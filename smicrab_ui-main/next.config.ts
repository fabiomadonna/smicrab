import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  async rewrites() {
    return [
      {
        source: "/tmp/analysis/:path*",
        destination: `${process.env.DOWNLOAD_URL}/tmp/analysis/:path*`,
      },
      {
        source: "/datasets/:path*",
        destination: `${process.env.DOWNLOAD_URL}/datasets/:path*`,
      },
      {
        source: "/datasets_csv/:path*",
        destination: `${process.env.DOWNLOAD_URL}/datasets_csv/:path*`,
      },
    ];
  },
};

export default nextConfig;
