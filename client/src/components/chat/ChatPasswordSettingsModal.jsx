import { useEffect, useState } from "react";
import { FiLock, FiTrash2, FiX } from "react-icons/fi";
import {
  getChatPasswordStatus,
  removeVerifiedUserAccess,
  setChatPassword,
  removeChatPassword,
} from "../../services/profileService";

function ChatPasswordSettingsModal({ onClose }) {
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [statusLoading, setStatusLoading] = useState(true);
  const [enabled, setEnabled] = useState(false);
  const [accessCount, setAccessCount] = useState(0);
  const [verifiedUsers, setVerifiedUsers] = useState([]);

  useEffect(() => {
    const loadStatus = async () => {
      try {
        const data = await getChatPasswordStatus();
        setEnabled(data.enabled);
        setAccessCount(data.accessCount);
        setVerifiedUsers(data.verifiedUsers || []);
      } catch (err) {
        console.error(err);
      } finally {
        setStatusLoading(false);
      }
    };

    loadStatus();
  }, []);

  const handleSave = async () => {
    if (password.length < 4) {
      alert("Password should be at least 4 characters.");
      return;
    }

    setLoading(true);

    try {
      await setChatPassword(password);
      setEnabled(true);
      setPassword("");
      alert(enabled ? "Chat password updated." : "Chat password saved.");
    } catch (err) {
      console.error(err);
      alert("Failed to save password.");
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = async () => {
    if (!window.confirm("Remove your chat password? Everyone will be able to chat with you.")) {
      return;
    }

    setLoading(true);

    try {
      await removeChatPassword();
      setEnabled(false);
      setAccessCount(0);
      setVerifiedUsers([]);
      alert("Password removed.");
      onClose();
    } catch (err) {
      console.error(err);
      alert("Failed to remove password.");
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveAccess = async (userId) => {
    if (!window.confirm("Remove this person's access to your chats?")) {
      return;
    }

    try {
      const data = await removeVerifiedUserAccess(userId);
      setVerifiedUsers((prev) => prev.filter((u) => u._id !== userId));
      setAccessCount(data.accessCount);
    } catch (err) {
      console.error(err);
      alert("Failed to remove access.");
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[999]">
      <div className="bg-white rounded-2xl p-6 w-[440px] max-h-[85vh] overflow-y-auto shadow-xl">
        <div className="flex justify-between items-center mb-5">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center">
              <FiLock className="text-[#FF7A00] text-lg" />
            </div>
            <div>
              <h2 className="font-bold text-xl text-[#2C2C2C]">Chat Password</h2>
              <p className="text-sm text-gray-500">
                {enabled ? "Protection is active" : "No password set"}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-gray-100 text-gray-500"
          >
            <FiX size={22} />
          </button>
        </div>

        {statusLoading ? (
          <p className="text-gray-500 text-sm">Loading...</p>
        ) : (
          <>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {enabled ? "Change password" : "Set a password"}
            </label>

            <input
              type="password"
              placeholder="Enter new password (min 4 characters)"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full border border-gray-200 rounded-xl p-3 mb-4 outline-none focus:border-[#FF7A00] focus:ring-2 focus:ring-[#FF7A00]/20"
            />

            <button
              onClick={handleSave}
              disabled={loading}
              className="w-full bg-[#FF7A00] hover:bg-[#E66E00] disabled:opacity-60 text-white py-3 rounded-xl mb-3 font-semibold transition-colors"
            >
              {enabled ? "Update Password" : "Save Password"}
            </button>

            {enabled && (
              <button
                onClick={handleRemove}
                disabled={loading}
                className="w-full bg-red-500 hover:bg-red-600 disabled:opacity-60 text-white py-3 rounded-xl mb-6 font-semibold transition-colors"
              >
                Remove Password
              </button>
            )}

            {enabled && (
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-semibold text-[#2C2C2C]">
                    People with access
                  </h3>
                  <span className="text-sm text-gray-500">
                    {accessCount} {accessCount === 1 ? "person" : "people"}
                  </span>
                </div>

                {verifiedUsers.length === 0 ? (
                  <p className="text-sm text-gray-500 bg-[#f8f9fa] rounded-xl p-4 border border-gray-100">
                    No one has verified yet. They will appear here after entering your password.
                  </p>
                ) : (
                  <div className="space-y-2">
                    {verifiedUsers.map((verifiedUser) => (
                      <div
                        key={verifiedUser._id}
                        className="flex items-center justify-between bg-[#f8f9fa] rounded-xl p-3 border border-gray-100"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          {verifiedUser.profilePic ? (
                            <img
                              src={verifiedUser.profilePic}
                              alt={verifiedUser.name}
                              className="w-9 h-9 rounded-full object-cover"
                            />
                          ) : (
                            <div className="w-9 h-9 rounded-full bg-[#FF7A00] text-white flex items-center justify-center font-semibold">
                              {verifiedUser.name?.charAt(0).toUpperCase()}
                            </div>
                          )}

                          <div className="min-w-0">
                            <p className="font-medium text-[#2C2C2C] truncate">
                              {verifiedUser.name}
                            </p>
                            <p className="text-xs text-gray-500 truncate">
                              {verifiedUser.email}
                            </p>
                          </div>
                        </div>

                        <button
                          onClick={() => handleRemoveAccess(verifiedUser._id)}
                          className="p-2 text-red-500 hover:bg-red-50 rounded-full transition-colors"
                          title="Remove access"
                        >
                          <FiTrash2 size={16} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

export default ChatPasswordSettingsModal;
