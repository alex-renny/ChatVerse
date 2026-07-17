import { FiUser, FiSettings, FiMoon, FiLogOut } from "react-icons/fi";

function ProfileMenu({
  onProfile,
  onSettings,
  onTheme,
  onLogout,
}) {
  return (
    <div className="absolute top-16 right-4 w-56 bg-slate-800 rounded-xl shadow-2xl border border-slate-700 overflow-hidden z-50">

      <button
        onClick={onProfile}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white"
      >
        <FiUser />
        My Profile
      </button>

      <button
        onClick={onSettings}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white"
      >
        <FiSettings />
        Settings
      </button>

      <button
        onClick={onTheme}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700 text-white"
      >
        <FiMoon />
        Theme
      </button>

      <button
        onClick={onLogout}
        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-red-600 text-white"
      >
        <FiLogOut />
        Logout
      </button>

    </div>
  );
}

export default ProfileMenu;