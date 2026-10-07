import User from "../models/User.js";
import bcrypt from "bcrypt";
import generateToken from "../utils/generateToken.js";

const normalizeEmail = (email) => String(email || "").trim().toLowerCase();
const validEmailSyntax = (email) =>
  email.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const publicUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  profilePic: user.profilePic,
  bio: user.bio,
  lastSeen: user.lastSeen,
});

export const registerUser = async (req, res) => {
  try {
    const { name, password } = req.body;
    const email = normalizeEmail(req.body.email);
    if (!name?.trim() || !email || !password) {
      return res.status(400).json({ message: "Please fill all fields" });
    }
    if (!validEmailSyntax(email)) {
      return res.status(400).json({ message: "Enter a valid email address" });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      if (!(await bcrypt.compare(password, existingUser.password))) {
        return res.status(409).json({
          message: "An account with this email already exists. Sign in with its password.",
        });
      }
      return res.status(200).json({
        message: "Account found. You are signed in.",
        token: generateToken(existingUser._id),
        user: publicUser(existingUser),
      });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({
      name: name.trim(),
      email,
      password: hashedPassword,
    });
    return res.status(201).json({
      message: "Account created successfully",
      token: generateToken(user._id),
      user: publicUser(user),
    });
  } catch (error) {
    // A second registration request can race the first one after the account
    // has already been inserted. Recover it as a sign-in when the password
    // matches, instead of returning a misleading duplicate/network error.
    if (error.code === 11000) {
      try {
        const email = normalizeEmail(req.body.email);
        const existingUser = await User.findOne({ email });
        if (existingUser && await bcrypt.compare(req.body.password || "", existingUser.password)) {
          return res.status(200).json({
            message: "Account found. You are signed in.",
            token: generateToken(existingUser._id),
            user: publicUser(existingUser),
          });
        }
        return res.status(409).json({
          message: "An account with this email already exists. Sign in with its password.",
        });
      } catch (recoveryError) {
        console.error("Registration recovery error:", recoveryError.message);
      }
    }
    console.error("Registration error:", error.message);
    return res.status(500).json({ message: "Server Error" });
  }
};

export const getAuthSession = (req, res) =>
  res.json({ authenticated: true, user: publicUser(req.user) });

export const loginUser = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const { password } = req.body;
    if (!validEmailSyntax(email) || !password) {
      return res.status(400).json({ message: "Enter a valid email and password" });
    }
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: "Invalid email or password" });
    }
    const token = generateToken(user._id);
    return res.status(200).json({
      message: "Login successful",
      token,
      user: publicUser(user),
    });
  } catch (error) {
    console.error("Login error:", error.message);
    return res.status(500).json({ message: "Server Error" });
  }
};
