import axios from "axios";
import { getSessionToken } from "./session";
console.log(import.meta.env.VITE_API_URL);
const API = `${import.meta.env.VITE_API_URL}/api/messages`;

const getToken = () => getSessionToken();

export const getMessages = async (receiverId, limit = 30, skip = 0) => {
  const { data } = await axios.get(`${API}/${receiverId}`, {
    headers: {
      Authorization: `Bearer ${getToken()}`,
    },
    params: {
      limit,
      skip,
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

export const deleteMessage = async (messageId, deleteForEveryone = false) => {
  try {
    const { data } = await axios.delete(`${API}/${messageId}`, {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
      data: {
        deleteForEveryone,
      },
    });

    return data;
  } catch (error) {
    // Another tab or the real-time event may have already removed it.
    if (error.response?.status === 404) return { alreadyDeleted: true };

    throw error;
  }
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
  const token = getSessionToken();

  const res = await fetch(
    `https://chatverse-server-eoma.onrender.com/api/messages/react/${messageId}`,
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

export const pinMessage = async (messageId) => {
  const { data } = await axios.put(
    `${API}/pin/${messageId}`,
    {},
    {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
    }
  );

  return data;
};

export const unpinMessage = async (messageId) => {
  const { data } = await axios.put(
    `${API}/unpin/${messageId}`,
    {},
    {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
    }
  );

  return data;
};
export const clearChat = async (receiverId) => {
  const { data } = await axios.delete(
    `${API}/clear/${receiverId}`,
    {
      headers: {
        Authorization: `Bearer ${getToken()}`,
      },
    }
  );

  return data;
};