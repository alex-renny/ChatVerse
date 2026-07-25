import { FiMapPin } from "react-icons/fi";

function UserCard({ user, onSelect, online, onTogglePin }) {
  return (
    <div
      onClick={() => {
        console.log("Clicked:", user);
        onSelect(user);
      }}
      className="cursor-pointer group bg-white hover:bg-[#f8f9fa] px-4 py-4 border-b border-gray-100 transition-all duration-200"
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
    </div>
  );
}

export default UserCard;