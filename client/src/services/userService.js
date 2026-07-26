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

// Save chat background
export const saveChatBackground = async (userId, background) => {
  const response = await API.put(
    `/users/${userId}/background`,
    { background }
  );

  return response.data;
};

// Get chat background
export const getChatBackground = async (userId) => {
  const response = await API.get(
    `/users/${userId}/background`
  );

  return response.data;
};