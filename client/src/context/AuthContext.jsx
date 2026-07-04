import { createContext, useContext, useState, useEffect } from "react";
import socket from "../services/socket";


const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(
    JSON.parse(localStorage.getItem("user")) || null
  );

  useEffect(() => {
  if (user) {
    socket.connect();
    socket.emit("registerUser", user.id);
  }
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