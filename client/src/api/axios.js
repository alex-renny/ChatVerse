import axios from "axios";
import { API_ORIGIN } from "../config/api";

const api = axios.create({
  baseURL: API_ORIGIN,
});

export default api;
