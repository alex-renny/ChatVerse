import {
  BrowserRouter,
  Navigate,
  Routes,
  Route,
  useLocation,
} from "react-router-dom";

import { useEffect, useState } from "react";

import Login from "./pages/Login";
import Register from "./pages/Register";
import Chat from "./pages/Chat";
import IntroScreen from "./components/IntroScreen";
import { useAuth } from "./context/AuthContext";

function ProtectedRoute({ children }) {
  const { user } = useAuth();

  return user ? children : <Navigate to="/" replace />;
}

function AppRoutes() {
  const { user } = useAuth();
  const location = useLocation();

  const isAuthPage =
    location.pathname === "/" ||
    location.pathname === "/register";

  const [showIntro, setShowIntro] = useState(false);

  useEffect(() => {
    if (
      isAuthPage &&
      sessionStorage.getItem("introPlayed") !== "true"
    ) {
      setShowIntro(true);
    } else {
      setShowIntro(false);
    }
  }, [location.pathname]);

  if (showIntro) {
    return (
      <IntroScreen
        onFinish={() => {
          sessionStorage.setItem("introPlayed", "true");
          setShowIntro(false);
        }}
      />
    );
  }

  return (
    <Routes>
      <Route path="/" element={<Login />} />

      <Route
        path="/register"
        element={<Register />}
      />

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