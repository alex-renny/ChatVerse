import API from "./api";

export const getUsers = async () => {
  const response = await API.get("/users");
  return response.data;
};

export const getConversationUsers = async () => {
  const response = await API.get("/users/conversations");
  return response.data;
};

export const togglePinnedChat = async (userId) => {
  const response = await API.put(`/users/${userId}/pin`);
  return response.data;
};
