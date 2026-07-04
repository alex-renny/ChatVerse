import { useEffect, useState } from "react";
import { getMessages } from "../../services/messageService";
import { sendMessage } from "../../services/messageService";
import socket from "../../services/socket";
import { useAuth } from "../../context/AuthContext";

function ChatWindow({ selectedUser }) {
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const { user } = useAuth();

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
                {msg.text}
              </div>
            </div>
          );
        })
        )}

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

    </main>
  );
}

export default ChatWindow;