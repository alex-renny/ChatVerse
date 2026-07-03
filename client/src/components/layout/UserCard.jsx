function UserCard({ name, message, online }) {
  return (
    <div className="flex items-center gap-4 p-4 hover:bg-slate-800 cursor-pointer transition">

      <div className="relative">

        <div className="w-12 h-12 rounded-full bg-emerald-500 flex items-center justify-center text-white font-bold text-lg">
          {name.charAt(0)}
        </div>

        {online && (
          <div className="absolute bottom-0 right-0 w-3 h-3 rounded-full bg-green-500 border-2 border-slate-900"></div>
        )}

      </div>

      <div className="overflow-hidden">

        <h3 className="text-white font-semibold">
          {name}
        </h3>

        <p className="text-slate-400 text-sm truncate w-48">
          {message}
        </p>

      </div>

    </div>
  );
}

export default UserCard;