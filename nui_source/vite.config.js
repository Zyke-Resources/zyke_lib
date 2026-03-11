import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig({
    plugins: [react()],
    base: "./",
    build: {
        outDir: "./../nui",
        assetsDir: "",
        rollupOptions: {
            output: {
                entryFileNames: "[name].js",
                chunkFileNames: "[name].js",
                assetFileNames: "[name].[ext]",
            },
        },
    },
    server: {
        host: true,
        port: 5173,
        strictPort: true,
        hmr: {
            protocol: "ws",
            host: "127.0.0.1",
            port: 5173,
        },
    },
});
