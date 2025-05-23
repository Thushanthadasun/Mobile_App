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
} from "./controller.mjs";
import upload from "../middleware/upload.mjs";

//User functions here

const userRouter = Router();

userRouter.post("/register", registerUser);
userRouter.post("/login", loginUser);
userRouter.post("/otpverify", otpVerify);
userRouter.get("/emailverify", emailVerify);
userRouter.get("/otpverify", otpVerify);
userRouter.get("/authUser", authUser);
userRouter.get("/logout", logout);
userRouter.post("/resend-verify-email", resendVerifyEmail);
userRouter.post("/forgot-password-process", forgotPassword);
userRouter.get("/verify-password-token", verifyResetPasswordToken);
userRouter.post("/reset-password", resetPassword);
userRouter.post("/register-vehicle", upload.single("vehicleImage"), registerVehicle);
userRouter.get("/loadVehicleTypes", loadVehicleTypes);
userRouter.get("/loadVehicleBrands", loadVehicleBrands);

export default userRouter;
