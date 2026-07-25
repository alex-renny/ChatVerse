import { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";

function Chat() {
  // Default to null, or pass a default user ID if you want a default chat open
  const [selectedUser, setSelectedUser] = useState(null);

  return (
    <div className="flex h-screen bg-[#f8f9fa] overflow-hidden font-sans">
      
      {/* ================= SIDEBAR ================= */}
      <div 
        className={`
          ${selectedUser ? "hidden md:block" : "block"} 
          w-full md:w-80 
          bg-white 
          border-r border-gray-200 
          h-full flex-shrink-0
        `}
      >
        {/* 
           NOTE: Update your Sidebar component to use the new theme colors. 
           Pass the setSelectedUser function down just like before.
        */}
        <Sidebar 
          setSelectedUser={setSelectedUser} 
          selectedUserId={selectedUser?.id || null} // If your user objects have IDs
        />
      </div>

      {/* ================= CHAT WINDOW ================= */}
      <div 
        className={`
          ${selectedUser ? "flex" : "hidden md:flex"} 
          flex-1 
          h-full 
          bg-white 
          relative
        `}
      >
        {/* 
           NOTE: Update your ChatWindow component to use the new theme colors.
           Pass the selectedUser state to it.
        */}
        <ChatWindow
          selectedUser={selectedUser}
          setSelectedUser={setSelectedUser}
        />
      </div>

    </div>
  );
}

export default Chat;