import { createContext, useContext, useState, useEffect } from "react";
import socket from "../services/socket";


const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(
    JSON.parse(localStorage.getItem("user")) || null
  );

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
  setUser(userData);

  localStorage.setItem("user", JSON.stringify(userData));
  localStorage.setItem("token", token);

};

  const logout = () => {
  socket.disconnect();

  setUser(null);

  localStorage.removeItem("user");
  localStorage.removeItem("token");
};

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