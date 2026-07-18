function MessageMenu({ x, y, onReply,onCopy, onDelete, onSelect }) {
  return (
    <div
      onClick={(e) => e.stopPropagation()}
      className="fixed bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50 w-48"
      style={{
        top: y,
        left: x,
      }}
    >
        <button
            onClick={onReply}
            className="w-full text-left px-4 py-3 hover:bg-slate-700 text-white"
            >
            ↩ Reply
        </button>

      <button
        onClick={onCopy}
        className="w-full text-left px-4 py-3 hover:bg-slate-700 text-white"
      >
        📋 Copy
      </button>

      <button
        onClick={onSelect}
        className="w-full text-left px-4 py-2 hover:bg-slate-700 text-white"
      >
        ✅ Select
      </button>

      <button
        onClick={() => {
            console.log("Button pressed");
            onDelete();
        }}
        className="w-full text-left px-4 py-3 hover:bg-red-700 text-red-300"
        >
        🗑 Delete
      </button>

      {/* <button onClick={onSelect}>
        ☑ Select
    </button> */}
    </div>
  );
}

export default MessageMenu;