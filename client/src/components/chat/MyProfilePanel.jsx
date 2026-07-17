import { FiX } from "react-icons/fi";

function MyProfilePanel({ user, onClose }) {
  if (!user) return null;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex justify-end">
      <div className="w-full md:w-96 h-full bg-slate-900 shadow-2xl overflow-y-auto">

        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-slate-800">
          <h2 className="text-xl font-bold text-white">
            My Profile
          </h2>

          <button
            onClick={onClose}
            className="text-white text-2xl"
          >
            <FiX />
          </button>
        </div>

        {/* Avatar */}
        <div className="flex flex-col items-center mt-8">
          <div className="w-32 h-32 rounded-full bg-blue-600 flex items-center justify-center text-5xl font-bold text-white">
            {user.name?.charAt(0).toUpperCase()}
          </div>

          <h3 className="mt-5 text-2xl font-bold text-white">
            {user.name}
          </h3>

          <p className="text-slate-400">
            {user.email}
          </p>
        </div>

        {/* About */}
        <div className="px-6 mt-8">
          <h4 className="text-blue-400 font-semibold mb-2">
            About
          </h4>

          <div className="bg-slate-800 rounded-xl p-4 text-slate-300">
            {user.bio || "Hey there! I'm using ChatVerse 💬"}
          </div>
        </div>

        {/* Joined */}
        <div className="px-6 mt-6">
          <h4 className="text-blue-400 font-semibold mb-2">
            Joined
          </h4>

          <div className="bg-slate-800 rounded-xl p-4 text-slate-300">
            {user.createdAt
              ? new Date(user.createdAt).toLocaleDateString()
              : "Unknown"}
          </div>
        </div>

      </div>
    </div>
  );
}

export default MyProfilePanel;