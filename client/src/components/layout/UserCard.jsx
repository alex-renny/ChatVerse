function UserCard({ user, onSelect, online }) {
  return (
    <div
      onClick={() => {
  console.log("Clicked:", user);
  onSelect(user);
}}  
      className="cursor-pointer hover:bg-slate-800 p-4 border-b border-slate-800"
    >
      <div className="flex items-center justify-between">
        <h3 className="text-white font-medium">
          {user.name}
        </h3>

        <div
          className={`w-3 h-3 rounded-full ${
            online ? "bg-green-500" : "bg-gray-500"
          }`}
        />
      </div>

      <p className="text-slate-400 text-sm mt-1">
        {user.bio || "Start a conversation"}
      </p>
    </div>
  );
}

export default UserCard;