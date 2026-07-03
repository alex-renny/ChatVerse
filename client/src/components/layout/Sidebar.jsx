function Sidebar() {
  return (
    <aside className="w-80 bg-slate-800 border-r border-slate-700 p-4">
      <input
        type="text"
        placeholder="Search users..."
        className="w-full p-3 rounded-lg bg-slate-700 text-white outline-none"
      />

      <div className="mt-6 space-y-3">
        <div className="p-3 rounded-lg bg-slate-700 cursor-pointer">
          <h2 className="text-white font-semibold">
            John
          </h2>

          <p className="text-slate-400 text-sm">
            Last message...
          </p>
        </div>

        <div className="p-3 rounded-lg bg-slate-700 cursor-pointer">
          <h2 className="text-white font-semibold">
            Sarah
          </h2>

          <p className="text-slate-400 text-sm">
            Last message...
          </p>
        </div>

        <div className="p-3 rounded-lg bg-slate-700 cursor-pointer">
          <h2 className="text-white font-semibold">
            David
          </h2>

          <p className="text-slate-400 text-sm">
            Last message...
          </p>
        </div>
      </div>
    </aside>
  );
}

export default Sidebar;