import { useState, useRef, useEffect } from "react";
import { FiMic, FiX, FiSend } from "react-icons/fi";

function formatTime(seconds) {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

function getSupportedMimeType() {
  const types = ["audio/webm;codecs=opus", "audio/webm", "audio/mp4", "audio/ogg;codecs=opus"];
  for (const type of types) {
    if (MediaRecorder.isTypeSupported(type)) return type;
  }
  return "";
}

function VoiceRecorder({ onRecorded, onCancel, onRecordingChange, disabled }) {
  const [recording, setRecording] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  const streamRef = useRef(null);
  const timerRef = useRef(null);

  useEffect(() => {
    return () => {
      clearInterval(timerRef.current);
      streamRef.current?.getTracks().forEach((t) => t.stop());
    };
  }, []);

  const startRecording = async () => {
    if (disabled) return;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      chunksRef.current = [];

      const mimeType = getSupportedMimeType();
      const options = mimeType ? { mimeType } : {};
      const recorder = new MediaRecorder(stream, options);
      mediaRecorderRef.current = recorder;

      recorder.ondataavailable = (e) => {
        if (e.data && e.data.size > 0) chunksRef.current.push(e.data);
      };

      recorder.onstop = () => {
        clearInterval(timerRef.current);
        const type = mimeType || "audio/webm";
        const blob = new Blob(chunksRef.current, { type });
        const ext = type.includes("mp4") ? "m4a" : "webm";
        const file = new File([blob], `voice-${Date.now()}.${ext}`, { type });
        stream.getTracks().forEach((t) => t.stop());
        onRecorded(file, elapsed);
        setRecording(false);
        onRecordingChange?.(false);
        setElapsed(0);
      };

      recorder.start(100);
      setRecording(true);
      onRecordingChange?.(true);
      setElapsed(0);
      timerRef.current = setInterval(() => setElapsed((s) => s + 1), 1000);
    } catch {
      alert("Could not access microphone. Please allow microphone access and try again.");
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current?.state === "recording") {
      mediaRecorderRef.current.stop();
    }
  };

  const cancelRecording = () => {
    clearInterval(timerRef.current);
    if (mediaRecorderRef.current?.state === "recording") {
      mediaRecorderRef.current.onstop = null;
      mediaRecorderRef.current.stop();
    }
    streamRef.current?.getTracks().forEach((t) => t.stop());
    chunksRef.current = [];
    setRecording(false);
    onRecordingChange?.(false);
    setElapsed(0);
    onCancel?.();
  };

  if (!recording) {
    return (
      <button
        onClick={startRecording}
        disabled={disabled}
        className="text-gray-400 hover:text-[#FF7A00] transition text-2xl p-1 flex-shrink-0 disabled:opacity-40"
      >
        <FiMic />
      </button>
    );
  }

  return (
    <div className="flex items-center gap-3 flex-1 min-w-0 animate-fadeIn">
      <button
        onClick={cancelRecording}
        className="text-gray-400 hover:text-red-500 transition text-xl p-1 flex-shrink-0"
      >
        <FiX />
      </button>

      <div className="flex items-center gap-2 flex-1 min-w-0 bg-red-50 rounded-full px-4 py-2.5 border border-red-100">
        <span className="w-2.5 h-2.5 bg-red-500 rounded-full recording-pulse flex-shrink-0" />
        <span className="text-red-500 text-sm font-medium flex-shrink-0">{formatTime(elapsed)}</span>
        <div className="flex items-center gap-[3px] flex-1 justify-center h-6 overflow-hidden">
          {[...Array(24)].map((_, i) => (
            <div
              key={i}
              className="recording-bar w-[3px] bg-red-400 rounded-full"
              style={{ animationDelay: `${i * 0.07}s` }}
            />
          ))}
        </div>
      </div>

      <button
        onClick={stopRecording}
        className="bg-[#FF7A00] hover:bg-[#E66E00] rounded-full p-3 text-white shadow-md transition flex-shrink-0"
      >
        <FiSend />
      </button>
    </div>
  );
}

export default VoiceRecorder;
