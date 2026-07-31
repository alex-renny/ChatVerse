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

// Set Chat Password
export const setChatPassword = async (password) => {
  const response = await API.put(
    "/users/chat-password",
    { password }
  );

  return response.data;
};

// Remove Chat Password
export const removeChatPassword = async () => {
  const response = await API.delete(
    "/users/chat-password"
  );

  return response.data;
};

// Check if chat access is allowed (password enabled + verified status)
export const checkChatAccess = async (userId) => {
  const response = await API.get(
    `/users/${userId}/chat-password-enabled`
  );

  return response.data;
};

// Verify Chat Password
export const verifyChatPassword = async (
  userId,
  password
) => {
  const response = await API.post(
    "/users/verify-chat-password",
    {
      userId,
      password,
    }
  );

  return response.data;
};