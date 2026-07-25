import { motion } from "framer-motion";

function MessageBubble({
  children,
  messageRef,
  selectionMode,
  toggleMessageSelection,
  msg,
  isMine,
  matched,
  handleReaction,
  onContextMenu,
  onReply,
}) {
  return (
    <motion.div
      ref={messageRef}
      drag="x"
      dragConstraints={{ left: 0, right: 120 }}
      dragElastic={0.15}
      dragSnapToOrigin
      transition={{
        type: "spring",
        stiffness: 500,
        damping: 30,
      }}
      onDragEnd={(event, info) => {
        // Swipe right to reply (orange theme friendly)
        if (info.offset.x > 80) {
          onReply(msg);
        }
      }}
      onClick={() => {
        if (selectionMode) {
          toggleMessageSelection(msg._id);
        }
      }}
      onDoubleClick={() => handleReaction(msg._id, "❤️")}
      onContextMenu={(e) => {
        e.preventDefault();
        onContextMenu(e, msg);
      }}
      className={`flex items-end gap-2 mb-1.5 w-full max-w-full transition-all duration-300 ${
        isMine ? "justify-end" : "justify-start"
      } ${
        matched ? "bg-yellow-200/50 rounded-xl ring-2 ring-yellow-400 px-2 py-1" : ""
      }`}
    >
      {/* 
        The children prop contains the actual message bubble UI. 
        You can style it directly inside ChatWindow (which we already upgraded).
      */}
      {children}
    </motion.div>
  );
}

export default MessageBubble;