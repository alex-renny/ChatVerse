import { useEffect } from "react";

function IntroScreen({ onFinish }) {
  return (
    <div className="fixed inset-0 bg-black flex items-center justify-center z-[9999]">
      <video
        src="/intro.mp4"
        autoPlay
        muted
        playsInline
        onEnded={onFinish}
        className="w-full h-full object-cover"
      />
    </div>
  );
}

export default IntroScreen;