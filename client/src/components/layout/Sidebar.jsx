import { useAuth } from "../../context/AuthContext";
import UserCard from "./UserCard";
import { useEffect, useState } from "react";
import { getUsers } from "../../services/userService";
import socket from "../../services/socket";

function Sidebar({ selectedUser,setSelectedUser, }) {
  const [users, setUsers] = useState([]);
  const [onlineUsers, setOnlineUsers] = useState([]);
  const { user, logout } = useAuth();

  const handleLogout = () => {
  socket.disconnect();
  logout();
};

  useEffect(() => {
  const loadUsers = async () => {
    try {
      const data = await getUsers();
      setUsers(data);
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

  return (
    <aside className="w-full md:w-80 h-screen bg-slate-900 border-r border-slate-800 flex flex-col">

      {/* Header */}
      <div className="p-5 border-b border-slate-800">

        <div className="flex justify-between items-center">

          <div>
            <h1 className="text-2xl font-bold text-white">
              💬 ChatVerse
            </h1>

            <p className="text-slate-400 text-sm">
              Welcome {user?.name}
            </p>
          </div>

          <button
            onClick={handleLogout}
            className="text-red-400 hover:text-red-300"
          >
            Logout
          </button>

        </div>

      </div>

      {/* Search */}

      <div className="p-4">

        <input
          placeholder="Search..."
          className="w-full p-3 rounded-xl bg-slate-800 text-white outline-none"
        />

      </div>

      {/* Contact List */}

      <div className="flex-1 overflow-y-auto">
        {users.map((u) => (
          <UserCard
            key={u._id}
            user={u}
            onSelect={setSelectedUser}
            online={onlineUsers.includes(u._id)}
          />
        ))}
      </div>

    </aside>
  );
}

export default Sidebar;