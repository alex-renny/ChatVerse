import { useAuth } from "../../context/AuthContext";
import UserCard from "./UserCard";
import { useEffect, useState,useRef } from "react";
import {getConversationUsers,getUsers} from "../../services/userService";
import socket from "../../services/socket";
import { FiMoreVertical } from "react-icons/fi";
import ProfileMenu from "../chat/ProfileMenu";
import MyProfilePanel from "../chat/MyProfilePanel";

function Sidebar({ selectedUser,setSelectedUser, }) {
  const [users, setUsers] = useState([]);
  const [allUsers, setAllUsers] = useState([]);
  const [search, setSearch] = useState("");
  const [onlineUsers, setOnlineUsers] = useState([]);
  const { user, logout } = useAuth();
  const [showMenu, setShowMenu] = useState(false);
  const [showMyProfile, setShowMyProfile] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const menuRef = useRef(null);

  const handleLogout = () => {
  socket.disconnect();
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

  return (
    <aside className="w-full md:w-80 h-screen bg-slate-900 border-r border-slate-800 flex flex-col">

      {/* Header */}
      <div className="relative p-5 border-b border-slate-800">

        <div className="flex justify-between items-center">

          <div>
            <h1 className="text-2xl font-bold text-white">
              💬 ChatVerse
            </h1>

            <p className="text-slate-400 text-sm">
              Welcome {user?.name}
            </p>
          </div>

          <div className="relative" ref={menuRef}>

            <button
              onClick={() => setShowMenu(!showMenu)}
              className="text-white text-2xl"
            >
              <FiMoreVertical />
            </button>

            {showMenu && (
              <ProfileMenu
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

      {/* Search */}

      <div className="p-4">

        <input
          type="text"
          placeholder="Search name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full p-3 rounded-xl bg-slate-800 text-white outline-none"
        />

      </div>

      {/* Contact List */}

      <div className="flex-1 overflow-y-auto">
        {filteredUsers.map((u) => (
          <UserCard
            key={u._id}
            user={u}
            onSelect={setSelectedUser}
            online={onlineUsers.includes(u._id)}
          />
        ))}
      </div>

      {showMyProfile && (
  <MyProfilePanel
    user={user}
    onClose={() => setShowMyProfile(false)}
  />
)}

    </aside>
  );
}

export default Sidebar;