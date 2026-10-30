/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#0d47a1', // Royal Carrefour Blue
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#0a2e6b',
        },
        coral: {
          500: '#e53935',
          600: '#d32f2f',
        }
      },
      fontFamily: {
        sans: ['Cairo', 'Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
