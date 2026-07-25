import { useState } from "react";
import { Link } from "react-router-dom";
import { useNavigate } from "react-router-dom";
import { register } from "../services/authService";

function Register() {
  const navigate = useNavigate();

  const [form, setForm] = useState({
    name: "",
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
      const data = await register(form);
      alert(data.message);
      navigate("/");
    } catch (error) {
      alert(error.response?.data?.message || "Registration failed");
    }
  };

  return (
    <div className="min-h-screen bg-white lg:bg-[#f8f9fa] flex items-center justify-center p-4 lg:p-8">
      
      {/* Main Split Container */}
      <div className="w-full max-w-6xl bg-white rounded-[2.5rem] lg:shadow-[0_20px_60px_-15px_rgba(0,0,0,0.08)] overflow-hidden flex flex-col lg:flex-row min-h-[600px]">
        
        {/* ================= LEFT SIDE: App Info & Logo ================= */}
        <div className="w-full lg:w-1/2 bg-gradient-to-br from-[#FF7A00] to-[#E66E00] p-8 lg:p-12 flex flex-col justify-center relative overflow-hidden">
          
          {/* Decorative swooshes matching your logo */}
          <div className="absolute -bottom-32 -right-32 w-96 h-96 bg-white/10 rounded-full pointer-events-none"></div>
          <div className="absolute -top-32 -left-32 w-96 h-96 bg-black/5 rounded-full pointer-events-none"></div>

          <div className="relative z-10 text-center lg:text-left lg:pl-8">
            
            {/* Custom CSS Chat Bubble Logo */}
            <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-md rounded-3xl mb-6 lg:mb-8 shadow-lg">
              <img
              src="/WhatsApp Image 2026-07-18 at 8.34.27 PM-Photoroom.png"
              alt="Logo"
              className="w-20 h-20 object-contain"
            />
            </div>

            <h1 className="text-4xl lg:text-5xl font-bold text-white tracking-tight mb-3">
              ReSender
            </h1>
            
            <p className="text-white/90 text-lg lg:text-xl font-light mb-6 leading-relaxed max-w-md mx-auto lg:mx-0">
              The modern messaging platform built for speed, simplicity, and secure conversations.
            </p>

            {/* Feature list */}
            <div className="space-y-3 text-white/80 text-sm lg:text-base max-w-sm mx-auto lg:mx-0">
              <div className="flex items-center space-x-3 bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full">
                <span className="text-white">⚡</span>
                <span>Lightning fast real-time messaging</span>
              </div>
              <div className="flex items-center space-x-3 bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full">
                <span className="text-white">🔒</span>
                <span>End-to-end encrypted conversations</span>
              </div>
              <div className="flex items-center space-x-3 bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full">
                <span className="text-white">🎨</span>
                <span>Beautiful, intuitive user interface</span>
              </div>
            </div>

            {/* Mobile-only Decorative Divider */}
            <div className="lg:hidden w-16 h-1 bg-white/30 rounded-full mx-auto mt-10"></div>
          </div>
        </div>

        {/* ================= RIGHT SIDE: Register Form ================= */}
        <div className="w-full lg:w-1/2 bg-white p-8 lg:p-12 flex flex-col justify-center">
          
          <div className="max-w-sm mx-auto w-full">
            
            {/* Header */}
            <div className="text-center mb-8 lg:text-left lg:mb-10">
              <h2 className="text-2xl font-bold text-[#2C2C2C]">Create an account</h2>
              <p className="text-gray-500 text-sm mt-1">Join us and start messaging today.</p>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              
              <div>
                <label className="block text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2 ml-1">
                  Full Name
                </label>
                <input
                  type="text"
                  name="name"
                  placeholder="John Doe"
                  value={form.name}
                  onChange={handleChange}
                  className="w-full p-3.5 rounded-xl bg-[#f8f9fa] text-[#2C2C2C] border border-gray-200 outline-none transition-all duration-200 focus:border-[#FF7A00] focus:ring-4 focus:ring-[#FF7A00]/10 placeholder:text-gray-400"
                  required
                />
              </div>

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
                  className="w-full p-3.5 rounded-xl bg-[#f8f9fa] text-[#2C2C2C] border border-gray-200 outline-none transition-all duration-200 focus:border-[#FF7A00] focus:ring-4 focus:ring-[#FF7A00]/10 placeholder:text-gray-400"
                  required
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
                  className="w-full p-3.5 rounded-xl bg-[#f8f9fa] text-[#2C2C2C] border border-gray-200 outline-none transition-all duration-200 focus:border-[#FF7A00] focus:ring-4 focus:ring-[#FF7A00]/10 placeholder:text-gray-400"
                  required
                />
              </div>

              <button
                type="submit"
                className="w-full bg-[#FF7A00] hover:bg-[#E66E00] transition duration-300 text-white font-semibold py-3.5 rounded-xl shadow-lg shadow-orange-200 hover:shadow-orange-300 transform active:scale-[0.98] mt-2"
              >
                Create Account
              </button>

            </form>

            {/* Footer */}
            <div className="text-center mt-8 pt-6 border-t border-gray-100">
              <p className="text-gray-500 text-sm">
                Already have an account?{" "}
                <Link
                  to="/"
                  className="text-[#2C2C2C] font-bold hover:text-[#FF7A00] transition-colors border-b-2 border-transparent hover:border-[#FF7A00] pb-0.5"
                >
                  Log In
                </Link>
              </p>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
}

export default Register;