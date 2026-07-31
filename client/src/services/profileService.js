import API from "./api";

export const uploadProfilePicture = async (file) => {
  const formData = new FormData();

  formData.append("profile", file);

  const { data } = await API.put(
    "/profile/picture",
    formData,
    {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    }
  );

  return data;
};
export const updateProfile = async (profileData) => {
  const { data } = await API.put(
    "/profile/update",
    profileData
  );

  return data;
};

export const setChatPassword = async (password) => {
  const response = await API.put("/profile/chat-password", {
    password,
  });

  return response.data;
};

export const removeChatPassword = async () => {
  const response = await API.delete("/profile/chat-password");

  return response.data;
};

export const getChatPasswordStatus = async () => {
  const response = await API.get("/profile/chat-password");

  return response.data;
};

export const removeVerifiedUserAccess = async (userId) => {
  const response = await API.delete(
    `/profile/chat-password/access/${userId}`
  );

  return response.data;
};