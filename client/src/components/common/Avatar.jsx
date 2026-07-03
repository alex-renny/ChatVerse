function Avatar({ src, alt, online = false }) {
  return (
    <div className="relative">
      <img
        src={src}
        alt={alt}
        className="w-12 h-12 rounded-full object-cover"
      />

      {online && (
        <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-green-500 border-2 border-slate-800"></span>
      )}
    </div>
  );
}

export default Avatar;