import axios from "axios";
import { getSessionToken } from "./session";
import { API_ORIGIN } from "../config/api";

const API = axios.create({
  baseURL: `${API_ORIGIN}/api`,
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
