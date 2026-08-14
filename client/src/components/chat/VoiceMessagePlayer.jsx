import { useState, useRef, useEffect } from "react";
import { FiPlay, FiPause } from "react-icons/fi";

function formatTime(seconds) {
  if (!seconds || isNaN(seconds)) return "0:00";
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}

function VoiceMessagePlayer({ src, isMine }) {
  const audioRef = useRef(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const onTimeUpdate = () => {
      if (audio.duration) setProgress(audio.currentTime / audio.duration);
      setCurrentTime(audio.currentTime);
    };
    const onLoaded = () => setDuration(audio.duration);
    const onEnded = () => { setPlaying(false); setProgress(0); setCurrentTime(0); };

    audio.addEventListener("timeupdate", onTimeUpdate);
    audio.addEventListener("loadedmetadata", onLoaded);
    audio.addEventListener("ended", onEnded);
    return () => {
      audio.removeEventListener("timeupdate", onTimeUpdate);
      audio.removeEventListener("loadedmetadata", onLoaded);
      audio.removeEventListener("ended", onEnded);
    };
  }, [src]);

  const togglePlay = () => {
    const audio = audioRef.current;
    if (!audio) return;
    if (playing) {
      audio.pause();
    } else {
      audio.play();
    }
    setPlaying(!playing);
  };

  const handleSeek = (e) => {
    const audio = audioRef.current;
    if (!audio || !audio.duration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const ratio = (e.clientX - rect.left) / rect.width;
    audio.currentTime = ratio * audio.duration;
    setProgress(ratio);
    setCurrentTime(audio.currentTime);
  };

  return (
    <div className={`flex items-center gap-2 min-w-[180px] max-w-[240px] ${isMine ? "" : ""}`}>
      <audio ref={audioRef} src={src} preload="metadata" />
      <button
        onClick={togglePlay}
        className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 transition
          ${isMine ? "bg-white/25 hover:bg-white/35 text-white" : "bg-[#FF7A00]/10 hover:bg-[#FF7A00]/20 text-[#FF7A00]"}`}
      >
        {playing ? <FiPause className="text-sm" /> : <FiPlay className="text-sm ml-0.5" />}
      </button>
      <div className="flex-1 flex flex-col gap-1">
        <div
          onClick={handleSeek}
          className="h-1.5 rounded-full cursor-pointer relative overflow-hidden
            bg-black/10"
        >
          <div
            className={`h-full rounded-full transition-all duration-100
              ${isMine ? "bg-white/80" : "bg-[#FF7A00]"}`}
            style={{ width: `${progress * 100}%` }}
          />
        </div>
        <div className="flex items-center gap-0.5 h-4">
          {[...Array(20)].map((_, i) => (
            <div
              key={i}
              className={`voice-bar w-[2px] rounded-full
                ${isMine ? "bg-white/50" : "bg-[#FF7A00]/40"}
                ${playing ? "voice-bar-active" : ""}`}
              style={{ animationDelay: `${i * 0.05}s`, height: `${30 + Math.sin(i * 0.8) * 50}%` }}
            />
          ))}
        </div>
      </div>
      <span className={`text-[10px] flex-shrink-0 ${isMine ? "text-white/70" : "text-gray-400"}`}>
        {formatTime(playing ? currentTime : duration)}
      </span>
    </div>
  );
}

export default VoiceMessagePlayer;
