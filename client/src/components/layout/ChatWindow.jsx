function ChatWindow({ selectedUser }) {
  if (!selectedUser) {
    return (
      <main className="flex-1 flex flex-col bg-slate-950">
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <h2 className="text-4xl font-bold text-white mb-4">
              Welcome to ChatVerse
            </h2>

            <p className="text-slate-400">
              Select a conversation to start chatting.
            </p>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="flex-1 flex flex-col bg-slate-950">
      <div className="p-5 border-b border-slate-800">
        <h2 className="text-2xl font-bold text-white">
          {selectedUser.name}
        </h2>

        <p className="text-slate-400">
          {selectedUser.email}
        </p>
      </div>

      <div className="flex-1 flex items-center justify-center text-slate-400">
        Start chatting with {selectedUser.name}
      </div>
    </main>
  );
}

export default ChatWindow;  