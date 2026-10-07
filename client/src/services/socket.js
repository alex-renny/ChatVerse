import { io } from "socket.io-client";
import { API_ORIGIN } from "../config/api";
import { getSessionToken } from "./session";

const socket = io(API_ORIGIN, {
  autoConnect: false,
  auth: (callback) => callback({ token: getSessionToken() }),
});

export default socket;
