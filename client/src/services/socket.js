import { io } from "socket.io-client";

const socket = io("https://chatverse-server-eoma.onrender.com", {
  autoConnect: false,
});

export default socket;