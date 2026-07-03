import { useAuth } from "../../context/AuthContext";
import UserCard from "./UserCard";
import { useEffect, useState } from "react";
import { getUsers } from "../../services/userService";

function Sidebar() {
  const [users, setUsers] = useState([]);
  const { user, logout } = useAuth();

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

  return (
    <aside className="w-80 bg-slate-900 border-r border-slate-800 flex flex-col">

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
            onClick={logout}
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

        <div className="flex-1 overflow-y-auto">
          {users.map((u) => (
            <UserCard
              key={u._id}
              name={u.name}
              message={u.bio || "Start a conversation"}
              online={u.isOnline}
            />
          ))}
        </div>  

      </div>

    </aside>
  );
}

export default Sidebar;