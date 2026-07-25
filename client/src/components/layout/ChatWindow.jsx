import { useEffect, useState, useRef } from "react";
import { getMessages, sendMessage, deleteMessage, markAsSeen, reactToMessage, pinMessage, unpinMessage } from "../../services/messageService";
import socket from "../../services/socket";
import { useAuth } from "../../context/AuthContext";
import MessageMenu from "../chat/MessageMenu";
import EmojiPicker from "emoji-picker-react";
import { FiPaperclip, FiImage, FiMic, FiSend, FiX, FiArrowLeft, FiMoreVertical, FiChevronUp, FiChevronDown } from "react-icons/fi";
import ProfilePanel from "../chat/ProfilePanel";
import { IoCheckmark, IoCheckmarkDone } from "react-icons/io5";
import { BsEmojiSmile } from "react-icons/bs";
import { useSwipeable } from "react-swipeable";
import MessageBubble from "../chat/MessageBubble";
import chatBackgrounds from "../../data/chatBackgrounds";

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
  const [selectedImageUrl, setSelectedImageUrl] = useState("");
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
  const [pinnedMessage, setPinnedMessage] = useState(null);
  const [showBackgroundSubMenu, setShowBackgroundSubMenu] = useState(false);
  const [chatBackground, setChatBackground] = useState("");
  const backgroundTimer = useRef(null);

  const reactionWidth = 280;
  const reactionHeight = 60;

  const reactionLeft = reactionMenu && reactionMenu.x + reactionWidth > window.innerWidth
    ? window.innerWidth - reactionWidth - 10
    : reactionMenu?.x;

  const reactionTop = reactionMenu && reactionMenu.y - reactionHeight < 0
    ? reactionMenu.y + 10
    : reactionMenu?.y - reactionHeight;

  // === EFFECTS ===
  useEffect(() => {
    if (!selectedImage) {
      setSelectedImageUrl("");
      return;
    }
    const objectUrl = URL.createObjectURL(selectedImage);
    setSelectedImageUrl(objectUrl);
    return () => URL.revokeObjectURL(objectUrl);
  }, [selectedImage]);

  useEffect(() => {
    if (!selectedUser) return;
    const saved = localStorage.getItem(`chatBackground_${selectedUser._id}`) || "";
    setChatBackground(saved);
  }, [selectedUser]);

  useEffect(() => {
    const handleClickOutside = () => {
      setShowChatMenu(false);
      setShowBackgroundSubMenu(false);
    };
    window.addEventListener("click", handleClickOutside);
    return () => window.removeEventListener("click", handleClickOutside);
  }, []);

  useEffect(() => {
    if (selectedMessages.length === 0) setSelectionMode(false);
  }, [selectedMessages]);

  useEffect(() => {
    if (showSearch) searchInputRef.current?.focus();
  }, [showSearch]);

  useEffect(() => {
    if (!searchText.trim()) {
      setMatchedIndexes([]);
      setCurrentMatch(0);
      return;
    }
    const matches = [];
    messages.forEach((msg, index) => {
      if (msg.text && msg.text.toLowerCase().includes(searchText.toLowerCase())) {
        matches.push(index);
      }
    });
    setMatchedIndexes(matches);
    if (matches.length > 0) {
      const lastMatch = matches[matches.length - 1];
      setCurrentMatch(matches.length - 1);
      setTimeout(() => {
        const msgId = messages[lastMatch]._id;
        messageRefs.current[msgId]?.scrollIntoView({ behavior: "smooth", block: "center" });
      }, 100);
    }
  }, [searchText, messages]);

  useEffect(() => {
    const closeMenus = () => { setMenu(null); setReactionMenu(null); };
    window.addEventListener("click", closeMenus);
    return () => window.removeEventListener("click", closeMenus);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, typing]);

  useEffect(() => {
    if (!selectedUser) return;
    const loadMessages = async () => {
      try {
        const data = await getMessages(selectedUser._id);
        setMessages(data);
        const pinned = data.find((m) => m.pinned);
        setPinnedMessage(pinned || null);
        await markAsSeen(selectedUser._id);
        socket.emit("messagesSeen", { senderId: selectedUser._id, receiverId: currentUserId });
      } catch (error) {
        console.error(error);
      }
    };
    loadMessages();
  }, [selectedUser]);

    useEffect(() => {
    const handleReceiveMessage = (message) => {
      // 1. If we are currently viewing the sender's chat, update messages instantly
      if (
        selectedUser &&
        (message.sender === selectedUser._id ||
          message.receiver === selectedUser._id)
      ) {
        setMessages((prev) => [...prev, message]);
      } 
      // 2. If we are NOT viewing their chat, show a browser notification (optional) or console log
      else {
        console.log(`💬 New message from ${message.senderName || 'someone'}: ${message.text}`);
        // You can add a toast notification here later!
      }
    };

    socket.on("receiveMessage", handleReceiveMessage);

    return () => {
      socket.off("receiveMessage", handleReceiveMessage);
    };
  }, [selectedUser]); // We keep selectedUser here so we know if we're viewing the right chat

  useEffect(() => {
    const handleTyping = (data) => {
      if (!data || !selectedUser) return;
      if (data.senderId === selectedUser._id) setTyping(true);
    };
    const handleStopTyping = (data) => {
      if (!data || !selectedUser) return;
      if (data.senderId === selectedUser._id) setTyping(false);
    };
    socket.on("typing", handleTyping);
    socket.on("stopTyping", handleStopTyping);
    socket.on("messageReaction", (updatedMessage) => {
      setMessages((prev) => prev.map((msg) => msg._id === updatedMessage._id ? updatedMessage : msg));
    });
    socket.on("messageUpdated", (updatedMessage) => {
      setMessages(prev => {
        const updatedMessages = prev.map(msg => {
          if (updatedMessage.pinned) {
            return msg._id === updatedMessage._id ? updatedMessage : { ...msg, pinned: false };
          }
          return msg._id === updatedMessage._id ? updatedMessage : msg;
        });
        const pinned = updatedMessages.find(m => m.pinned);
        setPinnedMessage(pinned || null);
        return updatedMessages;
      });
    });
    const handleMessageDeleted = ({ messageId }) => {
      setMessages((prev) => prev.filter((message) => message._id !== messageId));
      setPinnedMessage((prev) => (prev?._id === messageId ? null : prev));
    };
    socket.on("messageDeleted", handleMessageDeleted);
    return () => {
      socket.off("typing", handleTyping);
      socket.off("stopTyping", handleStopTyping);
      socket.off("messageReaction");
      socket.off("messageUpdated");
      socket.off("messageDeleted", handleMessageDeleted);
    };
  }, [selectedUser]);

  useEffect(() => {
    const handleSeenUpdate = ({ receiverId }) => {
      if (selectedUser && selectedUser._id === receiverId) {
        setMessages((prev) =>
          prev.map((msg) =>
            msg.sender === currentUserId ? { ...msg, seen: true, delivered: true } : msg
          )
        );
      }
    };
    socket.on("messagesSeenUpdate", handleSeenUpdate);
    return () => socket.off("messagesSeenUpdate", handleSeenUpdate);
  }, [selectedUser, user]);

  // === HANDLERS ===
  const clearSelectedAttachment = () => {
    setSelectedImage(null);
    setSelectedFile(null);
    setPreviewImage(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
    if (imageInputRef.current) imageInputRef.current.value = "";
  };

  const handleEmojiClick = (emojiData) => {
    setText((prev) => prev + emojiData.emoji);
  };

  const scrollToMessage = (id) => {
    const element = messageRefs.current[id];
    if (!element) return;
    element.scrollIntoView({ behavior: "smooth", block: "center" });
    element.classList.add("reply-highlight");
    setTimeout(() => element.classList.remove("reply-highlight"), 1800);
  };

  const deleteSelectedMessages = async () => {
  const idsToDelete = [...selectedMessages];

  // 1. Instantly remove them from the UI (Optimistic update)
  setMessages((prev) =>
    prev.filter((msg) => !idsToDelete.includes(msg._id))
  );
  setSelectedMessages([]);
  setSelectionMode(false);

  // 2. Fire off the API calls in the background (Promise.all)
  try {
    await Promise.all(
      idsToDelete.map((id) => deleteMessage(id, false))
    );
  } catch (err) {
    console.error(err);
    // Optional: If a delete fails on the server, you could revert the UI here
    alert("Some messages failed to delete.");
  }
};

  const toggleMessageSelection = (id) => {
    setSelectionMode(true);
    setSelectedMessages((prev) => {
      if (prev.includes(id)) return prev.filter((msgId) => msgId !== id);
      return [...prev, id];
    });
  };

  const goToNextMatch = () => {
    if (matchedIndexes.length === 0) return;
    let next = currentMatch + 1;
    if (next >= matchedIndexes.length) next = 0;
    setCurrentMatch(next);
    const msgIndex = matchedIndexes[next];
    const msgId = messages[msgIndex]._id;
    messageRefs.current[msgId]?.scrollIntoView({ behavior: "smooth", block: "center" });
  };

  const goToPreviousMatch = () => {
    if (matchedIndexes.length === 0) return;
    let next = currentMatch - 1;
    if (next < 0) next = matchedIndexes.length - 1;
    setCurrentMatch(next);
    const msgIndex = matchedIndexes[next];
    const msgId = messages[msgIndex]._id;
    messageRefs.current[msgId]?.scrollIntoView({ behavior: "smooth", block: "center" });
  };

  const handleReaction = async (messageId, emoji) => {
    try {
      const updatedMessage = await reactToMessage(messageId, emoji);
      setMessages((prev) => prev.map((msg) => msg._id === updatedMessage._id ? updatedMessage : msg));
    } catch (error) {
      console.error(error);
    }
  };

  const handleSend = async () => {
    if (!text.trim() && !selectedImage && !selectedFile) return;
    try {
      const newMessage = await sendMessage(selectedUser._id, text, selectedImage || selectedFile, replyMessage?._id);
      setMessages((prev) => [...prev, newMessage]);
      setText("");
      clearSelectedAttachment();
      setReplyMessage(null);
    } catch (error) {
      console.error(error);
    }
  };

  // === EMPTY STATE ===
  if (!selectedUser) {
    return (
      <main className="flex-1 bg-white relative">
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center p-8">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-[#FF7A00]/10 rounded-3xl mb-6">
              <span className="text-4xl">💬</span>
            </div>
            <h2 className="text-3xl font-bold text-[#2C2C2C] mb-2">Welcome to ReSender</h2>
            <p className="text-gray-400 text-lg">Select a conversation to start chatting.</p>
          </div>
        </div>
      </main>
    );
  }

    return (
    // 1. Added 'bg-cover' and 'bg-center' to ensure the background image fills the container
    <main 
      className="flex-1 flex justify-center bg-[#f8f9fa] relative bg-cover bg-center" 
      style={{ backgroundImage: chatBackground ? `url(${chatBackground})` : 'none' }}
    >
      
      {/* 2. Inner container is now 'bg-white' with 'bg-opacity-90' so the background image bleeds through slightly on the edges */}
      <div className="w-full max-w-5xl flex flex-col bg-transparent shadow-sm relative">

        {/* ================= HEADER ================= */}
        <div className="p-4 border-b border-gray-200 flex justify-between items-center bg-white z-10">
          {selectionMode ? (
            <>
              <div className="flex items-center gap-4">
                <button onClick={() => { setSelectionMode(false); setSelectedMessages([]); }} className="text-2xl text-[#2C2C2C] hover:text-red-500 transition">
                  <FiX />
                </button>
                <div>
                  <h2 className="text-lg font-semibold text-[#2C2C2C]">{selectedMessages.length} Selected</h2>
                  <p className="text-xs text-gray-400">Select more messages</p>
                </div>
              </div>
              <button onClick={deleteSelectedMessages} className="w-10 h-10 rounded-full bg-red-50 hover:bg-red-100 flex items-center justify-center text-red-500 text-xl transition">
                🗑️
              </button>
            </>
          ) : (
            <>
              <div className="flex items-center gap-3">
                <button onClick={() => setSelectedUser(null)} className="md:hidden p-2 rounded-full hover:bg-gray-100 text-[#2C2C2C] transition">
                  <FiArrowLeft className="text-xl" />
                </button>
                <div className="relative cursor-pointer" onClick={() => setShowProfile(true)}>
                  <img src={selectedUser.profilePic ? `${selectedUser.profilePic}?t=${selectedUser.updatedAt || Date.now()}` : "/default-avatar.png"} 
                       alt={selectedUser.name} className="w-10 h-10 rounded-full object-cover border border-gray-200" />
                  <div className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 rounded-full ring-2 ring-white"></div>
                </div>
                <div>
                  <h2 className="text-[#2C2C2C] font-semibold text-lg">{selectedUser.name}</h2>
                  <p className="text-xs text-gray-400">Online</p>
                </div>
              </div>

              <div className="relative">
                <button onClick={(e) => { e.stopPropagation(); setShowChatMenu(prev => !prev); }} className="text-[#2C2C2C] hover:text-[#FF7A00] p-2 rounded-full hover:bg-gray-50 transition text-2xl">
                  <FiMoreVertical />
                </button>

                {showChatMenu && (
                  <div 
                    onClick={(e) => e.stopPropagation()} 
                    className="absolute right-0 mt-2 w-52 bg-white rounded-xl border border-gray-200 shadow-xl z-[100] overflow-visible"
                  >
                    <button 
                      onClick={() => { setShowSearch(true); setShowChatMenu(false); }} 
                      className="w-full text-left px-4 py-3 hover:bg-gray-50 text-[#2C2C2C] flex items-center gap-2 text-sm font-medium transition"
                    >
                      <span>🔍</span> Search
                    </button>
                    
                    {/* CHANGE BACKGROUND BUTTON - Now using simpler toggle */}
                    <div className="relative">
                      <button 
                        onClick={(e) => {
                          e.stopPropagation();
                          setShowBackgroundSubMenu(!showBackgroundSubMenu);
                        }}
                        className="w-full text-left px-4 py-3 hover:bg-gray-50 text-[#2C2C2C] flex items-center gap-2 text-sm font-medium transition"
                      >
                        <span>🖼</span> Change Background
                      </button>

                      {/* SUB MENU - z-[101] ensures it sits on top of everything */}
                      {showBackgroundSubMenu && (
                        <div 
                          onClick={(e) => e.stopPropagation()}
                          className="absolute top-0 right-full mr-2 w-64 bg-white rounded-xl border border-gray-200 shadow-xl p-3 z-[101]"
                        >
                          <div className="max-h-80 overflow-y-auto p-1">
                            <div className="grid grid-cols-2 gap-2">
                              {chatBackgrounds.map((bg) => (
                                <img 
                                  key={bg} 
                                  src={bg} 
                                  alt="bg" 
                                  onClick={() => { 
                                    setChatBackground(bg); 
                                    localStorage.setItem(`chatBackground_${selectedUser._id}`, bg); 
                                    setShowChatMenu(false); 
                                    setShowBackgroundSubMenu(false); 
                                  }}
                                  className="w-full h-20 object-cover rounded-lg cursor-pointer hover:scale-105 transition border border-gray-100" 
                                />
                              ))}
                            </div>
                          </div>
                          <button 
                            onClick={() => { 
                              localStorage.removeItem(`chatBackground_${selectedUser._id}`); 
                              setChatBackground(""); 
                              setShowBackgroundSubMenu(false); 
                              setShowChatMenu(false); 
                            }}
                            className="w-full mt-2 text-left px-4 py-2 hover:bg-red-50 rounded-lg text-red-500 text-sm font-medium transition"
                          >
                            🗑 Remove Background
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </div>

        {/* ================= SEARCH BAR ================= */}
        {showSearch && (
          <div className="px-4 py-3 bg-[#f8f9fa] border-b border-gray-200 flex items-center gap-3">
            <input ref={searchInputRef} type="text" value={searchText} onChange={(e) => setSearchText(e.target.value)}
                   onKeyDown={(e) => { if (e.key === "Enter") goToPreviousMatch(); }}
                   placeholder="Search messages..." className="flex-1 bg-white text-[#2C2C2C] rounded-full px-4 py-2 outline-none border border-gray-200 focus:border-[#FF7A00] transition" />
            <button onClick={goToPreviousMatch} className="text-[#2C2C2C] hover:text-[#FF7A00] text-xl transition"><FiChevronUp /></button>
            <button onClick={goToNextMatch} className="text-[#2C2C2C] hover:text-[#FF7A00] text-xl transition"><FiChevronDown /></button>
            <button onClick={() => { setShowSearch(false); setSearchText(""); setMatchedIndexes([]); }} className="text-gray-400 hover:text-red-500 text-xl transition"><FiX /></button>
          </div>
        )}

        {/* ================= PINNED BANNER ================= */}
        {pinnedMessage && (
          <div className="px-4 py-2 bg-orange-50 border-b border-orange-100 cursor-pointer hover:bg-orange-100 transition flex items-center justify-between"
               onClick={() => { messageRefs.current[pinnedMessage._id]?.scrollIntoView({ behavior: "smooth", block: "center" }); }}>
            <div className="flex items-center gap-2">
              <span className="text-[#FF7A00] text-sm font-bold">📌</span>
              <div className="flex flex-col">
                <span className="text-[#FF7A00] font-semibold text-xs">Pinned Message</span>
                <div className="text-[#2C2C2C] truncate text-sm max-w-[200px]">{pinnedMessage.text || "📷 Image"}</div>
              </div>
            </div>
          </div>
        )}

        {/* ================= MESSAGES AREA ================= */}
        {/* 3. Changed this background to 'bg-transparent' so the main wrapper's background image shows through */}
        <div className="flex-1 overflow-y-auto p-4 md:p-6 bg-transparent">
          {messages.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center text-gray-400">
              <span className="text-6xl mb-4">👋</span>
              <p className="text-[#2C2C2C] font-medium">No messages yet</p>
              <p className="text-sm text-gray-400">Say hello to {selectedUser.name}!</p>
            </div>
          ) : (
            messages.map((msg, index) => {
              const isMine = msg.sender === currentUserId;
              const matched = matchedIndexes[currentMatch] === index;
              return (
                <MessageBubble
                  onReply={(message) => setReplyMessage(message)}
                  key={msg._id}
                  msg={msg}
                  isMine={isMine}
                  currentUserId={currentUserId}
                  selectedUser={selectedUser}
                  matched={matchedIndexes[currentMatch] === index}
                  selectedMessages={selectedMessages}
                  selectionMode={selectionMode}
                  toggleMessageSelection={toggleMessageSelection}
                  handleReaction={handleReaction}
                  onContextMenu={(e, msg) => { setReactionMenu({ x: e.pageX, y: e.pageY, message: msg }); setMenu({ x: e.pageX, y: e.pageY + 55, message: msg }); }}
                  scrollToMessage={scrollToMessage}
                  setPreviewImage={setPreviewImage}
                  setReplyMessage={setReplyMessage}
                  messageRef={(el) => { if (el) messageRefs.current[msg._id] = el; }}
                >
                  {selectionMode && (
                    <div className={`mr-3 w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all duration-300 shrink-0
                      ${selectedMessages.includes(msg._id) ? "bg-[#FF7A00] border-[#FF7A00] scale-110" : "border-gray-300"}`}>
                      {selectedMessages.includes(msg._id) && <span className="text-white text-xs">✓</span>}
                    </div>
                  )}

                    <div
                      className={`relative max-w-[75%] md:max-w-md px-4 py-2.5 rounded-2xl shadow-sm transition-all duration-300
                        ${
                          matched
                            ? "ring-4 ring-yellow-400 shadow-yellow-300/50"
                            : ""
                        }
                        ${
                          isMine
                            ? "bg-[#FF7A00] text-white rounded-br-sm"
                            : "bg-white border border-gray-100 rounded-bl-sm"
                        }`}
                    >

                    <div>
                      {msg.replyTo && (
                        <div onClick={() => scrollToMessage(msg.replyTo._id)}
                             className={`mb-2 border-l-4 ${isMine ? 'border-white/40' : 'border-[#FF7A00]'} bg-black/5 rounded-md px-3 py-1.5 cursor-pointer hover:bg-black/10 transition`}>
                          <p className={`text-xs font-semibold ${isMine ? 'text-white/80' : 'text-[#FF7A00]'}`}>
                            {msg.replyTo.sender === currentUserId ? "You" : selectedUser.name}
                          </p>
                          <p className={`text-sm truncate ${isMine ? 'text-white/70' : 'text-gray-500'}`}>
                            {msg.replyTo.text || "📷 Image"}
                          </p>
                        </div>
                      )}

                      {msg.deletedForEveryone ? (
                        <p className="italic text-gray-400 text-sm">🚫 Message unavailable</p>
                      ) : (
                        <>
                          {msg.image && (
                            <img src={msg.image} alt="Message" className="mt-2 rounded-xl max-w-full cursor-pointer shadow-sm"
                                 onClick={() => setPreviewImage(msg.image)} />
                          )}
                          {msg.text && <p className="leading-relaxed">{msg.text}</p>}
                          {msg.attachment && (
                            <a href={msg.attachment.url} download={msg.attachment.name} target="_blank" rel="noreferrer"
                               className={`mt-2 flex items-center gap-2 rounded-lg ${isMine ? 'bg-white/20 text-white' : 'bg-gray-100 text-[#2C2C2C]'} px-3 py-2 text-sm hover:bg-opacity-30 transition`}>
                              <FiPaperclip /> <span className="truncate">{msg.attachment.name}</span>
                            </a>
                          )}
                        </>
                      )}

                      {msg.reactions && msg.reactions.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-2">
                          {[...new Set(msg.reactions.map((r) => r.emoji))].map((emoji) => {
                            const count = msg.reactions.filter((r) => r.emoji === emoji).length;
                            const hasReacted = msg.reactions.some((r) => r.user === currentUserId && r.emoji === emoji);
                            return (
                              <div key={emoji} className={`rounded-full px-2 py-0.5 text-xs flex items-center gap-1 border
                                ${hasReacted ? (isMine ? 'bg-white/20 border-white/30' : 'bg-[#FF7A00]/10 border-[#FF7A00]/30 text-[#FF7A00]') : 'bg-gray-50 border-gray-200 text-gray-600'}`}>
                                <span>{emoji}</span> <span className="font-bold">{count}</span>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>

                    <div className={`flex justify-end items-center gap-1 text-[9px] mt-0.5 ${isMine ? 'text-white/70' : 'text-gray-400'}`}>
                      <span>{new Date(msg.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</span>
                      {isMine && (
                        msg.seen ? <IoCheckmarkDone className="text-white" /> :
                        msg.delivered ? <IoCheckmarkDone className="text-white/50" /> : <IoCheckmark className="text-white/50" />
                      )}
                    </div>
                  </div>
                </MessageBubble>
              );
            })
          )}

          {typing && (
            <div className="flex justify-start my-2 animate-fadeIn">
              <div className="bg-white border border-gray-200 rounded-2xl rounded-bl-md px-4 py-3 shadow-sm">
                <div className="flex items-center gap-1 h-5">
                  <span className="typing-dot bg-[#FF7A00]"></span>
                  <span className="typing-dot bg-[#FF7A00]"></span>
                  <span className="typing-dot bg-[#FF7A00]"></span>
                </div>
              </div>
            </div>
          )}

          <div ref={bottomRef}></div>
        </div>

        {/* ================= INPUT AREA ================= */}
        <div className="relative border-t border-gray-200 bg-white px-4 py-3">
          {replyMessage && (
            <div className="mb-3 rounded-xl border-l-4 border-[#FF7A00] bg-[#f8f9fa] px-4 py-3 relative">
              <button onClick={() => setReplyMessage(null)} className="absolute top-3 right-3 text-gray-400 hover:text-[#2C2C2C] transition">
                <FiX />
              </button>
              <p className="text-sm font-semibold text-[#FF7A00] mb-1">
                Replying to {replyMessage.sender === currentUserId ? "You" : selectedUser.name}
              </p>
              <p className="text-[#2C2C2C] truncate pr-8 text-sm">{replyMessage.text || "📷 Image"}</p>
            </div>
          )}

          {showEmojiPicker && (
            <div className="absolute bottom-20 left-4 z-50 shadow-xl rounded-xl border border-gray-200">
              <EmojiPicker onEmojiClick={handleEmojiClick} />
            </div>
          )}

          {(selectedImage || selectedFile) && (
            <div className="mb-3 flex items-center gap-3 rounded-xl bg-[#f8f9fa] border border-gray-200 p-2">
              {selectedImage ? (
                <button type="button" onClick={() => setPreviewImage(selectedImageUrl)} className="h-14 w-14 overflow-hidden rounded-lg border border-gray-200">
                  <img src={selectedImageUrl} alt="Selected" className="h-full w-full object-cover" />
                </button>
              ) : (
                <FiPaperclip className="ml-2 text-xl text-[#FF7A00]" />
              )}
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-[#2C2C2C]">{(selectedImage || selectedFile).name}</p>
                <p className="text-xs text-gray-400">{Math.ceil((selectedImage || selectedFile).size / 1024)} KB</p>
              </div>
              <button type="button" onClick={clearSelectedAttachment} className="rounded-full p-2 text-gray-400 hover:bg-gray-200 hover:text-red-500 transition">
                <FiX />
              </button>
            </div>
          )}

          <div className="flex items-center gap-2 md:gap-3">
            <button onClick={() => setShowEmojiPicker(!showEmojiPicker)} className="text-gray-400 hover:text-[#FF7A00] transition text-2xl p-1">
              <BsEmojiSmile />
            </button>
            <button onClick={() => fileInputRef.current.click()} className="text-gray-400 hover:text-[#FF7A00] transition text-2xl p-1">
              <FiPaperclip />
            </button>
            <button onClick={() => imageInputRef.current.click()} className="text-gray-400 hover:text-[#FF7A00] transition text-2xl p-1">
              <FiImage />
            </button>
            <input ref={fileInputRef} type="file" hidden onChange={(e) => { if (e.target.files.length > 0) { setSelectedImage(null); setSelectedFile(e.target.files[0]); } }} />
            <input ref={imageInputRef} type="file" hidden accept="image/*" onChange={(e) => { if (e.target.files.length > 0) { setSelectedFile(null); setSelectedImage(e.target.files[0]); } }} />

            <input type="text" value={text} onChange={(e) => { setText(e.target.value); socket.emit("typing", { receiverId: selectedUser._id, senderId: currentUserId }); clearTimeout(typingTimeout.current); typingTimeout.current = setTimeout(() => { socket.emit("stopTyping", { receiverId: selectedUser._id, senderId: currentUserId }); }, 1000); }}
                   placeholder="Type a message..." className="flex-1 bg-[#f8f9fa] text-[#2C2C2C] rounded-full px-5 py-3 outline-none border border-transparent focus:border-[#FF7A00] focus:bg-white transition"
                   onKeyDown={(e) => { if (e.key === "Enter") handleSend(); }} />

            <button className="text-gray-400 hover:text-[#FF7A00] transition text-2xl p-1"><FiMic /></button>

            <button onClick={handleSend} className="bg-[#FF7A00] hover:bg-[#E66E00] rounded-full p-3 text-white shadow-md shadow-orange-200 hover:shadow-orange-300 transform active:scale-95 transition">
              <FiSend />
            </button>
          </div>
        </div>

        {/* ================= OVERLAYS ================= */}
        {reactionMenu && (
          <div className="fixed bg-white rounded-full shadow-xl px-3 py-2 flex gap-2 z-50 border border-gray-200 animate-reactionPopup"
               style={{ left: reactionLeft, top: reactionTop }}>
            {["❤️", "😂", "👍", "😮", "😢", "🙏"].map((emoji) => (
              <button key={emoji} className="text-2xl transition-all duration-200 hover:scale-125 active:scale-95"
                      onClick={() => { handleReaction(reactionMenu.message._id, emoji); setTimeout(() => { setReactionMenu(null); setMenu(null); }, 100); }}>
                {emoji}
              </button>
            ))}
          </div>
        )}

        {menu && (
          <MessageMenu x={menu.x} y={menu.y}
            onReply={() => { setReplyMessage(menu.message); setMenu(null); }}
            onCopy={() => { navigator.clipboard.writeText(menu.message.text); setMenu(null); }}
            onSelect={() => { setSelectionMode(true); toggleMessageSelection(menu.message._id); setMenu(null); }}
            isSender={menu.message.sender === currentUserId}
            onDeleteForMe={async () => { try { await deleteMessage(menu.message._id, false); setMessages(prev => prev.filter(msg => msg._id !== menu.message._id)); setMenu(null); } catch (err) { console.error(err); } }}
            onDeleteForEveryone={async () => { try { await deleteMessage(menu.message._id, true); setMessages((prev) => prev.filter((msg) => msg._id !== menu.message._id)); setPinnedMessage((prev) => prev?._id === menu.message._id ? null : prev); setMenu(null); } catch (err) { console.error(err); } }}
            onPin={async () => { try { const updated = await pinMessage(menu.message._id); setMessages(prev => { const updatedMessages = prev.map(msg => msg._id === updated._id ? updated : { ...msg, pinned: false }); setPinnedMessage(updated); return updatedMessages; }); setMenu(null); } catch (err) { console.error(err); } }}
            isPinned={menu.message.pinned}
            onUnpin={async () => { const updated = await unpinMessage(menu.message._id); setMessages(prev => { const updatedMessages = prev.map(msg => msg._id === updated._id ? updated : msg); setPinnedMessage(null); return updatedMessages; }); setMenu(null); }}
          />
        )}

        {previewImage && (
          <div onClick={() => setPreviewImage(null)} className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 backdrop-blur-sm">
            <img src={previewImage} alt="Preview" className="max-w-[90%] max-h-[90%] object-contain rounded-xl shadow-2xl" />
          </div>
        )}

        {showProfile && <ProfilePanel user={selectedUser} onClose={() => setShowProfile(false)} />}
      </div>
    </main>
  );
}

export default ChatWindow;