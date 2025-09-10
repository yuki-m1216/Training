import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */

  output: "standalone",

  env: {
    NEXT_PUBLIC_SOCKET_URL: process.env.NEXT_PUBLIC_SOCKET_URL || "http://localhost:3000",
  },

  webpack: (config) => {
    config.externals.push({
      bufferutil:"bufferutil",
      "utf-8-validate":"utf-8-validate"
    });
    return config;
  }
};

export default nextConfig;
