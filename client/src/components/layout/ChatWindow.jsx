const messages = [
  {
    id: 1,
    sender: "John",
    text: "Hey Alex 👋",
    own: false,
    time: "10:30 AM",
  },
  {
    id: 2,
    sender: "Alex",
    text: "Hi John!",
    own: true,
    time: "10:31 AM",
  },
  {
    id: 3,
    sender: "John",
    text: "How are you?",
    own: false,
    time: "10:32 AM",
  },
  {
    id: 4,
    sender: "Alex",
    text: "I'm doing great! 😄",
    own: true,
    time: "10:33 AM",
  },
];

function ChatWindow() {
  return (
    <main className="flex-1 flex flex-col bg-slate-900">

      {/* Chat Header */}
      <div className="h-20 border-b border-slate-700 px-6 flex items-center justify-between bg-slate-800">
        <div>
          <h2 className="text-white text-xl font-semibold">
            John
          </h2>

          <p className="text-green-400 text-sm">
            🟢 Online
          </p>
        </div>

        <div className="flex gap-4 text-2xl">
          <button>📞</button>
          <button>🎥</button>
        </div>
      </div>

      {/* Messages */}

      <div className="flex-1 overflow-y-auto p-6 space-y-4">

        {messages.map((message) => (

          <div
            key={message.id}
            className={`flex ${
              message.own ? "justify-end" : "justify-start"
            }`}
          >

            <div
              className={`max-w-xs lg:max-w-md rounded-2xl px-4 py-3 ${
                message.own
                  ? "bg-emerald-500 text-white"
                  : "bg-slate-700 text-white"
              }`}
            >
              <p>{message.text}</p>

              <span className="text-xs opacity-70 block mt-2">
                {message.time}
              </span>

            </div>

          </div>

        ))}

      </div>

      {/* Message Input */}

      <div className="border-t border-slate-700 bg-slate-800 p-4">

        <div className="flex items-center gap-3">

          <button className="text-2xl">
            😊
          </button>

          <input
            type="text"
            placeholder="Type a message..."
            className="flex-1 bg-slate-700 rounded-full px-5 py-3 text-white outline-none"
          />

          <button className="text-2xl">
            📎
          </button>

          <button className="text-2xl">
            🎤
          </button>

          <button className="bg-emerald-500 rounded-full w-12 h-12 text-xl hover:bg-emerald-600 transition">
            ➤
          </button>

        </div>

      </div>

    </main>
  );
}

export default ChatWindow;