import API from "./api";

export const register = async (userData) => {
  const response = await API.post("/auth/register", userData);
  return response.data;
};

export const login = async (userData) => {
  const response = await API.post("/auth/login", userData);
  return response.data;
};