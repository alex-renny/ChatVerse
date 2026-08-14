const localHosts = new Set(["localhost", "127.0.0.1", "::1"]);
const isLocalApp = localHosts.has(window.location.hostname);

// Use the local API whenever the UI itself is opened locally, including a
// Vite preview build. Deployed clients keep using the production API URL.
export const API_ORIGIN = isLocalApp
  ? "http://localhost:5000"
  : import.meta.env.VITE_API_URL;

