import express from "express";
import cors from "cors";
import fs from "fs";
import dotenv from "dotenv";
import adminRouter from "./src/admin/routes.mjs";
import userRouter from "./src/user/routes.mjs";
import cookieParser from "cookie-parser";

const app = express();

const PORT = process.env.PORT || 5000;

// Middleware
app.use(
  cors({
    origin: function (origin, callback) {
      const allowedOrigins = [
        /^http:\/\/localhost:\d+$/,      // Allow all localhost ports
        /^http:\/\/127\.0\.0\.1:\d+$/,   // Allow all 127.0.0.1 ports
        "http://192.168.1.182:5173"      // Your static IP (for production)
      ];
      if (
        !origin ||
        allowedOrigins.some((o) =>
          typeof o === "string" ? o === origin : o.test(origin)
        )
      ) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
  })
);


app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded form data
app.use(cookieParser()); 

// Load environment variables
const uploadDir = "./uploads/";

// Ensure upload directory exists
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}


app.use("/api/v1/user/", userRouter);
app.use("/api/v1/admin/", adminRouter);
app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
