import { useEffect, useState, useRef } from "react";
import {getMessages,sendMessage,deleteMessage,} from "../../services/messageService";
import socket from "../../services/socket";
import { useAuth } from "../../context/AuthContext";
import MessageMenu from "../chat/MessageMenu";

function ChatWindow({ selectedUser }) {
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const { user } = useAuth();
  const bottomRef = useRef(null);
  const [menu, setMenu] = useState(null);

  const handleSend = async () => {
  if (!text.trim()) return;

  try {
    const newMessage = await sendMessage(selectedUser._id, text);

    setMessages((prev) => [...prev, newMessage]);

    setText("");

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
}, [messages]);

  useEffect(() => {
    if (!selectedUser) return;

    const loadMessages = async () => {
      try {
        const data = await getMessages(selectedUser._id);
        setMessages(data);
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
              <p>{msg.text}</p>

              <p className="text-[11px] text-slate-300 mt-1 text-right">
                {new Date(msg.createdAt).toLocaleTimeString([], {
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </p>
            </div>
          </div>
        </div>
      );
    })
  )}

  {/* Auto-scroll target */}
  <div ref={bottomRef}></div>

</div>
      <div className="p-4 border-t border-slate-800 flex gap-3">
        <input
          type="text"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 bg-slate-800 text-white p-3 rounded-xl outline-none"
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              handleSend();
            }
          }}
        />

        <button
          onClick={handleSend}
          className="bg-blue-600 hover:bg-blue-700 px-5 rounded-xl text-white"
        >
          Send
        </button>
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

    </main>
  );
}

export default ChatWindow;