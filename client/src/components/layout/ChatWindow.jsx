import { useEffect, useState, useRef } from "react";
import {getMessages,sendMessage,deleteMessage,markAsSeen,reactToMessage} from "../../services/messageService";
import socket from "../../services/socket";
import { useAuth } from "../../context/AuthContext";
import MessageMenu from "../chat/MessageMenu";
import EmojiPicker from "emoji-picker-react";
import {FiPaperclip,FiImage,FiMic,FiSend,} from "react-icons/fi";
import ProfilePanel from "../chat/ProfilePanel";
import { IoCheckmark, IoCheckmarkDone } from "react-icons/io5";
import { BsEmojiSmile } from "react-icons/bs";
import { FiChevronUp, FiChevronDown } from "react-icons/fi";

  import { FiMoreVertical } from "react-icons/fi";

function ChatWindow({ selectedUser, setSelectedUser }) {
  const typingTimeout = useRef(null);
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const { user } = useAuth();
  const currentUserId = user?._id || user?.id;
  const bottomRef = useRef(null);
  const [menu, setMenu] = useState(null);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const fileInputRef = useRef(null);
  const imageInputRef = useRef(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewImage, setPreviewImage] = useState(null);
  const [typing, setTyping] = useState(false);
  const [replyMessage, setReplyMessage] = useState(null);
  const [reactionMenu, setReactionMenu] = useState(null);
  const [showProfile, setShowProfile] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [searchText, setSearchText] = useState("");
  const [matchedIndexes, setMatchedIndexes] = useState([]);
  const [currentMatch, setCurrentMatch] = useState(0);
  const [showChatMenu, setShowChatMenu] = useState(false);
  const messageRefs = useRef([]);
  const searchInputRef = useRef(null);
  const [selectionMode, setSelectionMode] = useState(false);
  const [selectedMessages, setSelectedMessages] = useState([]);

  const handleEmojiClick = (emojiData) => {
  setText((prev) => prev + emojiData.emoji);
};

const deleteSelectedMessages = async () => {
  try {
    for (const id of selectedMessages) {
      await deleteMessage(id);
    }

    setMessages((prev) =>
      prev.filter((msg) => !selectedMessages.includes(msg._id))
    );

    setSelectedMessages([]);
    setSelectionMode(false);
  } catch (err) {
    console.error(err);
  }
};

const toggleMessageSelection = (id) => {
  setSelectionMode(true);

  setSelectedMessages((prev) => {
    if (prev.includes(id)) {
      return prev.filter((msgId) => msgId !== id);
    }

    return [...prev, id];
  });
};

const goToNextMatch = () => {
  if (matchedIndexes.length === 0) return;

  let next = currentMatch + 1;

  if (next >= matchedIndexes.length) {
    next = 0;
  }

  setCurrentMatch(next);

  messageRefs.current[matchedIndexes[next]]?.scrollIntoView({
    behavior: "smooth",
    block: "center",
  });
};

const handleReaction = async (messageId, emoji) => {
  try {
    const updatedMessage = await reactToMessage(messageId, emoji);

    setMessages((prev) =>
      prev.map((msg) =>
        msg._id === updatedMessage._id ? updatedMessage : msg
      )
    );
  } catch (error) {
    console.error(error);
  }
};

  const handleSend = async () => {
  if (!text.trim() && !selectedImage && !selectedFile) return;

  try {
    const newMessage = await sendMessage(
      selectedUser._id,
      text,
      selectedImage || selectedFile,
      replyMessage?._id
    );

    setMessages((prev) => [...prev, newMessage]);
    setText("");
    setSelectedImage(null);
    setSelectedFile(null);
    setReplyMessage(null);

  } catch (error) {
    console.error(error);
  }
};

const goToPreviousMatch = () => {
  if (matchedIndexes.length === 0) return;

  let next = currentMatch - 1;

  if (next < 0) {
    next = matchedIndexes.length - 1;
  }

  setCurrentMatch(next);

  messageRefs.current[matchedIndexes[next]]?.scrollIntoView({
    behavior: "smooth",
    block: "center",
  });
};

useEffect(() => {
  if (selectedMessages.length === 0) {
    setSelectionMode(false);
  }
}, [selectedMessages]);

useEffect(() => {
  if (showSearch) {
    searchInputRef.current?.focus();
  }
}, [showSearch]);

useEffect(() => {
  if (!searchText.trim()) {
    setMatchedIndexes([]);
    setCurrentMatch(0);
    return;
  }

  const matches = [];

  messages.forEach((msg, index) => {
    if (
      msg.text &&
      msg.text.toLowerCase().includes(searchText.toLowerCase())
    ) {
      matches.push(index);
    }
  });

  setMatchedIndexes(matches);

  if (matches.length > 0) {
  const lastMatch = matches[matches.length - 1];

  // Save the POSITION in the matches array
  setCurrentMatch(matches.length - 1);

  setTimeout(() => {
    messageRefs.current[lastMatch]?.scrollIntoView({
      behavior: "smooth",
      block: "center",
    });
  }, 100);
}
}, [searchText, messages]);

useEffect(() => {
  const closeMenus = () => {
    setMenu(null);
    setReactionMenu(null);
  };

  window.addEventListener("click", closeMenus);

  return () => {
    window.removeEventListener("click", closeMenus);
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
        receiverId: currentUserId,
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
  socket.on("messageReaction", (updatedMessage) => {
  setMessages((prev) =>
    prev.map((msg) =>
      msg._id === updatedMessage._id
        ? updatedMessage
        : msg
    )
  );
});

  return () => {
    socket.off("typing", handleTyping);
    socket.off("stopTyping", handleStopTyping);
    socket.off("messageReaction");
  };
}, [selectedUser]);

useEffect(() => {

  const handleSeenUpdate = ({ receiverId }) => {

    if (selectedUser && selectedUser._id === receiverId) {

      setMessages((prev) =>
        prev.map((msg) =>
          msg.sender === currentUserId
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
    <main className="flex-1 bg-slate-950 relative">

      <div className="absolute inset-0 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-5xl font-bold text-white mb-4">
            Welcome to ReSender
          </h2>

          <p className="text-slate-400 text-lg">
            Select a conversation to start chatting.
          </p>
        </div>
      </div>

    </main>
  );
}


  return (
    <main className="flex-1 flex flex-col bg-slate-950">
      
      {/* Header */}
      <div className="p-5 border-b border-slate-800 flex justify-between items-center">

        <div className="flex items-center gap-3">

          <button
            onClick={() => setSelectedUser(null)}
            className="md:hidden text-white text-2xl"
          >
            ←
          </button>

          <div
            onClick={() => setShowProfile(true)}
            className="cursor-pointer"
          >
            <h2 className="text-2xl font-bold text-white">
              {selectedUser.name}
            </h2>

            <p className="text-slate-400">
              {selectedUser.email}
            </p>
          </div>

        </div>

        <div className="relative">

          <button
            onClick={() => setShowChatMenu(!showChatMenu)}
            className="text-white text-2xl"
          >
            <FiMoreVertical />
          </button>

          {selectionMode && (
            <div className="flex items-center justify-between px-5 py-3 bg-slate-900 border-b border-slate-800">

              <button
                onClick={() => {
                  setSelectionMode(false);
                  setSelectedMessages([]);
                }}
                className="text-white text-xl"
              >
                ✕
              </button>

              <h2 className="text-white font-semibold">
                {selectedMessages.length} Selected
              </h2>

              <button
                onClick={deleteSelectedMessages}
                className="text-red-400 text-xl hover:text-red-500"
              >
                🗑️
              </button>

            </div>
          )}

          {showChatMenu && (
            <div className="absolute right-0 mt-2 w-44 bg-slate-800 rounded-xl shadow-xl border border-slate-700 z-50">

              <button
                onClick={() => {
                  setShowSearch(true);
                  setShowChatMenu(false);
                }}
                className="w-full text-left px-4 py-3 hover:bg-slate-700 text-white"
              >
                🔍 Search
              </button>

            </div>
          )}

        </div>

      </div>

      {showSearch && (
        <div className="border-b border-slate-800 p-3 flex items-center gap-2 animate-slideDown">

          <input
            ref={searchInputRef}
            type="text"
            className="flex-1 bg-slate-800 text-white rounded-lg px-3 py-2 outline-none"
            placeholder="Search messages..."
            value={searchText}
            onChange={(e) => setSearchText(e.target.value)}
            onKeyDown={(e) => {
                if (e.key === "Enter") {
                    goToPreviousMatch();
                }
            }}
        />

        <button
          onClick={goToPreviousMatch}
          className="text-white hover:text-blue-400"
        >
          <FiChevronUp size={20} />
        </button>

        <button
          onClick={goToNextMatch}
          className="text-white hover:text-blue-400"
        >
          <FiChevronDown size={20} />
        </button>
          {searchText && matchedIndexes.length > 0 && (
            <p className="text-sm text-slate-400 whitespace-nowrap self-center">
              {currentMatch + 1} / {matchedIndexes.length}
            </p>
          )}

          {searchText && matchedIndexes.length === 0 && (
            <p className="text-sm text-red-400 whitespace-nowrap self-center">
              0 results
            </p>
          )}

          <button
            onClick={() => {
              setShowSearch(false);
              setSearchText("");
          }}
            className="text-red-400"
          >
            ✕
          </button>

        </div>
      )}

      {/* Messages */}

      <div className="flex-1 overflow-y-auto p-5">
  {messages.length === 0 ? (
    <p className="text-slate-400">
      No messages yet.
    </p>
  ) : (
    messages.map((msg, index) => {
      const isMine = msg.sender === currentUserId;
//      
      console.log("ReplyTo:", msg.replyTo);

      return (
        <div
          key={msg._id}
          ref={(el) => (messageRefs.current[index] = el)}
          onClick={() => {
            if (selectionMode) {
              toggleMessageSelection(msg._id);
            }
          }}
          onDoubleClick={() => handleReaction(msg._id, "❤️")}
          onContextMenu={(e) => {
            e.preventDefault();

            setReactionMenu({
              x: e.pageX,
              y: e.pageY,
              message: msg,
            });

            setMenu({
              x: e.pageX,
              y: e.pageY + 55,
              message: msg,
            });
          }}
          className={`flex items-center gap-3 mb-1 ${
            isMine ? "justify-end" : "justify-start"
          }`}
        >

          {selectionMode && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                toggleMessageSelection(msg._id);
              }}
              className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all duration-200 ${
                selectedMessages.includes(msg._id)
                  ? "bg-cyan-500 border-cyan-500 scale-110"
                  : "border-slate-500 hover:border-cyan-400"
              }`}
            >
              {selectedMessages.includes(msg._id) && (
                <span className="text-white text-xs">✓</span>
              )}
            </button>
          )}

          <div
            className={`relative max-w-md px-4 py-1.5 rounded-2xl text-white transition-all duration-300 ${
              isMine
                ? "bg-blue-600 rounded-br-md"
                : "bg-slate-700 rounded-bl-md"
            }`}
          >
            {matchedIndexes[currentMatch] === index && (
  <div className="absolute left-0 top-2 bottom-2 w-1 rounded-full bg-gradient-to-b from-cyan-300 via-blue-500 to-cyan-300 animate-pulse" />
)}
            <div>
              <div>
                {msg.replyTo && (
                  <div className="mb-2 border-l-4 border-blue-400 bg-black/20 rounded-md px-3 py-1.5">
                    <p className="text-xs text-blue-300 font-semibold">
                      {msg.replyTo.sender === currentUserId ? "You" : selectedUser.name}
                    </p>

                    <p className="text-sm text-slate-300 truncate">
                      {msg.replyTo.text || "📷 Image"}
                    </p>
                  </div>
                )}

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

                {msg.attachment && (
                  <a
                    href={`http://localhost:5000${msg.attachment.url}`}
                    download={msg.attachment.name}
                    className="mt-2 flex items-center gap-2 rounded-lg bg-black/20 px-3 py-2 text-sm text-blue-200 hover:bg-black/30"
                  >
                    <FiPaperclip />
                    <span className="truncate">{msg.attachment.name}</span>
                  </a>
                )}

                {msg.reactions && msg.reactions.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {[...new Set(msg.reactions.map((r) => r.emoji))].map((emoji) => {
                      const count = msg.reactions.filter(
                        (r) => r.emoji === emoji
                      ).length;

                      return (
                        <div
                          key={emoji}
                          className={`rounded-full px-2 py-1 text-xs flex items-center gap-1 border ${
                            msg.reactions.some(
                              (r) => r.user === currentUserId && r.emoji === emoji
                            )
                              ? "bg-blue-600 border-blue-400"
                              : "bg-slate-800 border-slate-600"
                          }`}
                        >
                          <span>{emoji}</span>
                          <span>{count}</span>
                        </div>
                      );
                    })}
                  </div>
                )}

              </div>

              <div className="flex justify-end items-center gap-1 text-[9px] text-slate-300 mt-0.5">

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
    <div className="relative border-t border-slate-800 px-3 py-1.5">

              {replyMessage && (
      <div className="bg-slate-800 border-l-4 border-blue-500 rounded-lg p-3 mb-3 flex items-start">
        <div>
          <p className="text-blue-400 text-sm font-semibold">
            Replying to {replyMessage.sender === currentUserId ? "You" : selectedUser.name}
          </p>

          <p className="text-slate-300 text-sm truncate max-w-md px-4 py-2 rounded-2xl">
            {replyMessage.text || "📷 Image"}
          </p>
        </div>

        <button
          onClick={() => setReplyMessage(null)}
          className="text-slate-400 hover:text-white text-lg"
        >
          ✕
        </button>
      </div>
    )}

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
        onChange={(e) => {
          if (e.target.files.length > 0) {
            setSelectedFile(e.target.files[0]);
            setSelectedImage(null);
          }
        }}
      />

      <input
        ref={imageInputRef}
        type="file"
        accept="image/*"
        hidden
        onChange={(e) => {
          if (e.target.files.length > 0) {
            setSelectedImage(e.target.files[0]);
            setSelectedFile(null);
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
            senderId: currentUserId,
          });

          clearTimeout(typingTimeout.current);

          typingTimeout.current = setTimeout(() => {

            socket.emit("stopTyping", {
              receiverId: selectedUser._id,
              senderId: currentUserId,
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

    {reactionMenu && (
      <div
        className="fixed bg-slate-800 rounded-full shadow-xl px-2 py-2 flex gap-2 z-50 border border-slate-700 animate-reactionPopup"
        style={{
          left: reactionMenu.x,
          top: reactionMenu.y - 60,
        }}
      >
        {["❤️", "😂", "👍", "😮", "😢", "🙏"].map((emoji) => (
          <button
            key={emoji}
            className="text-2xl transition-all duration-200 hover:scale-150 active:scale-95"
            onClick={() => {
              handleReaction(reactionMenu.message._id, emoji);

              setTimeout(() => {
                  setReactionMenu(null);
                  setMenu(null);
              }, 100);
          }}
          >
            {emoji}
          </button>
        ))}
      </div>
    )}

      {menu && (
        <MessageMenu
          x={menu.x}
          y={menu.y}
          onClose={() => setMenu(null)}
          onReply={() => {
            setReplyMessage(menu.message);
            setMenu(null);
          }}
          onCopy={() => {
            navigator.clipboard.writeText(menu.message.text);
            setMenu(null);
          }}
          onSelect={() => {
            setSelectionMode(true);
            toggleMessageSelection(menu.message._id);
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

{showProfile && (
  <ProfilePanel
    user={selectedUser}
    onClose={() => setShowProfile(false)}
  />
)}

    </main>
  );
}

export default ChatWindow;
