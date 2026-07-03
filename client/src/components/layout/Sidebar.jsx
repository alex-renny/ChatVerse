import { useAuth } from "../../context/AuthContext";
import UserCard from "./UserCard";

function Sidebar() {
  const { user, logout } = useAuth();

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

        <UserCard
          name="John"
          message="Hey! What's up?"
          online={true}
        />

        <UserCard
          name="Emma"
          message="See you tomorrow!"
          online={false}
        />

        <UserCard
          name="David"
          message="Thank you 😊"
          online={true}
        />

      </div>

    </aside>
  );
}

export default Sidebar;