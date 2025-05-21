import bcrypt from "bcrypt";
import pool from "../../db.mjs";
import { tokenGen, tokenGenLogin } from "../utils/jwt.mjs";
import { verifyToken } from "../utils/jwt.mjs";
import { sendEmail } from "../utils/email.mjs";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";

dotenv.config();

export const registerUser = async (req, res) => {
  try {
    const { fname, lname, email, mobile, password } = req.body;
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);

    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);

    if (checkUser.rows.length > 0) {
      return res.status(400).send("email already exists");
    }

    const checkMobile = await pool.query(
      "SELECT * FROM mobile_number WHERE mobile_no=$1",
      [mobile]
    );

    if (
      checkMobile.rows.length > 0 &&
      checkMobile.rows[0].is_otp_verified === "1"
    ) {
      return res.status(400).send("Mobile number already exists");
    }

    const hashedOTP = await bcrypt.hash("123456", 10);

    const now = new Date();
    const currentDateTime = now.toISOString().slice(0, 19).replace("T", " ");
    const formattedDate = now.toISOString().split("T")[0];

    if (checkMobile.rows.length === 0) {
      const addMobile = await pool.query(
        "INSERT INTO mobile_number (mobile_no, otp, otp_datetime) VALUES ($1, $2, $3) RETURNING mobile_id",
        [mobile, hashedOTP, currentDateTime]
      );
      var mobileid = addMobile.rows[0].mobile_id;
    } else {
      const updateMobile = await pool.query(
        "UPDATE mobile_number SET otp = $1, otp_datetime = $2 WHERE mobile_no = $3 RETURNING mobile_id",
        [hashedOTP, currentDateTime, mobile]
      );
      var mobileid = checkMobile.rows[0].mobile_id;
    }

    const getMaxUser = await pool.query(
      "SELECT COUNT(user_id) AS maxuser FROM users"
    );

    const addUser = await pool.query(
      "INSERT INTO users (user_id, first_name, last_name, email, password, mobile_id, registered_date, user_type_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
      [
        "CUS" + (getMaxUser.rows[0].maxuser + 1),
        fname,
        lname,
        email,
        hashedPassword,
        mobileid,
        formattedDate,
        "2",
      ]
    );

    const otp = String(Math.floor(100000 + Math.random() * 900000)).padStart(
      6,
      "0"
    );

    sendVerificationEmail(email);

    res.status(201).send({ message: "Success" });
  } catch (error) {
    console.log(error);
    res.status(500).send("Internal Server Error");
  }
};

export const loginUser = async (req, res) => {
  try {
    const { email, password, rememberMe } = req.body;
    const checkUser = await pool.query(
      "SELECT * FROM users INNER JOIN mobile_number ON users.mobile_id=mobile_number.mobile_id WHERE email = $1 AND status = $2",
      [email, "1"]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).send({ message: "Invalid username" });
    }

    const user = checkUser.rows[0];
    if (!user.isemailverified) {
      return res.status(400).send({ message: "Email not verified" });
    }
    if (!user.isotpverified) {
      return res.status(400).send({ message: "Mobile number not verified" });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(400).send({ message: "Invalid credentials" });
    }
    const token = tokenGenLogin(
      { userID: user.user_id, email: user.email },
      rememberMe
    );

    const cookieExpiration = rememberMe
      ? 7 * 24 * 60 * 60 * 1000
      : 24 * 60 * 60 * 1000; // 7 days or 1 day

    res.cookie("token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production", // HTTPS only in production
      sameSite: "strict",
      maxAge: cookieExpiration,
      path: "/",
    });

    if (rememberMe) {
      res.cookie("rememberUser", encodeURIComponent(email), {
        maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
        httpOnly: false, // Accessible by JavaScript
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        path: "/",
      });
    } else {
      // Clear any existing remember cookie
      res.clearCookie("rememberUser");
    }
    res.status(200).send({ token: token, user: user.user_id });
  } catch (error) {
    console.log(error);
    res.status(500).send("Internal Server Error");
  }
};

//After clicking on the link at the email for verify email
export const emailVerify = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).send({ message: "Token not found" });
    }
    const emailadd = verifyToken(token);
    if (!emailadd) {
      return res.status(400).send({ message: "Invalid token" });
    }
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [emailadd.email]
    );
    if (checkEmail.rows.length === 0) {
      return res
        .status(400)
        .send({ message: "No registered email from this token" });
    }

    const updateEmail = await pool.query(
      "UPDATE users SET isemailverified = $1 WHERE email=$2",
      ["1", emailadd.email]
    );
    res.status(200).send({ message: "Email verified" });
  } catch (error) {
    console.log(error);
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//Resend the email verification link
export const resendVerifyEmail = async (req, res) => {
  try {
    const { email } = req.body;
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );
    if (checkEmail.rows.length === 0) {
      return res.status(400).send({ message: "Invalid Email" });
    }
    const user = checkEmail.rows[0];
    if (user.isemailverified) {
      return res
        .status(200)
        .send({ message: "Email already verified. Go to login!" });
    }
    sendVerificationEmail(email);
    res.status(200).send({ message: "Email sent" });
  } catch (error) {
    console.log(error);
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//Verify email function
const sendVerificationEmail = async (email) => {
  const token = tokenGen({ email });
  sendEmail(
    email,
    "Auto Lanka Services, Email Verification",
    `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Email Verification</title>
      <style>
        body {
          font-family: 'Arial', sans-serif;
          line-height: 1.6;
          color:rgb(33, 33, 33);
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }
        h1 {
          color:rgb(133, 0, 0);
          margin-bottom: 20px;
          font-size: 24px;
          text-align: center;
        }
        p {
          margin-bottom: 25px;
          font-size: 16px;
        }
        .btn {
          background-color:rgb(140, 0, 0);
          text-decoration: none; 
          color: white;
          padding: 12px 24px;
          text-decoration: none;
          border-radius: 4px;
          font-weight: bold;
          display: inline-block;
        }
        .btn:hover {
          background-color:rgb(118, 0, 0);
        }
        .container {
          background-color: #f9f9f9;
          border: 1px solid #dddddd;
          border-radius: 5px;
          padding: 30px;
        }
        .footer {
          margin-top: 30px;
          font-size: 12px;
          color: #777777;
          text-align: center;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Auto Lanka Services Email Verification</h1>
        <p>Thank you for registering with Auto Lanka Services. To complete your registration and activate your account, please verify your email address by clicking the button below:</p>
        <div style="text-align: center;">
          <a href="${process.env.CLIENT_URL}/signup/emailactivation?token=${token}" class="btn">Click here to verify</a>
        </div>
        <p style="margin-top: 25px;">If the button doesn't work, you can also copy and paste the following link into your browser:</p>
        <p style="font-size: 14px;">${process.env.CLIENT_URL}/signup/emailactivation?token=${token}</p>
      </div>
      <div class="footer">
        <p>This email was sent by Auto Lanka Services. If you didn't create an account, you can safely ignore this email.</p>
      </div>
    </body>
    </html>
    `
  );
};

//Verify OTP after registration
export const otpVerify = async (req, res) => {
  try {
    const { mobile, otp } = req.body;
    const checkMobile = await pool.query(
      "SELECT * FROM mobile_number WHERE mobile_no = $1",
      [mobile]
    );
    if (checkMobile.rows.length === 0) {
      return res.status(400).send("Invalid Mobile Number");
    }
    const mobileData = checkMobile.rows[0];
    const otpMatch = await bcrypt.compare(otp, mobileData.otp);
    if (!otpMatch) {
      return res.status(400).send({ message: "Invalid OTP" });
    }
    const updateMobile = await pool.query(
      "UPDATE mobile_number SET isotpverified = $1 WHERE mobile_id=$2 AND mobile_no = $3",
      ["1", mobileData.mobile_id, mobile]
    );
    res.status(200).send({ message: "Success" });
  } catch (error) {
    console.log(error);
    res.status(500).send({ message: "Internal server error" });
  }
};

//When user forgets password he will enter email and then this function will be called
export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email,
    ]);
    if (checkUser.rows.length === 0) {
      return res.status(400).send({ message: "Invalid Email" });
    }
    sendPasswordResetEmail(email);
    res.status(200).send({ message: "Email sent" });
  } catch (error) {
    console.log(error);
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//Verify email function
const sendPasswordResetEmail = async (email) => {
  const token = tokenGen({ email });
  sendEmail(
    email,
    "Auto Lanka Services, Reset Account Password",
    `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reset Password</title>
      <style>
        body {
          font-family: 'Arial', sans-serif;
          line-height: 1.6;
          color:rgb(33, 33, 33);
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
        }

        h1 {
          color:rgb(133, 0, 0);
          margin-bottom: 20px;
          font-size: 24px;
          text-align: center;
        }
        p {
          margin-bottom: 25px;
          font-size: 16px;
        }
        .btn {
          background-color:rgb(245, 161, 161);
          color: white;
          padding: 12px 24px;
          text-decoration: none;
          border-radius: 4px;
          display: inline-block;
        }
        .btn:hover {
          background-color:rgb(118, 0, 0);
        }
        .container {
          background-color: #f9f9f9;
          border: 1px solid #dddddd;
          border-radius: 5px;
          padding: 30px;
        }
        .footer {
          margin-top: 30px;
          font-size: 12px;
          color: #777777;
          text-align: center;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Auto Lanka Services Account Password Reset</h1>
        <p>Click the following link to reset your password in your Auto Lanka Service online account:</p>
        <div style="text-align: center;">
          <a href="${process.env.CLIENT_URL}/login/reset-password?token=${token}" class="btn">Click to reset password</a>
        </div>
        <p style="margin-top: 25px;">If the button doesn't work, you can also copy and paste the following link into your browser:</p>
        <p style="font-size: 14px;">${process.env.CLIENT_URL}/login/reset-password?token=${token}</p>
      </div>
      <div class="footer">
        <p>This email was sent by Auto Lanka Services. If you didn't create an account, you can safely ignore this email.</p>
      </div>
    </body>
    </html>
    `
  );
};

export const verifyResetPasswordToken = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).send({ message: "Token not found" });
    }
    const email = verifyToken(token);
    if (!email) {
      return res.status(400).send({ message: "Invalid token" });
    }
    const checkEmail = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email.email]
    );
    if (checkEmail.rows.length === 0) {
      return res
        .status(400)
        .send({ message: "Email not found. Check the link again." });
    }
    res.status(200).send({ message: "Token verified" });
  } catch (error) {
    console.log(error);
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//After clicking on the link at the email for reset password
export const resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;
    const email = verifyToken(token);
    const checkUser = await pool.query("SELECT * FROM users WHERE email = $1", [
      email.email,
    ]);
    if (checkUser.rows.length === 0) {
      return res.status(400).send({ message: "Invalid Email" });
    }
    const strPwd = String(password);
    const hashedPassword = await bcrypt.hash(strPwd, 10);
    const updatePassword = await pool.query(
      "UPDATE users SET password = $1 WHERE email=$2",
      [hashedPassword, email.email]
    );
    res.status(200).send({ message: "Password updated" });
  } catch (error) {
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//Load user data and give current user data
// This function retrieves the user data from the database based on the token in the cookies
// It verifies the token and checks if the user exists in the database
// If the user exists, it returns the user data in the response

export const loadUserData = async (req, res) => {
  try {
    const { token } = req.cookies;
    if (!token) {
      return res.status(401).send("Unauthorized");
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).send("Unauthorized");
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).send("Invalid User");
    }
    const user = checkUser.rows[0];
    return res.status(200).send(user);
  } catch (error) {
    console.log(error);
    res.status(500).send("Internal Server Error"); // If the token is invalid or the user does not exist, it returns an error message
  }
};

//Check if user is authorized
export const authUser = async (req, res) => {
  try {
    const { token } = req.cookies;
    if (!token) {
      return res.status(401).send({ message: "No cookies available" }); // This function checks if the user is authorized by verifying the token in the cookies
    }
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).send({ message: "Unauthorized" }); // It returns a 401 status if the token is not present or invalid, and a 200 status if the user is authorized
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).send({ message: "Invalid User" }); // It also checks if the user exists in the database and returns a 400 status if not
    }
    res.status(200).send({ message: "Authorized" });
  } catch (error) {
    res.status(500).send({ message: "Internal Server Error" });
  }
};

//Logout function
export const logout = async (req, res) => {
  res.clearCookie("token");
  res.status(200).send({ message: "Logged out" });
};

// Register vehicle function
// This function registers a vehicle for a user
// It checks if the vehicle already exists, and if not, it adds the vehicle to the database
// It also saves the vehicle image to the server

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

    const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

    const addUser = await pool.query(
      "INSERT INTO users (user_id, first_name, last_name, email, password, mobile_id, registered_date, user_type_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
      [
        "CUS" + (getMaxUser.rows[0].maxuser + 1),
        fname,
        lname,
        email,
        hashedPassword,
        mobileid,
        formattedDate,
        "2",
      ]
    );

    console.log("Received Vehicle Data:", vehicleData);

    res.status(200).json({
      message: "Vehicle registered successfully",
    });
  } catch (error) {
    console.error("Error handling form:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

// Load vehicle types function
export const loadVehicleTypes = async (req, res) => {
  try {
    const result = await pool.query("SELECT vehicle_type_id, vehicle_type FROM vehicle_type ORDER BY vehicle_type ASC");
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "No vehicle types found" });
    }
    res.json(result.rows);
  } catch (err) {
    console.error("Error fetching vehicle types:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const loadVehicleBrands = async (req, res) => {
  try {
    const result = await pool.query("SELECT vehicle_brand_id, vehicle_brand FROM vehicle_brand ORDER BY vehicle_brand ASC");
    res.json(result.rows);
  } catch (err) {
    console.error("Error fetching vehicle types:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

// Load dashboard function
// This function loads the dashboard for the user

export const loadDashboard = async (req, res) => {
  try {
    const { token } = req.headers;
    const decodedToken = verifyToken(token);
    if (!decodedToken) {
      return res.status(401).send("Unauthorized");
    }
    const userID = decodedToken.userID;
    const checkUser = await pool.query(
      "SELECT * FROM users WHERE user_id = $1",
      [userID]
    );
    if (checkUser.rows.length === 0) {
      return res.status(400).send("Invalid User");
    }
    const user = checkUser.rows[0];
    res.status(200).send(user);
  } catch (error) {
    console.log(error);
    res.status(500).send("Internal Server Error");
  }
};
