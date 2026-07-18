function Navbar() {
  return (
    <header className="h-16 bg-slate-800 border-b border-slate-700 flex items-center justify-between px-6 shadow-lg">
      <div>
        <h1 className="text-2xl font-bold text-emerald-400">
          ReSender
        </h1>
      </div>

      <div className="flex items-center gap-6">
        <button className="text-2xl hover:scale-110 transition">
          🔔
        </button>

        <button className="text-2xl hover:scale-110 transition">
          ⚙️
        </button>

        <div className="flex items-center gap-2">
          <img
            src="https://img.magnific.com/free-vector/blue-circle-with-white-user_78370-4707.jpg?semt=ais_hybrid&w=740&q=80"
            alt="Profile"
            className="w-10 h-10 rounded-full"
          />

          <span className="text-white font-medium">
            Alex
          </span>
        </div>
      </div>
    </header>
  );
}

export default Navbar;