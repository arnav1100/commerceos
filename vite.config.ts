import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
export default defineConfig({ plugins: [react(), tailwindcss()], server: { host: '0.0.0.0', allowedHosts: true }, build: { rollupOptions: { output: { manualChunks(id) { if (!id.includes('node_modules')) return; if (/jspdf/.test(id)) return 'jspdf-vendor'; if (/html2canvas|canvg|dompurify/.test(id)) return 'pdf-deps'; if (/recharts|d3-|victory-vendor/.test(id)) return 'charts-vendor'; if (/react|scheduler/.test(id)) return 'framework'; if (/lucide-react/.test(id)) return 'icons'; } } } } });
