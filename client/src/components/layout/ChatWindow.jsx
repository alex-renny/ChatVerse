function ChatWindow() {
  return (
    <main className="flex-1 flex flex-col bg-slate-900">
      <div className="flex-1 flex items-center justify-center">
        <h2 className="text-slate-500 text-3xl">
          Welcome to ChatVerse 👋
        </h2>
      </div>

      <div className="p-4 border-t border-slate-700">
        <input
          type="text"
          placeholder="Type a message..."
          className="w-full p-4 rounded-lg bg-slate-800 text-white outline-none"
        />
      </div>
    </main>
  );
}

export default ChatWindow;