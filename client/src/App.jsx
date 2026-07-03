import { useEffect, useState } from "react";
import api from "./api/axios";

function App() {
  const [message, setMessage] = useState("");

  useEffect(() => {
    const fetchMessage = async () => {
      try {
        const response = await api.get("/");
        setMessage(response.data.message);
      } catch (error) {
        console.error(error);
      }
    };

    fetchMessage();
  }, []);

  return (
    <div style={{ padding: "40px", fontFamily: "Arial" }}>
      <h1>ChatVerse</h1>

      <h2>Backend Response:</h2>

      <p>{message}</p>
    </div>
  );
}

export default App;