import { useState } from "react";
import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";

function Chat() {
    const [selectedUser, setSelectedUser] = useState(null);
  return (
    <div className="h-screen bg-slate-950 flex overflow-hidden">

      <Sidebar setSelectedUser={setSelectedUser} />

      <ChatWindow selectedUser={selectedUser} />

    </div>
  );
}

export default Chat;