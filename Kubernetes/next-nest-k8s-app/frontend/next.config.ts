import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone',
  outputFileTracingRoot: process.cwd(),
  
  // Disable static optimization to ensure proper client-side hydration
  experimental: {},
};

export default nextConfig;
