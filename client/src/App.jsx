import { BrowserRouter, Navigate, Routes, Route ,useLocation} from "react-router-dom";

import Login from "./pages/Login";
import Register from "./pages/Register";
import Chat from "./pages/Chat";
import { useAuth } from "./context/AuthContext";
import { useState } from "react";
import IntroScreen from "./components/IntroScreen";

function ProtectedRoute({ children }) {
  const { user } = useAuth();

  return user ? children : <Navigate to="/" replace />;
}
function AppRoutes() {
  const { user } = useAuth();
  const location = useLocation();
  const [showIntro, setShowIntro] = useState(
    location.pathname === "/" || location.pathname === "/register"
  );

  if (showIntro && (location.pathname === "/" || location.pathname === "/register")) {
    return (
      <IntroScreen
        onFinish={() => setShowIntro(false)}
      />
    );
  }

  return (
    <Routes>
      <Route path="/" element={<Login />} />
      <Route path="/register" element={<Register />} />

      <Route
        path="/chat"
        element={
          <ProtectedRoute>
            <Chat />
          </ProtectedRoute>
        }
      />
    </Routes>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  );
}


export default App;
