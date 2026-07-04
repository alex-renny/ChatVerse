import { useEffect, useState, useRef } from "react";
import {getMessages,sendMessage,deleteMessage,markAsSeen,} from "../../services/messageService";
import socket from "../../services/socket";
import { useAuth } from "../../context/AuthContext";
import MessageMenu from "../chat/MessageMenu";
import EmojiPicker from "emoji-picker-react";
import {FiPaperclip,FiImage,FiMic,FiSend,} from "react-icons/fi";
import { IoCheckmark, IoCheckmarkDone } from "react-icons/io5";

import { BsEmojiSmile } from "react-icons/bs";

function ChatWindow({ selectedUser }) {
  const typingTimeout = useRef(null);
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const { user } = useAuth();
  const bottomRef = useRef(null);
  const [menu, setMenu] = useState(null);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const fileInputRef = useRef(null);
  const imageInputRef = useRef(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [previewImage, setPreviewImage] = useState(null);
  const [typing, setTyping] = useState(false);

  const handleEmojiClick = (emojiData) => {
  setText((prev) => prev + emojiData.emoji);
};

  const handleSend = async () => {
  if (!text.trim() && !selectedImage) return;

  try {
    const newMessage = await sendMessage(selectedUser._id,text,selectedImage);

    setMessages((prev) => [...prev, newMessage]);
    setText("");
    setSelectedImage(null);

  } catch (error) {
    console.error(error);
  }
};

useEffect(() => {
  const closeMenu = () => setMenu(null);

  window.addEventListener("click", closeMenu);

  return () => {
    window.removeEventListener("click", closeMenu);
  };
}, []);

useEffect(() => {
  bottomRef.current?.scrollIntoView({
    behavior: "smooth",
  });
}, [messages, typing]);

  useEffect(() => {
  if (!selectedUser) return;

  const loadMessages = async () => {
    try {
      const data = await getMessages(selectedUser._id);

      setMessages(data);

      await markAsSeen(selectedUser._id);

      socket.emit("messagesSeen", {
        senderId: selectedUser._id,
        receiverId: user.id,
      });

    } catch (error) {
      console.error(error);
    }
  };

  loadMessages();
}, [selectedUser]);

  useEffect(() => {
  const handleReceiveMessage = (message) => {
    // Only show messages from the currently selected user
    if (
      selectedUser &&
      (message.sender === selectedUser._id ||
        message.receiver === selectedUser._id)
    ) {
      setMessages((prev) => [...prev, message]);
    }
  };

  socket.on("receiveMessage", handleReceiveMessage);

  return () => {
    socket.off("receiveMessage", handleReceiveMessage);
  };
}, [selectedUser]);

useEffect(() => {
  const handleTyping = (data) => {
    console.log("📥 Typing received:", data);

    if (!data || !selectedUser) return;

    if (data.senderId === selectedUser._id) {
      console.log("✅ setTyping(true)");
      setTyping(true);
    }
  };

  const handleStopTyping = (data) => {
    console.log("🛑 Stop typing:", data);

    if (!data || !selectedUser) return;

    if (data.senderId === selectedUser._id) {
      setTyping(false);
    }
  };

  socket.on("typing", handleTyping);
  socket.on("stopTyping", handleStopTyping);

  return () => {
    socket.off("typing", handleTyping);
    socket.off("stopTyping", handleStopTyping);
  };
}, [selectedUser]);

useEffect(() => {

  const handleSeenUpdate = ({ receiverId }) => {

    if (selectedUser && selectedUser._id === receiverId) {

      setMessages((prev) =>
        prev.map((msg) =>
          msg.sender === user.id
            ? { ...msg, seen: true, delivered: true }
            : msg
        )
      );

    }

  };

  socket.on("messagesSeenUpdate", handleSeenUpdate);

  return () => {
    socket.off("messagesSeenUpdate", handleSeenUpdate);
  };

}, [selectedUser, user]);

  if (!selectedUser) {
    return (
      <main className="flex-1 flex items-center justify-center bg-slate-950">
        <div className="text-center">
          <h2 className="text-4xl font-bold text-white mb-4">
            Welcome to ChatVerse
          </h2>

          <p className="text-slate-400">
            Select a conversation to start chatting.
          </p>
        </div>
      </main>
    );
  }


  return (
    <main className="flex-1 flex flex-col bg-slate-950">
      
      {/* Header */}

      <div className="p-5 border-b border-slate-800">

        <h2 className="text-2xl font-bold text-white">
          {selectedUser.name}
        </h2>

        <p className="text-slate-400">
          {selectedUser.email}
        </p>

      </div>

  {selectedImage && (
    <div className="px-4 pb-2">
      <div className="relative w-fit">

        <img
          src={URL.createObjectURL(selectedImage)}
          alt="Preview"
          className="max-h-40 rounded-xl border border-slate-700"
        />

        <button
          onClick={() => setSelectedImage(null)}
          className="absolute top-2 right-2 bg-red-600 rounded-full px-2 text-white"
        >
          ✕
        </button>

      </div>
    </div>
  )}

      {/* Messages */}

      <div className="flex-1 overflow-y-auto p-5">

  {messages.length === 0 ? (
    <p className="text-slate-400">
      No messages yet.
    </p>
  ) : (
    messages.map((msg) => {
      const isMine = msg.sender === user.id;

      return (
        <div
          key={msg._id}
          onContextMenu={(e) => {
            e.preventDefault();

            setMenu({
              x: e.pageX,
              y: e.pageY,
              message: msg,
            });
          }}
          className={`flex mb-3 ${
            isMine ? "justify-end" : "justify-start"
          }`}
        >
          <div
            className={`max-w-xs px-4 py-3 rounded-2xl text-white ${
              isMine
                ? "bg-blue-600 rounded-br-md"
                : "bg-slate-700 rounded-bl-md"
            }`}
          >
            <div>
              <div>
                {msg.image && (
                  <img
                    src={`http://localhost:5000${msg.image}`}
                    alt="Shared"
                    onClick={() =>
                      setPreviewImage(`http://localhost:5000${msg.image}`)
                    }
                    className="rounded-xl mb-2 max-w-xs cursor-pointer hover:opacity-90 transition"
                  />
                )}

                {msg.text && (
                  <p>{msg.text}</p>
                )}
              </div>

              <div className="flex justify-end items-center gap-1 text-[11px] text-slate-300 mt-1">

                <span>
                  {new Date(msg.createdAt).toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                </span>

                {isMine && (
                  msg.seen ? (
                    <IoCheckmarkDone className="text-green-400" />
                  ) : msg.delivered ? (
                    <IoCheckmarkDone className="text-gray-300" />
                  ) : (
                    <IoCheckmark className="text-gray-300" />
                  )
                )}

              </div>
            </div>
          </div>
        </div>
      );
    })
  )}
{typing && (
        <div className="flex justify-start my-2 animate-fadeIn">

          <div className="bg-slate-700 rounded-2xl rounded-bl-md px-3 py-2 shadow-md">

            <div className="flex items-center gap-1 h-5">
              <span className="typing-dot"></span>
              <span className="typing-dot"></span>
              <span className="typing-dot"></span>
            </div>

          </div>

        </div>
      )}

  {/* Auto-scroll target */}
  <div ref={bottomRef}></div>

  </div>
        <div className="relative border-t border-slate-800 p-4">

    {showEmojiPicker && (
      <div className="absolute bottom-20 left-3 z-50">
        <EmojiPicker onEmojiClick={handleEmojiClick} />
      </div>
    )}

    <div className="flex items-center gap-2">

      {/* Emoji */}
      <button
        onClick={() => setShowEmojiPicker(!showEmojiPicker)}
        className="text-slate-300 hover:text-white text-2xl"
      >
        <BsEmojiSmile />
      </button>

      {/* File */}
      <button
        onClick={() => fileInputRef.current.click()}
        className="text-slate-300 hover:text-white text-2xl"
      >
        <FiPaperclip />
      </button>

      {/* Image */}
      <button
        onClick={() => imageInputRef.current.click()}
        className="text-slate-300 hover:text-white text-2xl"
      >
        <FiImage />
      </button>

      <input
        ref={fileInputRef}
        type="file"
        hidden
      />

      <input
        ref={imageInputRef}
        type="file"
        accept="image/*"
        hidden
        onChange={(e) => {
          if (e.target.files.length > 0) {
            setSelectedImage(e.target.files[0]);
          }
        }}
      />

      {/* Message Box */}

      <input
        type="text"
        value={text}
        onChange={(e) => {

          setText(e.target.value);

          console.log("Sending typing event");
          socket.emit("typing", {
            receiverId: selectedUser._id,
            senderId: user.id,
          });

          clearTimeout(typingTimeout.current);

          typingTimeout.current = setTimeout(() => {

            socket.emit("stopTyping", {
              receiverId: selectedUser._id,
              senderId: user.id,
            });

          }, 1000);

        }}
        placeholder="Type a message..."
        className="flex-1 bg-slate-800 text-white rounded-full px-5 py-3 outline-none"
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            handleSend();
          }
        }}
      />

      {/* Mic */}

      <button
        className="text-slate-300 hover:text-white text-2xl"
      >
        <FiMic />
      </button>

      {/* Send */}

      <button
        onClick={handleSend}
        className="bg-blue-600 hover:bg-blue-700 rounded-full p-3 text-white"
      >
        <FiSend />
      </button>

      </div>

    </div>

      {menu && (
        <MessageMenu
          x={menu.x}
          y={menu.y}
          onClose={() => setMenu(null)}
          onCopy={() => {
            navigator.clipboard.writeText(menu.message.text);
            setMenu(null);
          }}
          onDelete={async () => {
  console.log("Delete clicked");

  try {
    await deleteMessage(menu.message._id);

    console.log("Deleted from server");

    setMessages((prev) =>
      prev.filter((msg) => msg._id !== menu.message._id)
    );

    setMenu(null);
  } catch (error) {
    console.error(error);
  }
}}  
        />
      )}

      {previewImage && (
  <div
    onClick={() => setPreviewImage(null)}
    className="fixed inset-0 bg-black/80 flex items-center justify-center z-50"
  >
    <img
      src={previewImage}
      alt="Preview"
      className="max-w-[90%] max-h-[90%] rounded-xl shadow-2xl"
    />
  </div>
)}

    </main>
  );
}

export default ChatWindow;