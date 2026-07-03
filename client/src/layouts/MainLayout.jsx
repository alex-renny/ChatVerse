import Navbar from "../components/layout/Navbar";

function MainLayout({ children }) {
  return (
    <div className="h-screen flex flex-col bg-slate-900">
      <Navbar />
      <main className="flex-1 overflow-hidden">
        {children}
      </main>
    </div>
  );
}

export default MainLayout;