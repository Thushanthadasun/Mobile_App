import { Router } from "express";
import { registerUser, loginUser, otpVerify, emailVerify } from "./controller.mjs";

//User functions here

const userRouter = Router();

userRouter.post("/register", registerUser);
userRouter.post("/login", loginUser);
userRouter.post("/otpverify", otpVerify);
userRouter.get("/emailverify", emailVerify);
userRouter.get("/otpverify", otpVerify);

export default userRouter;
