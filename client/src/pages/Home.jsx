import Sidebar from "../components/layout/Sidebar";
import ChatWindow from "../components/layout/ChatWindow";
import MainLayout from "../layouts/MainLayout";

function Home() {
  return (
    <MainLayout>
      <div className="flex h-full">
        <Sidebar />
        <ChatWindow />
      </div>
    </MainLayout>
  );
}

export default Home;