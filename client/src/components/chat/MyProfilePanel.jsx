import { FiTrash2, FiX, FiCamera, FiEdit2 } from "react-icons/fi";
import { useState, useRef } from "react";
import { useAuth } from "../../context/AuthContext";
import { uploadProfilePicture, updateProfile } from "../../services/profileService";
import ChatPasswordSettingsModal from "./ChatPasswordSettingsModal";

function MyProfilePanel({ user, onClose }) {
  const [uploading, setUploading] = useState(false);
  const [showPasswordSettings, setShowPasswordSettings] = useState(false);
  const fileInputRef = useRef(null);
  const { setUser } = useAuth();
  const [profile, setProfile] = useState(user);
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({
    name: user.name,
    bio: user.bio || "",
    status: user.status || "Available",
  });

  const handleSave = async () => {
    try {
      const updated = await updateProfile(form);
      setProfile(updated);
      setUser(updated);
      setEditing(false);
    } catch (err) {
      console.error(err);
      alert("Failed to update profile");
    }
  };

  const handleImageChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploading(true);
    try {
      const updatedUser = await uploadProfilePicture(file);
      setProfile(updatedUser);
      setUser(updatedUser);
    } catch (err) {
      console.error(err);
      alert("Upload failed");
    } finally {
      setUploading(false);
    }
  };

  const handleRemoveProfilePicture = async () => {
    try {
      const updatedUser = await updateProfile({ profilePic: "" });
      setProfile(updatedUser);
      setUser(updatedUser);
    } catch (err) {
      console.error(err);
      alert("Failed to remove profile picture");
    }
  };

  if (!user) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex justify-end animate-fadeIn">
      
      <div className="w-full md:w-96 h-full bg-white shadow-2xl overflow-y-auto flex flex-col animate-slideInRight">

        {/* ================= HEADER ================= */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
          <h2 className="text-xl font-bold text-[#2C2C2C] tracking-tight">
            My Profile
          </h2>

          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-gray-100 text-[#2C2C2C] hover:text-red-500 transition-colors text-2xl"
          >
            <FiX />
          </button>
        </div>

        {/* ================= AVATAR SECTION ================= */}
        <div className="flex justify-center mt-8">
          <div className="relative">
            
            {/* Avatar Container */}
            <div
              onClick={() => !uploading && fileInputRef.current.click()}
              className="group relative w-28 h-28 rounded-full overflow-hidden cursor-pointer border-4 border-white shadow-lg shadow-orange-100"
            >
              {uploading ? (
                <div className="absolute inset-0 bg-white/90 flex flex-col items-center justify-center z-20">
                  <div className="w-10 h-10 border-4 border-[#FF7A00] border-t-transparent rounded-full animate-spin"></div>
                  <p className="text-[#2C2C2C] text-xs mt-3 font-medium">Uploading...</p>
                </div>
              ) : profile.profilePic ? (
                <img
                  src={`${profile.profilePic}?t=${Date.now()}`}
                  alt="Profile"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full bg-[#FF7A00] flex items-center justify-center text-5xl font-bold text-white">
                  {profile.name.charAt(0).toUpperCase()}
                </div>
              )}

              {/* Camera Hover Overlay */}
              <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-all duration-300 flex items-center justify-center">
                <FiCamera className="text-white text-3xl opacity-0 group-hover:opacity-100 transition-all duration-300 drop-shadow-lg" />
              </div>
            </div>

            {/* Delete Picture Button */}
            {profile.profilePic && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  handleRemoveProfilePicture();
                }}
                className="absolute bottom-0 right-0 z-30 w-9 h-9 rounded-full bg-red-500 hover:bg-red-600 flex items-center justify-center shadow-lg border-2 border-white transition-colors"
                title="Remove profile picture"
              >
                <FiTrash2 className="text-white text-sm" />
              </button>
            )}

            <input
              type="file"
              ref={fileInputRef}
              hidden
              accept="image/*"
              onChange={handleImageChange}
            />
          </div>
        </div>

        {/* ================= NAME & EMAIL ================= */}
        <div className="text-center mt-5 px-6">
          {editing ? (
            <input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="bg-[#f8f9fa] text-[#2C2C2C] rounded-xl px-4 py-2 text-center w-full border border-gray-200 outline-none focus:border-[#FF7A00] transition"
              placeholder="Your name"
            />
          ) : (
            <h2 className="text-2xl font-bold text-[#2C2C2C]">
              {profile.name}
            </h2>
          )}

          <p className="text-gray-500 text-sm font-medium mt-1">
            {profile.email}
          </p>
        </div>

        {/* ================= ABOUT SECTION ================= */}
        <div className="px-6 mt-8">
          <h4 className="text-[#FF7A00] font-semibold text-xs uppercase tracking-wider mb-2">
            About
          </h4>

          {editing ? (
            <textarea
              value={form.bio}
              onChange={(e) => setForm({ ...form, bio: e.target.value })}
              className="w-full bg-[#f8f9fa] rounded-xl p-4 text-[#2C2C2C] border border-gray-200 outline-none focus:border-[#FF7A00] transition resize-none"
              rows={3}
              placeholder="Tell us about yourself..."
            />
          ) : (
            <div className="bg-[#f8f9fa] rounded-xl p-4 text-[#2C2C2C] leading-relaxed border border-gray-100 text-sm">
              {profile.bio || "Hey there! I'm using ReSender 💬"}
            </div>
          )}
        </div>

        {/* ================= ACTION BUTTONS ================= */}
        <div className="px-6 mt-8 flex gap-3">
          {editing ? (
            <>
              <button
                onClick={handleSave}
                className="flex-1 bg-[#FF7A00] hover:bg-[#E66E00] text-white font-semibold py-3 rounded-xl shadow-md shadow-orange-200 transition-colors"
              >
                Save Changes
              </button>

              <button
                onClick={() => setEditing(false)}
                className="flex-1 bg-gray-100 hover:bg-gray-200 text-[#2C2C2C] font-semibold py-3 rounded-xl transition-colors"
              >
                Cancel
              </button>
            </>
          ) : (
            <button
              onClick={() => setEditing(true)}
              className="w-full bg-[#f8f9fa] hover:bg-gray-200 text-[#2C2C2C] font-medium py-3 rounded-xl border border-gray-200 transition-colors flex items-center justify-center gap-2"
            >
              <FiEdit2 className="text-gray-500" /> Edit Profile
            </button>
          )}
        </div>

        {/* ================= JOINED SECTION ================= */}
        <div className="px-6 mt-6 pb-6">
          <h4 className="text-[#FF7A00] font-semibold text-xs uppercase tracking-wider mb-2">
            Member Since
          </h4>

          <div className="bg-[#f8f9fa] rounded-xl p-4 text-[#2C2C2C] text-sm border border-gray-100 font-medium">
            {profile.createdAt
              ? new Date(profile.createdAt).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })
              : "Unknown"}
          </div>
        </div>

        {/* ================= CHAT PASSWORD ================= */}

            <div className="px-6 pb-8">

            <h4 className="text-[#FF7A00] font-semibold text-xs uppercase tracking-wider mb-2">
                Chat Password
            </h4>

            <div className="bg-[#f8f9fa] rounded-xl p-4 border border-gray-100">

                <button
                onClick={() => setShowPasswordSettings(true)}
                className="w-full bg-[#FF7A00] hover:bg-[#E66E00] text-white py-3 rounded-xl font-semibold transition"
                >
                Manage Chat Password
                </button>

            </div>

            </div>

            {showPasswordSettings && (
                <ChatPasswordSettingsModal
                    onClose={() => setShowPasswordSettings(false)}
                />
                )}

      </div>
    </div>
    
  );
}

export default MyProfilePanel;