import { FiX } from "react-icons/fi";
import { uploadProfilePicture } from "../../services/profileService";
import { useState, useRef } from "react";

function MyProfilePanel({ user, onClose }) {

    const fileInputRef = useRef(null);
    const [profile, setProfile] = useState(user);
    const handleImageChange = async (e) => {
    const file = e.target.files[0];

    if (!file) return;

    try {
        const updatedUser = await uploadProfilePicture(file);

        setProfile(updatedUser);

        localStorage.setItem(
        "user",
        JSON.stringify(updatedUser)
        );

    } catch (err) {
        console.error(err);
        alert("Upload failed");
    }
    };

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
        <div className="flex justify-center mt-8">
            <div
                onClick={() => fileInputRef.current.click()}
                className="w-32 h-32 rounded-full bg-blue-600 flex items-center justify-center text-5xl font-bold text-white cursor-pointer hover:scale-105 transition overflow-hidden"
            >
                {profile.profilePic ? (
                <img
                    src={`http://localhost:5000${profile.profilePic}?t=${Date.now()}`}
                    alt="Profile"
                    className="w-full h-full object-cover"
                />
                ) : (
                profile.name?.charAt(0).toUpperCase()
                )}
            </div>

            <input
                type="file"
                ref={fileInputRef}
                hidden
                accept="image/*"
                onChange={handleImageChange}
            />
        </div>
        {/* About */}
        <div className="px-6 mt-8">
          <h4 className="text-blue-400 font-semibold mb-2">
            About
          </h4>

          <div className="bg-slate-800 rounded-xl p-4 text-slate-300">
            {profile.bio || "Hey there! I'm using ChatVerse 💬"}
          </div>
        </div>

        {/* Joined */}
        <div className="px-6 mt-6">
          <h4 className="text-blue-400 font-semibold mb-2">
            Joined
          </h4>

          <div className="bg-slate-800 rounded-xl p-4 text-slate-300">
            {profile.createdAt
              ? new Date(profile.createdAt).toLocaleDateString()
              : "Unknown"}
          </div>
        </div>

      </div>
    </div>
  );
}

export default MyProfilePanel;