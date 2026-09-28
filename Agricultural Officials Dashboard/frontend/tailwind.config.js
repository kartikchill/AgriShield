/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        cmdBg: "#080c14",
        cmdSurface: "#0f172a",
        cmdCard: "rgba(15, 23, 42, 0.6)",
        cmdBorder: "rgba(30, 41, 59, 0.8)",
      },
      boxShadow: {
        'glow-red': '0 0 15px rgba(239, 68, 68, 0.25)',
        'glow-amber': '0 0 15px rgba(245, 158, 11, 0.25)',
        'glow-green': '0 0 15px rgba(16, 185, 129, 0.25)',
        'glow-violet': '0 0 15px rgba(139, 92, 246, 0.25)',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
