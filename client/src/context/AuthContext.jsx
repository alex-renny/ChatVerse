import { createContext, useContext, useState, useEffect } from "react";
import socket from "../services/socket";

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(
    JSON.parse(localStorage.getItem("user")) || null
  );

  const login = (userData, token) => {
    setUser(userData);

    localStorage.setItem("user", JSON.stringify(userData));
    localStorage.setItem("token", token);
  };

  const logout = () => {
    setUser(null);

    localStorage.removeItem("user");
    localStorage.removeItem("token");
  };
  
  useEffect(() => {
  if (user) {
    if (!socket.connected) {
      socket.connect();
    }

    socket.emit("join", user.id);
  }

  return () => {
    if (socket.connected) {
      socket.disconnect();
    }
  };
}, [user]);

  return (
    <AuthContext.Provider
      value={{
        user,
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