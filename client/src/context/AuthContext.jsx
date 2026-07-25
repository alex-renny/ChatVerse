import { createContext, useContext, useState, useEffect } from "react";
import socket from "../services/socket";
import {
  clearSession,
  getSessionUser,
  saveSession,
  saveSessionUser,
} from "../services/session";


const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUserState] = useState(getSessionUser);

  useEffect(() => {
  if (!user) return;

  console.log("Connecting socket...");
  socket.connect();

  socket.on("connect", () => {
    console.log("Socket connected:", socket.id);
    const userId = user._id || user.id;

    console.log("Registering user:", userId);

    socket.emit("registerUser", userId);
  });

  return () => {
    socket.off("connect");
  };
}, [user]);

  const login = (userData, token) => {
  setUserState(userData);
  saveSession(userData, token);

};

  // Profile updates must never be able to replace the active account.
  const setUser = (updatedUser) => {
    const currentId = user?._id || user?.id;
    const updatedId = updatedUser?._id || updatedUser?.id;

    if (currentId && updatedId && currentId !== updatedId) {
      console.warn("Ignored profile update for a different account");
      return;
    }

    setUserState(updatedUser);
    saveSessionUser(updatedUser);
  };

  const logout = () => {
  socket.disconnect();

  setUserState(null);
  clearSession();
};

  return (
    <AuthContext.Provider
      value={{
        user,
        setUser,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
