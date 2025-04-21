// controller.mjs

import db from "../config/db.mjs"; // adjust path as needed

// REGISTER USER
export async function registerUser(req, res) {
  try {
    const { fname, lname, email, password, mobile } = req.body;

    // Insert mobile number
    const mobileResult = await db.query(
      `INSERT INTO mobile_number (mobile_no, otp, otp_datetime, isotpverified)
       VALUES ($1, '0000', NOW(), true) RETURNING mobile_id`,
      [mobile]
    );

    const mobile_id = mobileResult.rows[0].mobile_id;

    // Insert user
    const userResult = await db.query(
      `INSERT INTO "user" (first_name, last_name, email, password, user_type_id, mobile_id, registered_date, isemailverified, status)
       VALUES ($1, $2, $3, $4, 1, $5, NOW(), true, 1)
       RETURNING *`,
      [fname, lname, email, password, mobile_id]
    );

    res.status(201).json({ message: "User registered", user: userResult.rows[0] });
  } catch (error) {
    console.error("Registration error:", error.message);
    res.status(500).json({ message: "Registration failed", error: error.message });
  }
}

// LOGIN USER
export async function loginUser(req, res) {
  try {
    const { email, password } = req.body;

    const result = await db.query(
      `SELECT * FROM "user" WHERE email = $1 AND password = $2 AND isemailverified = true AND status = 1`,
      [email, password]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    res.status(200).json({ message: "Login successful", user: result.rows[0] });
  } catch (error) {
    console.error("Login error:", error.message);
    res.status(500).json({ message: "Login failed", error: error.message });
  }
}

// OTP VERIFY (dummy)
export function otpVerify(req, res) {
  const { otp } = req.body;
  if (otp === "123456") {
    return res.status(200).json({ message: "OTP verified" });
  }
  res.status(400).json({ message: "Invalid OTP" });
}

// EMAIL VERIFY (dummy)
export async function emailVerify(req, res) {
  try {
    const { email } = req.body;

    const userCheck = await db.query(`SELECT * FROM "user" WHERE email = $1`, [email]);

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ message: "Email not found" });
    }

    await db.query(`UPDATE "user" SET isemailverified = true WHERE email = $1`, [email]);

    res.status(200).json({ message: "Email verified" });
  } catch (error) {
    console.error("Email verify error:", error.message);
    res.status(500).json({ message: "Verification failed", error: error.message });
  }
}
