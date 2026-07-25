import { useState } from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import { login as loginService } from "../services/authService";
import { useAuth } from "../context/AuthContext";
import socket from "../services/socket";

function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();

  const [form, setForm] = useState({
    email: "",
    password: "",
  });

  const handleChange = (e) => {
    setForm({
      ...form,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      const data = await loginService(form);
      login(data.user, data.token);
      navigate("/chat");
    } catch (error) {
      alert(error.response?.data?.message || "Login failed");
    }
  };

  return (
    <div className="min-h-screen bg-[#f8f9fa] flex items-center justify-center px-4 py-8">
      
      <div className="w-full max-w-md bg-white rounded-[2.5rem] shadow-[0_20px_60px_-15px_rgba(0,0,0,0.1)] p-10 relative overflow-hidden">
        
        {/* Decorative top curve matching the logo's swoosh */}
        <div className="absolute -top-16 -right-16 w-64 h-64 bg-[#FF7A00] rounded-full opacity-10 pointer-events-none"></div>
        <div className="absolute -top-10 -left-10 w-40 h-40 bg-[#2C2C2C] rounded-full opacity-5 pointer-events-none"></div>

        {/* Logo / Brand Header */}
        <div className="relative z-10 flex flex-col items-center text-center mb-10">
          <div className="w-16 h-16 bg-[#FF7A00] rounded-2xl flex items-center justify-center mb-4 shadow-lg shadow-orange-200">
            <img
              src="/WhatsApp Image 2026-07-18 at 8.34.27 PM-Photoroom.png"
              alt="Logo"
              className="w-20 h-20 object-contain"
            />
          </div>
          <h1 className="text-3xl font-bold text-[#2C2C2C] tracking-tight">
            ReSender
          </h1>
          <p className="text-gray-500 mt-1 text-sm font-medium tracking-wide">
            Welcome back to your inbox
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="relative z-10 space-y-6">
          
          <div>
            <label className="block text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 ml-1">
              Email Address
            </label>
            <input
              type="email"
              name="email"
              placeholder="you@example.com"
              value={form.email}
              onChange={handleChange}
              className="w-full p-4 rounded-xl bg-[#f8f9fa] text-[#2C2C2C] border border-gray-200 outline-none transition-all duration-200 focus:border-[#FF7A00] focus:ring-2 focus:ring-[#FF7A00]/20 placeholder:text-gray-400"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 ml-1">
              Password
            </label>
            <input
              type="password"
              name="password"
              placeholder="••••••••"
              value={form.password}
              onChange={handleChange}
              className="w-full p-4 rounded-xl bg-[#f8f9fa] text-[#2C2C2C] border border-gray-200 outline-none transition-all duration-200 focus:border-[#FF7A00] focus:ring-2 focus:ring-[#FF7A00]/20 placeholder:text-gray-400"
            />
          </div>

          <div className="flex items-center justify-end">
            <a href="#" className="text-sm text-[#FF7A00] hover:text-[#E66E00] font-medium transition-colors">
              Forgot password?
            </a>
          </div>

          <button
            type="submit"
            className="w-full bg-[#FF7A00] hover:bg-[#E66E00] transition duration-300 text-white font-semibold py-4 rounded-xl shadow-lg shadow-orange-200 hover:shadow-orange-300 transform active:scale-95"
          >
            Log In
          </button>

        </form>

        {/* Footer */}
        <div className="relative z-10 text-center mt-8 pt-6 border-t border-gray-100">
          <p className="text-gray-500 text-sm">
            Don't have an account?{" "}
            <Link
              to="/register"
              className="text-[#2C2C2C] font-bold hover:text-[#FF7A00] transition-colors border-b-2 border-transparent hover:border-[#FF7A00] pb-0.5"
            >
              Sign Up
            </Link>
          </p>
        </div>

      </div>
    </div>
  );
}

export default Login;