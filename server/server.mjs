import express from "express";
import cors from "cors";
import { fileURLToPath } from 'url';
import path from "path";
import dotenv from "dotenv";
import adminRouter from "./src/admin/routes.mjs";
import userRouter from "./src/user/routes.mjs";
import cookieParser from "cookie-parser";
import paymentsRouter from "./src/payments/routes.mjs";

// Get __dirname equivalent for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0'; // Bind to all interfaces

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
        "http://192.168.1.147:3000",       // Your computer IP for Flutter web
        "http://192.168.1.147:5000",       // Your computer IP for mobile access
        /^http:\/\/10\.116\.44\.\d+:\d+$/, // Allow any device on your local network
        null                               // Allow mobile apps (they don't send origin)
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
dotenv.config();

// Health check endpoint for mobile app
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use("/api/v1/user/", userRouter);
app.use("/api/v1/admin/", adminRouter);
app.use("/api/v1/payments", paymentsRouter);

app.listen(PORT, HOST, () => {
  console.log(`Server is running on ${HOST}:${PORT}`);
  console.log(`Server accessible at:`);
  console.log(`  - Local: http://localhost:${PORT}`);
  console.log(`  - Network: http://192.168.1.147:${PORT}`);
});
