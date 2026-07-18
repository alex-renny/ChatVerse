import jwt from "jsonwebtoken";
import User from "../models/User.js";

const protect = async (req, res, next) => {
  let token;

  // Check Authorization header
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    try {
      // Extract token
      token = req.headers.authorization.split(" ")[1];

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      console.log("Decoded token:", decoded);

      const user = await User.findById(decoded.id).select("-password");

      console.log("User found:", user);

      if (!user) {
        return res.status(401).json({
          message: "User not found",
        });
      }

      req.user = user;

      next();

    } catch (error) {
      console.error(error);

      return res.status(401).json({
        message: "Not authorized. Invalid token.",
      });
    }
  }

  if (!token) {
    return res.status(401).json({
      message: "Not authorized. No token provided.",
    });
  }
};

export default protect;