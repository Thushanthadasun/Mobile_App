import bcrypt from "bcrypt";
import { tokenGen, tokenGenLogin, verifyToken } from "../utils/jwt.mjs";
import { sendEmail } from "../utils/email.mjs";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import pool from "../../db.mjs";

dotenv.config();

export const registerUser = async (req, res) => {
  try {
    const { fname, lname, email, mobile, password } = req.body;
    if (!fname || !lname || !email || !mobile || !password) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);

    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (checkUser.rows.length > 0) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const checkMobile = await pool.query(
      "SELECT * FROM mobile_number WHERE mobile_no = $1",
      [mobile]
    );
    if (
      checkMobile.rows.length > 0 &&
      checkMobile.rows[0].isotpverified === true
    ) {
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

    const getMaxUser = await pool.query(
      "SELECT COUNT(user_id) AS maxuser FROM users"
    );

    await pool.query(
      "INSERT INTO users (user_id, first_name, last_name, email, password, mobile_id, registered_date, user_type_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
      [
        "CUS" + (parseInt(getMaxUser.rows[0].maxuser) + 1),
        fname,
        lname,
        email,
        hashedPassword,
        mobileid,
        formattedDate,
        2,
      ]
    );

    sendVerificationEmail(email);

    res.status(201).json({ message: "Success" });
  } catch (error) {
    console.error("Error in registerUser:", error.message, error.stack);
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
    const decoded = verifyToken(token); // returns { userID: 'CUS12', email: '...' }

    const query = `
      SELECT u.first_name, u.last_name, u.email, m.mobile_no
      FROM users u
      JOIN mobile_number m ON u.mobile_id = m.mobile_id
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
    const { email, password, rememberMe } = req.body;
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

    const token = tokenGenLogin(
      { userID: user.user_id, email: user.email },
      rememberMe
    );

    const cookieExpiration = rememberMe
      ? 7 * 24 * 60 * 60 * 1000
      : 24 * 60 * 60 * 1000;

    res.cookie("token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: cookieExpiration,
      path: "/",
    });

    if (rememberMe) {
      res.cookie("rememberUser", encodeURIComponent(email), {
        maxAge: 30 * 24 * 60 * 60 * 1000,
        httpOnly: false,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        path: "/",
      });
    } else {
      res.clearCookie("rememberUser");
    }

    res.status(200).json({ token, user: user.user_id });
  } catch (error) {
    console.error("Error in loginUser:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const emailVerify = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({ message: "Token not found" });
    }
    const emailadd = verifyToken(token);
    if (!emailadd) {
      return res.status(400).json({ message: "Invalid token" });
    }
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [emailadd.email]
    );
    if (checkEmail.rows.length === 0) {
      return res
        .status(400)
        .json({ message: "No registered email from this token" });
    }

    await pool.query(
      "UPDATE users SET isemailverified = $1 WHERE email = $2",
      [true, emailadd.email]
    );
    res.status(200).json({ message: "Email verified" });
  } catch (error) {
    console.error("Error in emailVerify:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const resendVerifyEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );
    if (checkEmail.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    const user = checkEmail.rows[0];
    if (user.isemailverified) {
      return res
        .status(200)
        .json({ message: "Email already verified. Go to login!" });
    }
    sendVerificationEmail(email);
    res.status(200).json({ message: "Email sent" });
  } catch (error) {
    console.error("Error in resendVerifyEmail:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

const sendVerificationEmail = async (email) => {
  try {
    const token = tokenGen({ email });
    await sendEmail(
      email,
      "Auto Lanka Services, Email Verification",
      `
        Auto Lanka Services Email Verification

        Thank you for registering with Auto Lanka Services. To complete your registration and activate your account, please verify your email address by clicking the button below:

        <a href="http://localhost:5000/api/v1/user/emailverify?token=${token}">Click here to verify</a>

        If the button doesn't work, you can also copy and paste the following link into your browser:

        http://localhost:5000/api/v1/user/emailverify?token=${token}

        This email was sent by Auto Lanka Services. If you didn't create an account, you can safely ignore this email.
      `
    );
  } catch (error) {
    console.error("Error in sendVerificationEmail:", error.message, error.stack);
  }
};

export const otpVerify = async (req, res) => {
  try {
    const { mobile, otp } = req.body;
    if (!mobile || !otp) {
      return res.status(400).json({ message: "Mobile number and OTP are required" });
    }
    const checkMobile = await pool.query(
      "SELECT * FROM mobile_number WHERE mobile_no = $1",
      [mobile]
    );
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
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    sendPasswordResetEmail(email);
    res.status(200).json({ message: "Email sent" });
  } catch (error) {
    console.error("Error in forgotPassword:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

const sendPasswordResetEmail = async (email) => {
  try {
    const token = tokenGen({ email });
    await sendEmail(
      email,
      "Auto Lanka Services, Reset Account Password",
      `
        Auto Lanka Services Account Password Reset

        Click the following link to reset your password in your Auto Lanka Service online account:

        <a href="${process.env.CLIENT_URL}/login/reset-password?token=${token}">Click to reset password</a>

        If the button doesn't work, you can also copy and paste the following link into your browser:

        ${process.env.CLIENT_URL}/login/reset-password?token=${token}

        This email was sent by Auto Lanka Services. If you didn't create an account, you can safely ignore this email.
      `
    );
  } catch (error) {
    console.error("Error in sendPasswordResetEmail:", error.message, error.stack);
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
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email.email]
    );
    if (checkEmail.rows.length === 0) {
      return res
        .status(400)
        .json({ message: "Email not found. Check the link again." });
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
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email.email,
    ]);
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid Email" });
    }
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);
    await pool.query(
      "UPDATE users SET password = $1 WHERE email = $2",
      [hashedPassword, email.email]
    );
    res.status(200).json({ message: "Password updated" });
  } catch (error) {
    console.error("Error in resetPassword:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const loadUserData = async (req, res) => {
  try {
    const { token } = req.cookies;
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
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
    const { token } = req.cookies;
    if (!token) {
      return res.status(401).json({ message: "No cookies available" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "Invalid User" });
    }
    res.status(200).json({ message: "Authorized" });
  } catch (error) {
    console.error("Error in authUser:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const logout = async (req, res) => {
  try {
    res.clearCookie("token");
    res.status(200).json({ message: "Logged out" });
  } catch (error) {
    console.error("Error in logout:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

export const registerVehicle = async (req, res) => {
  try {
    const {
      licensePlate,
      vehicleType,
      make,
      model,
      color,
      year,
      transmission,
      fuelType,
    } = req.body;
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

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).json({ message: "User not found" });
    }

    const checkVehicle = await pool.query(
      "SELECT * FROM vehicles WHERE license_plate = $1",
      [licensePlate]
    );
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

    const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

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
        imagePath,
      ]
    );

    res.status(200).json({ message: "Vehicle registered successfully" });
  } catch (error) {
    console.error("Error in registerVehicle:", error.message, error.stack);
    res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};

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
    const { token } = req.headers;
    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).json({ message: "Invalid token" });
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
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

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
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

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
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
          vehicle_id, service_type_id, reserve_date, start_time, end_time, reservation_status, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [vehicleId, service_type_id, preferredDate, startTime, endTime, 1, notes || null]
      );
    }

    res.status(200).json({ message: "Service booking registered successfully" });
  } catch (error) {
    console.error("Error in bookService:", error.message, error.stack);
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

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      console.error(`User not found for userID: ${userID}`);
      return res.status(400).json({ message: "User not found" });
    }

    const result = await pool.query(
      `SELECT 
        v.license_plate,
        sr.service_record_id,
        sr.service_description,
        sr.price,
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

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
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
        sr.price,
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
