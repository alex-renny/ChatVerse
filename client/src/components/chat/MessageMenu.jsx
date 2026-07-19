function MessageMenu({
  x,
  y,
  onReply,
  onCopy,
  onPin,
  isPinned,
  onUnpin,
  onDeleteForMe,
  onDeleteForEveryone,
  onSelect,
  isSender,
}) {

  const menuWidth = 220;
  const menuHeight = isSender ? 260 : 210;

  const left =
    x + menuWidth > window.innerWidth
      ? window.innerWidth - menuWidth - 10
      : x;

  const top =
    y + menuHeight > window.innerHeight
      ? window.innerHeight - menuHeight - 10
      : y;

  return (
    <div
      onClick={(e) => e.stopPropagation()}
      className="fixed bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50 w-56 max-h-72 overflow-y-auto"
      style={{
        top,
        left,
      }}
    >
      <button
        onClick={onReply}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white transition"
      >
        ↩ <span>Reply</span>
      </button>

      <button
        onClick={onCopy}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white transition"
      >
        📋 <span>Copy</span>
      </button>

      {isPinned ? (
        <button
          onClick={onUnpin}
          className="w-full text-left px-4 py-3 hover:bg-slate-700 text-white"
        >
          📍 Unpin Message
        </button>
      ) : (
        <button
          onClick={onPin}
          className="w-full text-left px-4 py-3 hover:bg-slate-700 text-white"
        >
          📌 Pin Message
        </button>
      )}

      <button
        onClick={onSelect}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white transition"
      >
        ✅ <span>Select</span>
      </button>

      <button
        onClick={onDeleteForMe}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white transition"
      >
        🗑 <span>Delete for Me</span>
      </button>

      {isSender && (
        <button
          onClick={onDeleteForEveryone}
          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-red-700 text-red-300 transition"
        >
          🌍 <span>Delete for Everyone</span>
        </button>
      )}
    </div>
  );
}

export default MessageMenu;