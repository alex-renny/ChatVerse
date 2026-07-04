import axios from "axios";

const API = "http://localhost:5000/api/messages";

const getToken = () => localStorage.getItem("token");

export const getMessages = async (receiverId) => {
  const { data } = await axios.get(`${API}/${receiverId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`,
    },
  });

  return data;
};

export const sendMessage = async (receiver, text) => {
  const { data } = await axios.post(
    API,
    {
      receiver,
      text,
    },
    {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
    }
  );

  return data;
};
export const deleteMessage = async (messageId) => {
  const { data } = await axios.delete(`${API}/${messageId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`,
    },
  });

  return data;
};