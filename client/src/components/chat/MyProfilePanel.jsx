import { FiX } from "react-icons/fi";
import { useState, useRef } from "react";
import {uploadProfilePicture,updateProfile,} from "../../services/profileService";

function MyProfilePanel({ user, onClose }) {

    const fileInputRef = useRef(null);
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

                localStorage.setItem(
                "user",
                JSON.stringify(updated)
                );

                setEditing(false);

            } catch (err) {
                console.error(err);
                alert("Failed to update profile");
            }
            };
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
        <div className="text-center mt-5">

            {editing ? (
                <input
                value={form.name}
                onChange={(e) =>
                    setForm({
                    ...form,
                    name: e.target.value,
                    })
                }
                className="bg-slate-800 text-white rounded-lg px-4 py-2 text-center w-64"
                />
            ) : (
                <h2 className="text-2xl font-bold text-white">
                {profile.name}
                </h2>
            )}

            <p className="text-slate-400 mt-2">
                {profile.email}
            </p>

        </div>
        {/* About */}
        <div className="px-6 mt-8">
          <h4 className="text-blue-400 font-semibold mb-2">
            About
          </h4>

          {editing ? (
            <textarea
                value={form.bio}
                onChange={(e) =>
                setForm({
                    ...form,
                    bio: e.target.value,
                })
                }
                className="w-full bg-slate-800 rounded-xl p-4 text-white"
                rows={3}
            />
            ) : (
            <div className="bg-slate-800 rounded-xl p-4 text-slate-300">
                {profile.bio || "Hey there! I'm using ChatVerse 💬"}
            </div>
            )}
        </div>

        <div className="px-6 mt-8 flex gap-3">

            {editing ? (
                <>
                <button
                    onClick={handleSave}
                    className="flex-1 bg-green-600 hover:bg-green-700 text-white py-3 rounded-xl"
                >
                    Save
                </button>

                <button
                    onClick={() => setEditing(false)}
                    className="flex-1 bg-red-600 hover:bg-red-700 text-white py-3 rounded-xl"
                >
                    Cancel
                </button>
                </>
            ) : (
                <button
                onClick={() => setEditing(true)}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-xl"
                >
                Edit Profile
                </button>
            )}

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