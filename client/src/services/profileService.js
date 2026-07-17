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