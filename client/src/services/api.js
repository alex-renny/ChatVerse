import axios from "axios";
import { getSessionToken } from "./session";

const API = axios.create({
  baseURL:
    import.meta.env.MODE === "development"
      ? "http://localhost:5000/api"
      : "https://chatverse-server-eoma.onrender.com/api",
});

// Automatically attach JWT to every request
API.interceptors.request.use((config) => {
  const token = getSessionToken();

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});

export default API;
