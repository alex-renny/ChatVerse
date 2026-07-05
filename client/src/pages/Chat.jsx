import { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";

function Chat() {
  const [selectedUser, setSelectedUser] = useState(null);

  return (
    <div className="flex h-screen bg-slate-950 overflow-hidden">

      {/* Sidebar */}
      <div className={`${selectedUser ? "hidden md:block" : "block"} w-full md:w-80`}>
        <Sidebar setSelectedUser={setSelectedUser} />
      </div>

      {/* Chat */}
      <div className={`${selectedUser ? "flex" : "hidden md:flex"} flex-1`}>
        <ChatWindow
          selectedUser={selectedUser}
          setSelectedUser={setSelectedUser}
        />
      </div>

    </div>
  );
}

export default Chat;