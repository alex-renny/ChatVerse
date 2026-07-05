import { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";

function Chat() {
  const [selectedUser, setSelectedUser] = useState(null);
  const [showChat, setShowChat] = useState(false);

  return (
    <div className="h-screen flex bg-slate-950 overflow-hidden">
      <Sidebar
        setSelectedUser={setSelectedUser}
        showChat={showChat}
        setShowChat={setShowChat}
      />

      <ChatWindow
        selectedUser={selectedUser}
        showChat={showChat}
        setShowChat={setShowChat}
      />
    </div>
  );
}

export default Chat;