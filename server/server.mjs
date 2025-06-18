import express from "express";
import cors from "cors";
import fs from "fs";
import path from "path";
import { fileURLToPath } from 'url';
import dotenv from "dotenv";
import adminRouter from "./src/admin/routes.mjs";
import userRouter from "./src/user/routes.mjs";
import cookieParser from "cookie-parser";

// Get __dirname equivalent for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

const PORT = process.env.PORT || 5000;

// Middleware
app.use(
  cors({
    origin: function (origin, callback) {
      const allowedOrigins = [
        /^http:\/\/localhost:\d+$/,        // Match all localhost ports
        /^http:\/\/127\.0\.0\.1:\d+$/,     // Match all 127.0.0.1 ports
        "http://localhost:5173",           // Specific port if needed
        "http://127.0.0.1:5173",
        "http://localhost:3000",           // Explicitly added for Flutter web
        "http://192.168.1.182:5173"        // LAN IP or production dev IP
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

// 🔥 ADD THIS LINE - Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Optional: Add a test endpoint to verify files exist
app.get('/test-upload/:filename', (req, res) => {
  const filePath = path.join(__dirname, 'uploads', req.params.filename);
  
  if (fs.existsSync(filePath)) {
    const stats = fs.statSync(filePath);
    res.json({ 
      exists: true, 
      path: filePath,
      size: stats.size,
      modified: stats.mtime
    });
  } else {
    res.status(404).json({ 
      exists: false, 
      path: filePath,
      message: 'File not found in uploads directory'
    });
  }
});

// API Routes
app.use("/api/v1/user/", userRouter);
app.use("/api/v1/admin/", adminRouter);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Static files served from: http://localhost:${PORT}/uploads/`);
});