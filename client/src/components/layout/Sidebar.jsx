import { useAuth } from "../../context/AuthContext";
import UserCard from "./UserCard";
import { useEffect, useState, useRef } from "react";
import { getConversationUsers, getUsers, togglePinnedChat, checkChatAccess, verifyChatPassword } from "../../services/userService";
import socket from "../../services/socket";
import { FiMoreVertical, FiSearch, FiX } from "react-icons/fi";
import ProfileMenu from "../chat/ProfileMenu";
import MyProfilePanel from "../chat/MyProfilePanel";
import ChatPasswordPromptModal from "../chat/ChatPasswordPromptModal";

function Sidebar({ selectedUser, setSelectedUser }) {
  const [users, setUsers] = useState([]);
  const [allUsers, setAllUsers] = useState([]);
  const [search, setSearch] = useState("");
  const [showSearch, setShowSearch] = useState(false);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const { user, logout } = useAuth();
  const [showMenu, setShowMenu] = useState(false);
  const [showMyProfile, setShowMyProfile] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [passwordUser, setPasswordUser] = useState(null);
  const [pendingUser, setPendingUser] = useState(null);
  const menuRef = useRef(null);

  const handleLogout = () => {
  socket.disconnect();

  sessionStorage.removeItem("introPlayed");

  logout();
};

  useEffect(() => {
    function handleClickOutside(event) {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setShowMenu(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  useEffect(() => {
    const loadUsers = async () => {
      try {
        const data = await getConversationUsers();
        setUsers(data);
        const everyone = await getUsers();
        setAllUsers(everyone);
      } catch (error) {
        console.error(error);
      }
    };

    loadUsers();
  }, []);

  useEffect(() => {
    socket.on("onlineUsers", (users) => {
      console.log("Online Users:", users);
      setOnlineUsers(users);
    });

    return () => {
      socket.off("onlineUsers");
    };
  }, []);

  const filteredUsers =
    search.trim() === ""
      ? users
      : allUsers.filter((u) => {
          const matches =
            u.name.toLowerCase().includes(search.toLowerCase()) ||
            u.email.toLowerCase().includes(search.toLowerCase());

          return matches;
        });

  const handleTogglePin = async (chatUser) => {
    try {
      const { pinned } = await togglePinnedChat(chatUser._id);
      const updatePinnedState = (list) =>
        list
          .map((item) =>
            item._id === chatUser._id ? { ...item, isPinned: pinned } : item
          )
          .sort((a, b) => Number(b.isPinned) - Number(a.isPinned));

      setUsers(updatePinnedState);
      setAllUsers(updatePinnedState);
    } catch (error) {
      console.error(error);
    }
  };

  const handleSelectUser = async (chatUser) => {
    try {
      const result = await checkChatAccess(chatUser._id);

      if (result.enabled && !result.verified) {
        setPendingUser(chatUser);
        setPasswordUser(chatUser);
        return;
      }

      setSelectedUser(chatUser);
    } catch (err) {
      console.error(err);
    }
  };
  return (
    <aside className="w-full md:w-80 h-full min-h-0 bg-white flex flex-col shadow-sm relative z-20">
      
      {/* ================= HEADER ================= */}
      <div className="p-5 border-b border-gray-100 bg-white">
        <div className="flex justify-between items-center">
          
          <div>
            <h1 className="text-2xl font-bold text-[#FF7A00] tracking-tight">
              ReSender
            </h1>
            <p className="text-gray-500 text-xs font-medium mt-0.5">
              Welcome back, {user?.name}
            </p>
          </div>

          <div className="relative" ref={menuRef}>
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="text-[#2C2C2C] hover:text-[#FF7A00] transition-colors p-2 hover:bg-gray-50 rounded-full text-2xl"
            >
              <FiMoreVertical />
            </button>

            {showMenu && (
              <ProfileMenu
                onSearch={() => {
                  setShowMenu(false);
                  setShowSearch(true);
                }}
                onProfile={() => {
                  setShowMenu(false);
                  setShowMyProfile(true);
                }}
                onSettings={() => {
                  setShowMenu(false);
                  setShowSettings(true);
                }}
                onTheme={() => {
                  alert("Theme coming soon 🚀");
                  setShowMenu(false);
                }}
                onLogout={handleLogout}
              />
            )}
          </div>

        </div>
      </div>

      {/* ================= SEARCH BAR ================= */}
      {showSearch ? (
        <div className="p-4 bg-[#f8f9fa] border-b border-gray-200 flex items-center gap-3">
          <div className="relative flex-1">
            <FiSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-lg" />
            <input
              type="text"
              placeholder="Search name or email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white text-[#2C2C2C] border border-gray-200 outline-none focus:border-[#FF7A00] focus:ring-2 focus:ring-[#FF7A00]/20 placeholder:text-gray-400 transition-all"
              autoFocus
            />
          </div>
          <button
            onClick={() => {
              setShowSearch(false);
              setSearch("");
            }}
            className="p-2 text-gray-400 hover:text-red-500 transition-colors rounded-full hover:bg-red-50"
          >
            <FiX className="text-xl" />
          </button>
        </div>
      ) : (
        <div className="px-5 py-3 border-b border-gray-100 flex items-center gap-2">
          <button 
            onClick={() => setShowSearch(true)}
            className="flex-1 flex items-center gap-3 p-2.5 rounded-xl bg-[#f8f9fa] text-gray-500 hover:bg-gray-200 transition-colors text-sm"
          >
            <FiSearch className="text-lg" />
            <span>Search contacts...</span>
          </button>
        </div>
      )}

      {/* ================= CONTACT LIST ================= */}
      <div className="flex-1 overflow-y-auto bg-white scrollbar-thin scrollbar-thumb-gray-200">
        {filteredUsers.length > 0 ? (
          filteredUsers.map((u) => (
            <UserCard
              key={u._id}
              user={u}
              onSelect={handleSelectUser}
              online={onlineUsers.includes(u._id)}
              onTogglePin={handleTogglePin}
            />
          ))
        ) : (
          <div className="flex flex-col items-center justify-center h-full text-gray-400 p-8 text-center">
            <div className="text-4xl mb-3">💬</div>
            <p className="font-medium text-[#2C2C2C]">No users found</p>
            <p className="text-sm text-gray-400 mt-1">Try a different search term</p>
          </div>
        )}
      </div>

      {/* ================= PROFILE PANEL ================= */}
      {showMyProfile && (
        <MyProfilePanel
          user={user}
          onClose={() => setShowMyProfile(false)}
        />
      )}
      {passwordUser && (
        <ChatPasswordPromptModal
          user={passwordUser}
          onClose={() => {
            setPasswordUser(null);
            setPendingUser(null);
          }}
          onSubmit={async (password) => {
            await verifyChatPassword(pendingUser._id, password);
            setSelectedUser(pendingUser);
            setPasswordUser(null);
            setPendingUser(null);
          }}
        />
      )}
    </aside>
  );
}

export default Sidebar;