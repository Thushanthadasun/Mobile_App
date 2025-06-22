import { Router } from "express";
import {
  registerUser,
  loginUser,
  otpVerify,
  emailVerify,
  authUser,
  logout,
  resendVerifyEmail,
  forgotPassword,
  resetPassword,
  verifyResetPasswordToken,
  registerVehicle,
  loadVehicleTypes,
  loadVehicleBrands,
  loadVehicles,
  bookService,
  loadServiceTypes,
  loadMaintenanceHistory,
  loadCurrentServiceStatus,
  getUserProfile // ✅ Added here
} from "./controller.mjs";
import upload from "../middleware/upload.mjs";

const userRouter = Router();

// 🧑‍💻 User Auth
userRouter.post("/register", registerUser);
userRouter.post("/login", loginUser);
userRouter.get("/emailverify", emailVerify);
userRouter.post("/otpverify", otpVerify); // ✅ Only POST used here
userRouter.get("/authUser", authUser);
userRouter.get("/logout", logout);
userRouter.get("/profile", getUserProfile); // ✅ NEW: User Profile route

// 📧 Email / Password
userRouter.post("/resend-verify-email", resendVerifyEmail);
userRouter.post("/forgot-password-process", forgotPassword);
userRouter.get("/verify-password-token", verifyResetPasswordToken);
userRouter.post("/reset-password", resetPassword);

// 🚗 Vehicle Management
userRouter.post("/register-vehicle", upload.single("vehicleImage"), registerVehicle);
userRouter.get("/loadVehicleTypes", loadVehicleTypes);
userRouter.get("/loadVehicleBrands", loadVehicleBrands);
userRouter.get("/vehicles", loadVehicles);

// 🛠️ Service Management
userRouter.post("/book-service", bookService);
userRouter.get("/loadServiceTypes", loadServiceTypes);
userRouter.get("/maintenance-history", loadMaintenanceHistory);
userRouter.get("/current-service-status", loadCurrentServiceStatus);

export default userRouter;
