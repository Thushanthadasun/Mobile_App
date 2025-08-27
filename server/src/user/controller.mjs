import bcrypt from "bcrypt";
import { tokenGen, tokenGenLogin, verifyToken } from "../utils/jwt.mjs";
//import { sendEmail } from "../utils/email.mjs";
import { uploadToSupabase } from "../middleware/upload.mjs";
import dotenv from "dotenv";
import pool from "../../db.mjs";
//import jwt from "jsonwebtoken";
//import { transporter } from "../mailer.mjs";
//import jwt from "jsonwebtoken";
import jwt from "jsonwebtoken";
import { transporter } from "../mailer.mjs";

dotenv.config();

export const registerUser = async (req, res) => {
  try {
    const { fname, lname, email, mobile, nicno, address_line1, address_line2, address_line3, password } = req.body;
    if (!fname || !lname || !email || !mobile || !nicno || !address_line1 || !password) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);

    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (checkUser.rows.length > 0) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const checkMobile = await pool.query("SELECT * FROM mobile_number WHERE mobile_no = $1", [mobile]);
    if (checkMobile.rows.length > 0 && checkMobile.rows[0].isotpverified === true) {
      return res.status(400).json({ message: "Mobile number already exists" });
    }

    const hashedOTP = await bcrypt.hash("123456", 10);

    const now = new Date();
    const currentDateTime = now.toISOString().slice(0, 19).replace("T", " ");
    const formattedDate = now.toISOString().split("T")[0];

    let mobileid;
    if (checkMobile.rows.length === 0) {
      const addMobile = await pool.query(
        "INSERT INTO mobile_number (mobile_no, otp, otp_datetime) VALUES ($1, $2, $3) RETURNING mobile_id",
        [mobile, hashedOTP, currentDateTime]
      );
      mobileid = addMobile.rows[0].mobile_id;
    } else {
      const updateMobile = await pool.query(
        "UPDATE mobile_number SET otp = $1, otp_datetime = $2 WHERE mobile_no = $3 RETURNING mobile_id",
        [hashedOTP, currentDateTime, mobile]
      );
      mobileid = updateMobile.rows[0].mobile_id;
    }

    const addAddress = await pool.query(
      "INSERT INTO addresses (address_line1, address_line2, address_line3) VALUES ($1, $2, $3) RETURNING address_id",
      [address_line1, address_line2 || null, address_line3 || null]
    );
    const addressId = addAddress.rows[0].address_id;

    const getMaxUser = await pool.query("SELECT COUNT(user_id) AS maxuser FROM users");

    await pool.query(
      "INSERT INTO users (user_id, first_name, last_name, email, password, mobile_id, registered_date, user_type_id, nicno, address_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
      [
        "CUS" + (parseInt(getMaxUser.rows[0].maxuser) + 1),
        fname,
        lname,
        email,
        hashedPassword,
        mobileid,
        formattedDate,
        2,
        nicno,
        addressId,
      ]
    );

          await sendVerificationEmail({ email, fname });
          res.status(201).json({ message: "Success" });
  } catch (error) {
    console.error("Error in registerUser:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const bookService = async (req, res) => {
  try {
    const { vehicleNumber, services, preferredDate, preferredTime, notes } = req.body;
    if (!vehicleNumber || !services || !preferredDate || !preferredTime) {
      return res.status(400).json({ message: "All booking fields are required" });
    }

    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;

    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "User not found" });
    }

    const checkVehicle = await pool.query(
      "SELECT license_plate FROM vehicles WHERE license_plate = $1 AND user_id = $2 AND status = $3",
      [vehicleNumber, userID, true]
    );
    if (checkVehicle.rows.length === 0) {
      return res.status(400).json({ message: "Vehicle not found or not registered to this user" });
    }
    const vehicleId = checkVehicle.rows[0].license_plate;

    for (const serviceName of services) {
      const checkService = await pool.query(
        "SELECT service_type_id, duration FROM service_type WHERE service_name = $1",
        [serviceName]
      );
      if (checkService.rows.length === 0) {
        return res.status(400).json({ message: `Service '${serviceName}' not found` });
      }
      const { service_type_id, duration } = checkService.rows[0];

      let startTime;
      try {
        const timeMatch = preferredTime.match(/(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
        if (!timeMatch) {
          throw new Error("Invalid time format");
        }
        let hours = parseInt(timeMatch[1]);
        const minutes = timeMatch[2];
        const period = timeMatch[3] ? timeMatch[3].toUpperCase() : null;

        if (period === "PM" && hours !== 12) hours += 12;
        if (period === "AM" && hours === 12) hours = 0;

        startTime = `${hours.toString().padStart(2, '0')}:${minutes}:00`;
      } catch (error) {
        return res.status(400).json({ message: "Invalid preferred time format" });
      }

      const startDateTime = new Date(`2000-01-01T${startTime}`);
      const endDateTime = new Date(startDateTime.getTime() + duration * 60 * 1000);
      const endTime = endDateTime.toTimeString().slice(0, 8);

      const checkOverlap = await pool.query(
        `SELECT * FROM reservations 
         WHERE vehicle_id = $1 
         AND reserve_date = $2 
         AND (
           (start_time <= $3 AND end_time >= $3) OR 
           (start_time <= $4 AND end_time >= $4) OR 
           (start_time >= $3 AND end_time <= $4)
         )`,
        [vehicleId, preferredDate, startTime, endTime]
      );
      if (checkOverlap.rows.length > 0) {
        return res.status(400).json({ message: `Time slot unavailable for ${serviceName} on ${preferredDate} from ${preferredTime}` });
      }

      await pool.query(
        `INSERT INTO reservations (
          vehicle_id, service_type_id, reserve_date, start_time, end_time, end_date, reservation_status, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [vehicleId, service_type_id, preferredDate, startTime, endTime, preferredDate, 1, notes || null]
      );
    }

    res.status(200).json({ message: "Service booking registered successfully" });
  } catch (error) {
    console.error("Error in bookService:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

// --- ADD near other exports in controller.mjs -----------------

export const updateEmail = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1] : null;
    if (!token) return res.status(401).json({ message: "Unauthorized" });

    const { userID } = verifyToken(token);
    const { email } = req.body;

    if (!email) return res.status(400).json({ message: "New email is required" });

    // email must be unique
    const dupe = await pool.query("SELECT 1 FROM users WHERE email=$1 AND user_id<>$2", [email, userID]);
    if (dupe.rowCount) return res.status(400).json({ message: "Email already in use" });

    // update
    const upd = await pool.query(
      "UPDATE users SET email=$1, isemailverified=$2 WHERE user_id=$3 RETURNING first_name",
      [email, true, userID]
    );

    const fname = upd.rows[0]?.first_name || "there";

    // send an informational email (no click required)
    try {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: "Auto Lanka Services — Email Updated",
        html: `
          <p>Hi ${fname},</p>
          <p>Your account email was updated to <b>${email}</b>.</p>
          <p>If you did not make this change, please contact support immediately.</p>
        `,
      });
    } catch (e) {
      console.warn("Email notice send failed (updateEmail):", e?.message || e);
    }

    res.status(200).json({ message: "Email updated" });
  } catch (err) {
    console.error("Error in updateEmail:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

export const updateContact = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1] : null;
    if (!token) return res.status(401).json({ message: "Unauthorized" });

    const { userID } = verifyToken(token);
    const { mobile } = req.body;

    if (!mobile) return res.status(400).json({ message: "New contact number is required" });

    // locate user's current mobile_id
    const row = await pool.query("SELECT mobile_id, email, first_name FROM users WHERE user_id=$1", [userID]);
    if (!row.rowCount) return res.status(404).json({ message: "User not found" });

    const { mobile_id, email, first_name } = row.rows[0];

    // ensure number not in use by another verified user
    const dupe = await pool.query(
      "SELECT 1 FROM mobile_number mn JOIN users u ON u.mobile_id = mn.mobile_id WHERE mn.mobile_no=$1 AND u.user_id<>$2",
      [mobile, userID]
    );
    if (dupe.rowCount) return res.status(400).json({ message: "Mobile number already in use" });

    // update (and mark verified = true so it works immediately, per your request)
    await pool.query(
      "UPDATE mobile_number SET mobile_no=$1, isotpverified=$2 WHERE mobile_id=$3",
      [mobile, true, mobile_id]
    );

    // send info email to current account email (optional)
    try {
      await transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: "Auto Lanka Services — Contact Number Updated",
        html: `
          <p>Hi ${first_name || "there"},</p>
          <p>Your contact number was updated to <b>${mobile}</b>.</p>
          <p>If you did not make this change, please contact support immediately.</p>
        `,
      });
    } catch (e) {
      console.warn("Email notice send failed (updateContact):", e?.message || e);
    }

    res.status(200).json({ message: "Contact updated" });
  } catch (err) {
    console.error("Error in updateContact:", err);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

// --- END ADD ---------------------------------------------------


export const loadVehicleTypes = async (req, res) => {
  try {
    const result = await pool.query("SELECT vehicle_type_id, vehicle_type FROM vehicle_type ORDER BY vehicle_type ASC");
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "No vehicle types found" });
    }
    res.json(result.rows);
  } catch (error) {
    console.error("Error in loadVehicleTypes:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadVehicleBrands = async (req, res) => {
  try {
    const result = await pool.query("SELECT vehicle_brand_id, vehicle_brand FROM vehicle_brand ORDER BY vehicle_brand ASC");
    res.json(result.rows);
  } catch (error) {
    console.error("Error in loadVehicleBrands:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadDashboard = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid User" });
    }
    const user = checkUser.rows[0];
    res.status(200).json(user);
  } catch (error) {
    console.error("Error in loadDashboard:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadVehicles = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      console.error("No token provided in loadVehicles");
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      console.error("Invalid token in loadVehicles:", token);
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    console.log(`Fetching vehicles for userID: ${userID}`);

    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      console.error(`User not found for userID: ${userID}`);
      return res.status(400).json({ message: "User not found" });
    }
    console.log(`User found: ${JSON.stringify(checkUser.rows[0])}`);

    const result = await pool.query(
      `SELECT 
        v.license_plate,
        v.model,
        v.color,
        v.make_year,
        v.imgpath,
        COALESCE(vt.vehicle_type, 'Unknown') AS vehicle_type,
        COALESCE(vb.vehicle_brand, 'Unknown') AS vehicle_brand,
        COALESCE(ft.fuel_type, 'Unknown') AS fuel_type,
        COALESCE(tt.transmission_type, 'Unknown') AS transmission_type
      FROM vehicles v
      LEFT JOIN vehicle_type vt ON v.vehicle_type_id = vt.vehicle_type_id
      LEFT JOIN vehicle_brand vb ON v.vehicle_brand_id = vb.vehicle_brand_id
      LEFT JOIN fuel_type ft ON v.fuel_type::integer = ft.fuel_type_id
      LEFT JOIN transmission_type tt ON v.transmission_type = tt.transmission_type_id
      WHERE v.user_id = $1 AND v.status = $2
      ORDER BY v.license_plate ASC`,
      [userID, true]
    );

    console.log(`Query executed with userID: ${userID}, status: true`);
    console.log(`Fetched ${result.rows.length} vehicles for user ${userID}:`, JSON.stringify(result.rows, null, 2));

    if (result.rows.length === 0) {
      console.warn(`No vehicles found for user ${userID}. Check if vehicles are registered and status is true.`);
      const allVehicles = await pool.query(
        "SELECT license_plate, user_id, status FROM vehicles WHERE user_id = $1",
        [userID]
      );
      console.log(`All vehicles for user ${userID} (including inactive):`, JSON.stringify(allVehicles.rows, null, 2));
    }

    res.status(200).json(result.rows);
  } catch (error) {
    console.error("Error in loadVehicles:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadServiceTypes = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT service_type_id, service_name, description FROM service_type ORDER BY service_name ASC"
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "No service types found" });
    }
    res.json(result.rows);
  } catch (error) {
    console.error("Error in loadServiceTypes:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadMaintenanceHistory = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      console.error("No token provided in loadMaintenanceHistory");
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      console.error("Invalid token in loadMaintenanceHistory:", token);
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    console.log(`Fetching maintenance history for userID: ${userID}`);

    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      console.error(`User not found for userID: ${userID}`);
      return res.status(400).json({ message: "User not found" });
    }

    const result = await pool.query(
      `SELECT 
        v.license_plate,
        sr.service_record_id,
        sr.service_description,
        sr.final_amount,
        sr.created_datetime,
        sr.is_paid,
        TO_CHAR(r.reserve_date, 'YYYY-MM-DD') AS reserve_date,
        TO_CHAR(r.start_time, 'HH24:MI:SS') AS start_time,
        TO_CHAR(r.end_time, 'HH24:MI:SS') AS end_time,
        r.notes,
        st.service_name
      FROM service_records sr
      INNER JOIN reservations r ON sr.reservation_id = r.reservation_id
      INNER JOIN vehicles v ON r.vehicle_id = v.license_plate
      INNER JOIN service_type st ON r.service_type_id = st.service_type_id
      WHERE v.user_id = $1
      ORDER BY r.reserve_date DESC, r.start_time DESC`,
      [userID]
    );

    console.log(`Fetched ${result.rows.length} service records for user ${userID}:`, JSON.stringify(result.rows, null, 2));

    res.status(200).json(result.rows);
  } catch (error) {
    console.error("Error in loadMaintenanceHistory:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadCurrentServiceStatus = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      console.error("No token provided in loadCurrentServiceStatus");
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      console.error("Invalid token in loadCurrentServiceStatus:", token);
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    console.log(`Fetching current service status for userID: ${userID}`);

    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      console.error(`User not found for userID: ${userID}`);
      return res.status(400).json({ message: "User not found" });
    }

    const result = await pool.query(
      `SELECT 
        r.reservation_id,
        v.license_plate,
        st.service_name,
        TO_CHAR(r.reserve_date, 'YYYY-MM-DD') AS reserve_date,
        TO_CHAR(r.start_time, 'HH24:MI:SS') AS start_time,
        TO_CHAR(r.end_time, 'HH24:MI:SS') AS end_time,
        st.duration,
        rs.status_name,
        sr.final_amount,
        sr.is_paid,
        sr.service_record_id
      FROM reservations r
      INNER JOIN vehicles v ON r.vehicle_id = v.license_plate
      INNER JOIN service_type st ON r.service_type_id = st.service_type_id
      INNER JOIN reservation_status rs ON r.reservation_status = rs.reservation_status_id
      LEFT JOIN service_records sr ON r.reservation_id = sr.reservation_id
      WHERE v.user_id = $1 
        AND rs.reservation_status_id IN (1, 2, 3)
      ORDER BY r.reserve_date DESC, r.start_time DESC`,
      [userID]
    );

    console.log(`Fetched ${result.rows.length} current services for user ${userID}:`, JSON.stringify(result.rows, null, 2));

    res.status(200).json(result.rows);
  } catch (error) {
    console.error("Error in loadCurrentServiceStatus:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const getUserProfile = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const token = authHeader.split(" ")[1];
    const decoded = verifyToken(token);

    const query = `
      SELECT 
        u.first_name, 
        u.last_name, 
        u.email, 
        m.mobile_no, 
        u.nicno,
        a.address_line1,
        a.address_line2,
        a.address_line3
      FROM users u
      JOIN mobile_number m ON u.mobile_id = m.mobile_id
      LEFT JOIN addresses a ON u.address_id = a.address_id
      WHERE u.user_id = $1
    `;

    const result = await pool.query(query, [decoded.userID]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error("Profile error:", error.message);
    res.status(500).json({ message: "Server error" });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const checkUser = await pool.query(
      "SELECT * FROM users INNER JOIN mobile_number ON users.mobile_id = mobile_number.mobile_id WHERE email = $1 AND status = $2",
      [email, true]
    );

    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid username" });
    }

    const user = checkUser.rows[0];

    if (!user.isemailverified) {
      return res.status(400).json({ message: "Email not verified" });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const token = tokenGenLogin({ userID: user.user_id, email: user.email });

    return res.status(200).json({
      token,
      user: {
        id: user.user_id,
        fname: user.first_name,
        lname: user.last_name,
        email: user.email,
        mobile: user.mobile_no,
        nicno: user.nicno
      }
    });
  } catch (error) {
    console.error("Error in loginUser:", error.message, error.stack);
    return res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const emailVerify = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      console.log('[emailVerify] missing token');
      return res.status(400).json({ message: "Token not found" });
    }

    const decoded = verifyToken(token);
    if (!decoded || !decoded.email) {
      console.log('[emailVerify] invalid token:', decoded);
      return res.status(400).json({ message: "Invalid token" });
    }

    const email = decoded.email;
    console.log('[emailVerify] decoded email:', email);

    const user = await pool.query("SELECT isemailverified FROM users WHERE email = $1", [email]);
    if (user.rows.length === 0) {
      console.log('[emailVerify] no user for email:', email);
      return res.status(400).json({ message: "No registered email from this token" });
    }

    if (user.rows[0].isemailverified === true) {
      console.log('[emailVerify] already verified:', email);
      return res.status(200).json({ message: "Email already verified" });
    }

    const updated = await pool.query(
      "UPDATE users SET isemailverified = $1 WHERE email = $2 RETURNING isemailverified",
      [true, email]
    );

    console.log('[emailVerify] update rowCount:', updated.rowCount, 'new value:', updated.rows[0]?.isemailverified);
    return res.status(200).json({ message: "Email verified" });
  } catch (error) {
    console.error("Error in emailVerify:", error.message, error.stack);
    return res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};


export const resendVerifyEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }
    const checkEmail = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (checkEmail.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    const user = checkEmail.rows[0];
    if (user.isemailverified) {
      return res.status(200).json({ message: "Email already verified. Go to login!" });
    }
    await sendVerificationEmail({ email, fname: user.first_name });;
    res.status(200).json({ message: "Email sent" });
  } catch (error) {
    console.error("Error in resendVerifyEmail:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

const sendVerificationEmail = async ({ email, fname }) => {
  try {
    const token = tokenGen({ email });

    // Direct API verification link
    const verifyUrl = `http://localhost:5000/api/v1/user/emailverify?token=${encodeURIComponent(token)}`;

    const info = await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: "Auto Lanka Services — Email Verification",
      html: `
        <p>Hi ${fname || "there"},</p>
        <p>Please verify your email by clicking the button below:</p>
        <p>
          <a href="${verifyUrl}" 
             style="background:#0a84ff;color:#fff;padding:10px 16px;border-radius:8px;text-decoration:none;">
            Verify Email
          </a>
        </p>
        <p>If the button doesn't work, copy this link:<br>${verifyUrl}</p>
      `,
    });

    console.log("Verify URL:", verifyUrl);
    console.log("MessageId:", info.messageId, "accepted:", info.accepted, "rejected:", info.rejected);
  } catch (err) {
    console.error("Error in sendVerificationEmail:", err);
  }
};







export const otpVerify = async (req, res) => {
  try {
    const { mobile, otp } = req.body;
    if (!mobile || !otp) {
      return res.status(400).json({ message: "Mobile number and OTP are required" });
    }
    const checkMobile = await pool.query("SELECT * FROM mobile_number WHERE mobile_no = $1", [mobile]);
    if (checkMobile.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Mobile Number" });
    }
    const mobileData = checkMobile.rows[0];
    const otpMatch = mobileData.otp ? await bcrypt.compare(otp, mobileData.otp) : false;
    if (!otpMatch) {
      return res.status(400).json({ message: "Invalid OTP" });
    }
    await pool.query(
      "UPDATE mobile_number SET isotpverified = $1 WHERE mobile_id = $2 AND mobile_no = $3",
      [true, mobileData.mobile_id, mobile]
    );
    res.status(200).json({ message: "Success" });
  } catch (error) {
    console.error("Error in otpVerify:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    await sendPasswordResetEmail(email);
    res.status(200).json({ message: "Email sent" });
  } catch (error) {
    console.error("Error in forgotPassword:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

// replace the whole function with this transporter version
const sendPasswordResetEmail = async (email) => {
  try {
    const token = tokenGen({ email });
    const base = process.env.CLIENT_URL || "http://localhost:3000/#";
    const resetUrl = `${base}login/reset-password?token=${encodeURIComponent(token)}`;

    const info = await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: "Auto Lanka Services — Reset Account Password",
      html: `
        <p>Reset your Auto Lanka Services account password:</p>
        <p>
          <a href="${resetUrl}" style="background:#0a84ff;color:#fff;padding:10px 16px;border-radius:8px;text-decoration:none;">
            Reset Password
          </a>
        </p>
        <p>If the button doesn't work, copy this link:<br>${resetUrl}</p>
      `,
    });
    console.log("Password reset email accepted:", info.accepted, "rejected:", info.rejected);
  } catch (error) {
    console.error("Error in sendPasswordResetEmail:", error.message, error.stack);
    throw error; // bubble up if you want the route to fail on send errors
  }
};


export const verifyResetPasswordToken = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({ message: "Token not found" });
    }
    const email = verifyToken(token);
    if (!email) {
      return res.status(400).json({ message: "Invalid token" });
    }
    const checkEmail = await pool.query("SELECT * FROM users WHERE email = $1", [email.email]);
    if (checkEmail.rows.length === 0) {
      return res.status(400).json({ message: "Email not found. Check the link again." });
    }
    res.status(200).json({ message: "Token verified" });
  } catch (error) {
    console.error("Error in verifyResetPasswordToken:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      return res.status(400).json({ message: "Token and password are required" });
    }
    const email = verifyToken(token);
    if (!email) {
      return res.status(400).json({ message: "Invalid token" });
    }
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [email.email]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);
    await pool.query("UPDATE users SET password = $1 WHERE email = $2", [hashedPassword, email.email]);
    res.status(200).json({ message: "Password updated" });
  } catch (error) {
    console.error("Error in resetPassword:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadUserData = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid User" });
    }
    const user = checkUser.rows[0];
    res.status(200).json(user);
  } catch (error) {
    console.error("Error in loadUserData:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const authUser = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Authorization header missing" });
    }

    const token = authHeader.split(" ")[1];
    const decoded = verifyToken(token);

    const result = await pool.query(
      `SELECT 
         first_name AS fname,
         last_name AS lname,
         email,
         mobile_no AS mobile,
         nicno,
         address_line1,
         address_line2,
         address_line3
       FROM users 
       INNER JOIN mobile_number ON users.mobile_id = mobile_number.mobile_id 
       LEFT JOIN addresses ON users.address_id = addresses.address_id
       WHERE users.user_id = $1`,
      [decoded.userID]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const user = result.rows[0];

    res.status(200).json({
      fname: user.fname,
      lname: user.lname,
      email: user.email,
      mobile: user.mobile,
      nicno: user.nicno,
      address_line1: user.address_line1 || '',
      address_line2: user.address_line2 || '',
      address_line3: user.address_line3 || '',
    });
  } catch (error) {
    console.error("Error in authUser:", error.message);
    res.status(500).json({ message: "Failed to get user profile", error: error.message });
  }
};

export const logout = async (req, res) => {
  try {
    res.clearCookie("token");
    res.status(200).json({ message: "Logged out" });
  } catch (error) {
    console.error("register vehicle error:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const registerVehicle = async (req, res) => {
  try {
    const { licensePlate, vehicleType, make, model, color, year, transmission, fuelType } = req.body;
    if (!licensePlate || !vehicleType || !make || !model || !color || !year || !transmission || !fuelType) {
      return res.status(400).json({ message: "All vehicle fields are required" });
    }

    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;

    const checkUser = await pool.query("SELECT * FROM users WHERE user_id = $1", [userID]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "User not found" });
    }

    const checkVehicle = await pool.query("SELECT * FROM vehicles WHERE license_plate = $1", [licensePlate]);
    if (checkVehicle.rows.length > 0) {
      return res.status(400).json({ message: "License plate already registered" });
    }

    const fuelTypeMap = {
      "1": "1",
      "2": "2",
      "3": "3",
    };
    const transmissionMap = {
      "1": "1",
      "2": "2",
    };

    const dbFuelType = fuelTypeMap[fuelType];
    const dbTransmission = transmissionMap[transmission];

    if (!dbFuelType || !dbTransmission) {
      return res.status(400).json({ message: "Invalid fuel type or transmission" });
    }

    let imageUrl = null;
    if (req.file) {
      imageUrl = await uploadToSupabase(req.file);
    }

    await pool.query(
      `INSERT INTO vehicles (
        license_plate, user_id, vehicle_type_id, vehicle_brand_id, 
        model, color, make_year, status, fuel_type, transmission_type, imgpath
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        licensePlate,
        userID,
        vehicleType,
        make,
        model,
        color,
        year,
        true,
        dbFuelType,
        dbTransmission,
        imageUrl,
      ]
    );

    res.status(200).json({ message: "Vehicle registered successfully" });
  } catch (error) {
    console.error("Error in registerVehicle:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const updateVehicleImage = async (req, res) => {
  try {
    const { licensePlate } = req.body;
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    if (!licensePlate) {
      return res.status(400).json({ message: "License plate is required" });
    }
    if (!req.file) {
      return res.status(400).json({ message: "No image file provided" });
    }

    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;

    const checkVehicle = await pool.query(
      "SELECT imgpath FROM vehicles WHERE license_plate = $1 AND user_id = $2",
      [licensePlate, userID]
    );
    if (checkVehicle.rows.length === 0) {
      return res.status(400).json({ message: "Vehicle not found or not registered to this user" });
    }

    const imageUrl = await uploadToSupabase(req.file);

    await pool.query(
      "UPDATE vehicles SET imgpath = $1 WHERE license_plate = $2 AND user_id = $3",
      [imageUrl, licensePlate, userID]
    );

    res.status(200).json({ message: "Vehicle image updated successfully" });
  } catch (error) {
    console.error("Error in updateVehicleImage:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};
