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

    const userId = user._id || user.id;
    const registerUser = () => {
      if (!userId) return;
      socket.emit("registerUser", userId);
    };

    // Register after every connection (including automatic reconnects). If
    // hot reload leaves an existing socket open, register immediately too.
    socket.on("connect", registerUser);
    socket.connect();
    if (socket.connected) registerUser();

    return () => socket.off("connect", registerUser);
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
