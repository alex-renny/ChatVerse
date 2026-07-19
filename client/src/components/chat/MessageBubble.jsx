import { motion } from "framer-motion";

function MessageBubble({
  children,
  messageRef,
  selectionMode,
  toggleMessageSelection,
  msg,
  isMine,
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
      className={`flex items-center gap-3 mb-1 ${
        isMine ? "justify-end" : "justify-start"
      }`}
    >
      {children}
    </motion.div>
  );
}

export default MessageBubble;