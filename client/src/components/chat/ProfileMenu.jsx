import { FiSearch, FiUser, FiSettings, FiMoon, FiLogOut } from "react-icons/fi";

function ProfileMenu({
  onProfile,
  onSettings,
  onTheme,
  onLogout,
  onSearch,
}) {
  const menuItems = [
    { icon: FiSearch, label: "Search", onClick: onSearch },
    { icon: FiUser, label: "My Profile", onClick: onProfile },
    { icon: FiSettings, label: "Settings", onClick: onSettings },
    { icon: FiMoon, label: "Theme", onClick: onTheme },
  ];

  return (
    <div className="absolute top-14 right-0 w-56 bg-white rounded-xl shadow-[0_10px_40px_-10px_rgba(0,0,0,0.15)] border border-gray-100 overflow-hidden z-50 py-1.5">
      
      {/* Main Menu Items */}
      {menuItems.map(({ icon: Icon, label, onClick }) => (
        <button
          key={label}
          onClick={onClick}
          className="w-full flex items-center gap-3 px-5 py-3 hover:bg-[#f8f9fa] text-[#2C2C2C] transition-colors group"
        >
          <Icon className="text-xl text-gray-400 group-hover:text-[#FF7A00] transition-colors" />
          <span className="text-sm font-medium">{label}</span>
        </button>
      ))}

      {/* Divider Line */}
      <div className="mx-5 my-1.5 h-px bg-gray-100"></div>

      {/* Logout Button - Styled independently */}
      <button
        onClick={onLogout}
        className="w-full flex items-center gap-3 px-5 py-3 hover:bg-red-50 text-[#2C2C2C] transition-colors group"
      >
        <FiLogOut className="text-xl text-gray-400 group-hover:text-red-500 transition-colors" />
        <span className="text-sm font-medium group-hover:text-red-500">Logout</span>
      </button>

    </div>
  );
}

export default ProfileMenu;