import chats from "../../data/chats";

function Sidebar() {
  return (
    <aside className="w-80 bg-slate-800 border-r border-slate-700 flex flex-col">
      {/* Search */}
      <div className="p-4">
        <input
          type="text"
          placeholder="🔍 Search chats..."
          className="w-full rounded-lg bg-slate-700 px-4 py-3 text-white placeholder-slate-400 outline-none focus:ring-2 focus:ring-emerald-500"
        />
      </div>

      {/* Chat List */}
      <div className="flex-1 overflow-y-auto">
        {chats.map((chat) => (
          <div
            key={chat.id}
            className="flex items-center justify-between px-4 py-4 hover:bg-slate-700 cursor-pointer transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="relative">
                <img
                  src={`https://i.pravatar.cc/150?img=${chat.id + 10}`}
                  alt={chat.name}
                  className="w-12 h-12 rounded-full"
                />

                {chat.online && (
                  <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-green-500 border-2 border-slate-800"></span>
                )}
              </div>

              <div>
                <h3 className="text-white font-semibold">
                  {chat.name}
                </h3>

                <p className="text-sm text-slate-400">
                  {chat.message}
                </p>
              </div>
            </div>

            {chat.unread > 0 && (
              <div className="bg-emerald-500 text-xs text-white rounded-full h-6 w-6 flex items-center justify-center">
                {chat.unread}
              </div>
            )}
          </div>
        ))}
      </div>
    </aside>
  );
}

export default Sidebar;