import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vite.dev/config/
export default defineConfig({
  base: './',
  plugins: [react()],
  server: {
    port: 3000,
    host: '0.0.0.0',
    proxy: {
      '/api/vision': {
        target: 'http://127.0.0.1:8095',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/vision/, ''),
      },
      '/rest/v1': {
        target: 'http://127.0.0.1:54321',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/rest\/v1/, ''),
      },
    },
  },
  preview: {
    port: 3000,
    host: '0.0.0.0',
  },
  build: {
    chunkSizeWarningLimit: 1500,
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom'],
          'vendor-icons': ['lucide-react'],
          'vendor-supabase': ['@supabase/supabase-js'],
        },
      },
    },
  },
});
