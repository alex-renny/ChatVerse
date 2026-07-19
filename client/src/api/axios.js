import axios from "axios";

const api = axios.create({
  baseURL: "https://chatverse-server-eoma.onrender.com",
});

export default api;