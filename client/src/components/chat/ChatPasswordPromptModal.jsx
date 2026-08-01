import { useState } from "react";
import { FiLock, FiX } from "react-icons/fi";

function ChatPasswordPromptModal({ user, onClose, onSubmit }) {
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!password.trim()) {
      setError("Please enter the password.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      await onSubmit(password);
    } catch (err) {
      setError(err.response?.data?.message || "Wrong password");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[999]">
      <div className="bg-white rounded-2xl p-6 w-[400px] shadow-xl">
        <div className="flex justify-between items-start mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center">
              <FiLock className="text-[#FF7A00] text-lg" />
            </div>
            <div>
              <h2 className="font-bold text-xl text-[#2C2C2C]">Private Chat</h2>
              <p className="text-sm text-gray-500 mt-0.5">
                {user?.name} has protected their chats
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

        <p className="text-gray-600 text-sm mb-4">
          Enter the chat password to send your first message.
        </p>

        <form onSubmit={handleSubmit}>
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => {
              setPassword(e.target.value);
              setError("");
            }}
            className="w-full border border-gray-200 rounded-xl p-3 mb-2 outline-none focus:border-[#FF7A00] focus:ring-2 focus:ring-[#FF7A00]/20"
            autoFocus
          />

          {error && (
            <p className="text-red-500 text-sm mb-3">{error}</p>
          )}

          <div className="flex gap-3 mt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 bg-gray-100 hover:bg-gray-200 text-[#2C2C2C] py-3 rounded-xl font-medium transition-colors"
            >
              Cancel
            </button>

            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-[#FF7A00] hover:bg-[#E66E00] disabled:opacity-60 text-white py-3 rounded-xl font-semibold transition-colors"
            >
              {loading ? "Verifying..." : "Continue"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default ChatPasswordPromptModal;
