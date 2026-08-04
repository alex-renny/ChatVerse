import { FiMapPin } from "react-icons/fi";
import { useState } from "react";
import { useEffect, useRef } from "react";

function UserCard({
  user,
  onSelect,
  online,
  onTogglePin,
  onDeleteChat,
}) {

  const [showMenu, setShowMenu] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const menuRef = useRef(null);

  useEffect(() => {
    const close = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setShowMenu(false);
      }
    };

    document.addEventListener("click", close);

    return () => document.removeEventListener("click", close);
  }, []);
  return (
    <div
      ref={menuRef}
      onClick={() => {
        console.log("Clicked:", user);
        onSelect(user);
      }}
      onContextMenu={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setShowMenu(true);
      }}
      className="relative cursor-pointer group bg-white hover:bg-[#f8f9fa] px-4 py-4 border-b border-gray-100 transition-all duration-200"
    >
      <div className="flex items-center gap-3">

        {/* Profile Picture */}
        <div className="w-12 h-12 rounded-full overflow-hidden bg-[#FF7A00] flex items-center justify-center text-white font-bold text-lg shadow-sm shrink-0">
          {user.profilePic ? (
            <img
              src={
                user.profilePic?.startsWith("http")
                  ? user.profilePic
                  : `https://chatverse-server-eoma.onrender.com${user.profilePic}`
              }
              alt={user.name}
              className="w-full h-full object-cover"
            />
          ) : (
            user.name?.charAt(0).toUpperCase()
          )}
        </div>

        {/* Name & Bio */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between">
            <h3 className="text-[#2C2C2C] font-semibold truncate">
              {user.name}
            </h3>

            <div className="flex items-center gap-2 shrink-0 ml-2">
              {user.isPinned && (
                <FiMapPin className="text-[#FF7A00] opacity-80" aria-label="Pinned chat" />
              )}
              <div
                className={`w-2.5 h-2.5 rounded-full ring-2 ring-white ${
                  online ? "bg-emerald-500" : "bg-gray-300"
                }`}
              />
            </div>
          </div>

          <p className="text-gray-500 text-sm mt-0.5 truncate">
            {user.bio || "Start a conversation"}
          </p>
        </div>

      </div>
      
      {/* Pin/Unpin Action */}
      <div className="mt-2 flex justify-end">
        <button
          onClick={(event) => {
            event.stopPropagation();
            onTogglePin(user);
          }}
          className={`text-xs font-medium px-3 py-1 rounded-full transition-colors duration-200 ${
            user.isPinned 
              ? "bg-orange-50 text-[#FF7A00] hover:bg-orange-100" 
              : "bg-transparent text-gray-400 hover:text-[#FF7A00] group-hover:bg-gray-100"
          }`}
        >
          {user.isPinned ? "Unpin chat" : "Pin chat"}
        </button>
      </div>
            {showMenu && (
              <div className="absolute right-4 top-14 bg-white border rounded-lg shadow-lg z-50">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowMenu(false);

                    setShowConfirm(true);
                  }}
                  className="block w-full px-4 py-2 text-left text-red-500 hover:bg-gray-100"
                >
                  🗑 Delete Chat
                </button>
              </div>
            )}
            {showConfirm && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-[999]">
          <div className="bg-white rounded-xl p-6 w-80 shadow-xl">
            <h2 className="text-lg font-semibold">
              Delete Chat?
            </h2>

            <p className="text-gray-500 mt-2">
              Delete chat with <b>{user.name}</b>?
            </p>

            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowConfirm(false)}
                className="px-4 py-2 rounded-lg bg-gray-200"
              >
                Cancel
              </button>

              <button
                onClick={() => {
                  onDeleteChat(user);
                  setShowConfirm(false);
                }}
                className="px-4 py-2 rounded-lg bg-red-500 text-white hover:bg-orange-500"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default UserCard;