import { FiCornerUpLeft, FiCopy, FiCheckSquare, FiTrash2, FiGlobe, FiMapPin, FiBookmark } from "react-icons/fi";

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
      className="fixed bg-white border border-gray-200 rounded-xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.15)] z-50 w-56 overflow-hidden py-1.5"
      style={{
        top,
        left,
      }}
    >
      {/* Reply */}
      <button
        onClick={onReply}
        className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
      >
        <FiCornerUpLeft className="text-xl text-gray-400 group-hover:text-[#FF7A00] transition-colors" />
        <span className="text-sm font-medium">Reply</span>
      </button>

      {/* Copy */}
      <button
        onClick={onCopy}
        className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
      >
        <FiCopy className="text-xl text-gray-400 group-hover:text-[#FF7A00] transition-colors" />
        <span className="text-sm font-medium">Copy</span>
      </button>

      {/* Pin / Unpin */}
      {isPinned ? (
        <button
          onClick={onUnpin}
          className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
        >
          <FiMapPin className="text-xl text-[#FF7A00] transition-colors" />
          <span className="text-sm font-medium">Unpin Message</span>
        </button>
      ) : (
        <button
          onClick={onPin}
          className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
        >
          <FiBookmark className="text-xl text-gray-400 group-hover:text-[#FF7A00] transition-colors" />
          <span className="text-sm font-medium">Pin Message</span>
        </button>
      )}

      {/* Select */}
      <button
        onClick={onSelect}
        className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
      >
        <FiCheckSquare className="text-xl text-gray-400 group-hover:text-[#FF7A00] transition-colors" />
        <span className="text-sm font-medium">Select</span>
      </button>

      {/* Divider */}
      <div className="mx-5 my-1.5 h-px bg-gray-100"></div>

      {/* Delete for Me */}
      <button
        onClick={onDeleteForMe}
        className="w-full flex items-center gap-3 px-5 py-3 hover:bg-red-50 text-[#2C2C2C] transition-colors group"
      >
        <FiTrash2 className="text-xl text-gray-400 group-hover:text-red-500 transition-colors" />
        <span className="text-sm font-medium group-hover:text-red-500">Delete for Me</span>
      </button>

      {/* Delete for Everyone (Only if sender) */}
      {isSender && (
        <button
          onClick={onDeleteForEveryone}
          className="w-full flex items-center gap-3 px-5 py-3 hover:bg-red-50 text-[#2C2C2C] transition-colors group"
        >
          <FiGlobe className="text-xl text-gray-400 group-hover:text-red-500 transition-colors" />
          <span className="text-sm font-medium group-hover:text-red-500">Delete for Everyone</span>
        </button>
      )}
    </div>
  );
}

export default MessageMenu;