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

export const sendMessage = async (receiver, text, attachment, replyTo) => {
  const formData = new FormData();

  formData.append("receiver", receiver);
  formData.append("text", text);

  if (attachment) {
    formData.append("attachment", attachment);
  }

  if (replyTo) {
    formData.append("replyTo", replyTo);
  }

  const { data } = await axios.post(API, formData, {
    headers: {
      Authorization: `Bearer ${getToken()}`,
    },
  });

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
export const markAsSeen = async (senderId) => {
  const { data } = await axios.put(
    `${API}/seen/${senderId}`,
    {},
    {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
    }
  );

  return data;
};

export const reactToMessage = async (messageId, emoji) => {
  const token = localStorage.getItem("token");

  const res = await fetch(
    `http://localhost:5000/api/messages/react/${messageId}`,
    {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ emoji }),
    }
  );

  return res.json();
};
