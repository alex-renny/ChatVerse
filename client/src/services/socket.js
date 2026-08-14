import { io } from "socket.io-client";
import { API_ORIGIN } from "../config/api";

const socket = io(API_ORIGIN, {
  autoConnect: false,
});

export default socket;
