import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import connectDB from "./config/db.js";
import { createServer } from "http";
import { Server } from "socket.io";
import messageRoutes from "./routes/messageRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config();

connectDB();

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const server = createServer(app);

export const io = new Server(server, {
  cors: {
    origin: "http://localhost:5173",
    methods: ["GET", "POST"],
  },
});
export const onlineUsers = new Map();

io.on("connection", (socket) => {

    console.log("🟢 Connected:", socket.id);

    socket.on("registerUser", (userId) => {
  console.log("REGISTER RECEIVED:", userId);

  onlineUsers.set(userId, socket.id);

  console.log("Map:", [...onlineUsers.entries()]);

  io.emit("onlineUsers", [...onlineUsers.keys()]);
});

    socket.on("messagesSeen", ({ senderId, receiverId }) => {

      const senderSocketId = onlineUsers.get(senderId);

      if (senderSocketId) {

        io.to(senderSocketId).emit("messagesSeenUpdate", {
          receiverId,
        });

      }

    });
    socket.on("typing", ({ receiverId, senderId }) => {

  console.log("📨 Server received typing:", {
    receiverId,
    senderId,
  });

  console.log("Online Users Map:");
console.log([...onlineUsers.entries()]);

  const receiverSocketId = onlineUsers.get(receiverId);

  console.log("Receiver socket:", receiverSocketId);

  if (receiverSocketId) {
    io.to(receiverSocketId).emit("typing", {
      senderId,
    });

    console.log("✅ Typing event forwarded");
  } else {
    console.log("❌ Receiver socket not found");
  }
});

socket.on("stopTyping", ({ receiverId, senderId }) => {

  const receiverSocketId = onlineUsers.get(receiverId);

  console.log("Stop typing receiver socket:", receiverSocketId);

  if (receiverSocketId) {
    io.to(receiverSocketId).emit("stopTyping", {
      senderId,
    });

    console.log("🛑 StopTyping forwarded");
  }

});

    socket.on("disconnect", () => {

      console.log("🔴 Disconnected:", socket.id);

      for (const [userId, socketId] of onlineUsers.entries()) {

        if (socketId === socket.id) {

          onlineUsers.delete(userId);

          break;

        }

      }

      io.emit("onlineUsers", [...onlineUsers.keys()]);

    });

  });

app.use(cors());
app.use(express.json());
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/profile", profileRoutes);
app.use("/uploads",express.static(path.join(__dirname, "uploads")));

app.get("/", (req, res) => {
  res.send("🚀ReSender API Running");
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});