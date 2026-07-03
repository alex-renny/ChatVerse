import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";

function Chat() {
  return (
    <div className="h-screen bg-slate-950 flex overflow-hidden">

      <Sidebar />

      <ChatWindow />

    </div>
  );
}

export default Chat;