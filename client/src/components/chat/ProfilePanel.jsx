import { FiX } from "react-icons/fi";

function ProfilePanel({ user, onClose }) {
  if (!user) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex justify-end animate-fadeIn">
      
      {/* Panel Container */}
      <div className="w-full md:w-96 h-full bg-white shadow-2xl flex flex-col animate-slideInRight">
        
        {/* ================= HEADER ================= */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
          <h2 className="text-xl font-bold text-[#2C2C2C] tracking-tight">
            Profile
          </h2>

          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-gray-100 text-[#2C2C2C] hover:text-red-500 transition-colors text-2xl"
          >
            <FiX />
          </button>
        </div>

        {/* ================= AVATAR SECTION ================= */}
        <div className="flex flex-col items-center mt-8 px-6">
          <div className="relative">
            <div className="w-28 h-28 rounded-full overflow-hidden bg-[#FF7A00] flex items-center justify-center text-5xl text-white font-bold shadow-lg shadow-orange-100 border-4 border-white">
              {user.profilePic ? (
                <img
                  src={user.profilePic}
                  alt={user.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                user.name.charAt(0).toUpperCase()
              )}
            </div>
            {/* Subtle online indicator (optional) */}
            <div className="absolute bottom-1 right-1 w-4 h-4 bg-emerald-400 rounded-full border-2 border-white"></div>
          </div>

          <h3 className="mt-5 text-2xl font-bold text-[#2C2C2C]">
            {user.name}
          </h3>

          <p className="text-gray-500 text-sm font-medium">
            {user.email}
          </p>
        </div>

        {/* ================= INFO SECTIONS ================= */}
        <div className="mt-8 px-6 flex-1 overflow-y-auto">
          
          {/* About Section */}
          <div className="bg-[#f8f9fa] rounded-xl p-5 mb-4 border border-gray-100">
            <h4 className="text-[#FF7A00] font-semibold text-xs uppercase tracking-wider mb-2">
              About
            </h4>
            <p className="text-[#2C2C2C] leading-relaxed text-sm">
              {user.bio || "This user hasn't written a bio yet."}
            </p>
          </div>

          {/* Joined Section */}
          <div className="bg-[#f8f9fa] rounded-xl p-5 border border-gray-100">
            <h4 className="text-[#FF7A00] font-semibold text-xs uppercase tracking-wider mb-2">
              Member Since
            </h4>
            <p className="text-[#2C2C2C] text-sm font-medium">
              {new Date(user.createdAt).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })}
            </p>
          </div>

        </div>

        {/* ================= FOOTER ACTION (Optional) ================= */}
        <div className="p-6 border-t border-gray-100 mt-auto">
          <button 
            className="w-full py-3 bg-[#f8f9fa] hover:bg-gray-200 text-[#2C2C2C] font-medium rounded-xl transition-colors"
            onClick={onClose}
          >
            Close Profile
          </button>
        </div>

      </div>
    </div>
  );
}

export default ProfilePanel;