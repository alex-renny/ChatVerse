import API from "./api";

export const getUsers = async () => {
  const response = await API.get("/users");
  return response.data;
};

export const getConversationUsers = async () => {
  const response = await API.get("/users/conversations");
  return response.data;
};