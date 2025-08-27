import { Router } from "express";
import {
  // 🔑 Auth
  registerUser,
  loginUser,
  otpVerify,
  emailVerify,
  authUser,
  logout,

  // 📧 Email / Password Management
  resendVerifyEmail,
  forgotPassword,
  resetPassword,
  verifyResetPasswordToken,

  // 👤 Profile edits
  updateEmail,
  updateContact,
  getUserProfile,

  // 🚗 Vehicle Management
  registerVehicle,
  updateVehicleImage,
  loadVehicleTypes,
  loadVehicleBrands,
  loadVehicles,

  // 🛠️ Service Management
  bookService,
  loadServiceTypes,
  loadMaintenanceHistory,
  loadCurrentServiceStatus,
} from "./controller.mjs";

import { upload } from "../middleware/upload.mjs";

const userRouter = Router();

/* ------------------- AUTH ------------------- */
userRouter.post("/register", registerUser);
userRouter.post("/login", loginUser);
userRouter.get("/emailverify", emailVerify);
userRouter.post("/otpverify", otpVerify);
userRouter.get("/authUser", authUser);
userRouter.get("/logout", logout);

/* ------------------- EMAIL / PASSWORD ------------------- */
userRouter.post("/resend-verify-email", resendVerifyEmail);
userRouter.post("/forgot-password-process", forgotPassword);
userRouter.get("/verify-password-token", verifyResetPasswordToken);
userRouter.post("/reset-password", resetPassword);

/* ------------------- PROFILE ------------------- */
userRouter.get("/profile", getUserProfile);
userRouter.put("/profile/email", updateEmail);
userRouter.put("/profile/contact", updateContact);

/* ------------------- VEHICLES ------------------- */
userRouter.post("/register-vehicle", upload.single("vehicleImage"), registerVehicle);
userRouter.post("/update-vehicle-image", upload.single("vehicleImage"), updateVehicleImage);
userRouter.get("/loadVehicleTypes", loadVehicleTypes);
userRouter.get("/loadVehicleBrands", loadVehicleBrands);
userRouter.get("/vehicles", loadVehicles);

/* ------------------- SERVICES ------------------- */
userRouter.post("/book-service", bookService);
userRouter.get("/loadServiceTypes", loadServiceTypes);
userRouter.get("/maintenance-history", loadMaintenanceHistory);
userRouter.get("/current-service-status", loadCurrentServiceStatus);

export default userRouter;
