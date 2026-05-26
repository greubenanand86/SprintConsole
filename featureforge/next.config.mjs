/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    optimizePackageImports: ['@fortawesome/react-fontawesome', 'primereact'],
  },
}

export default nextConfig
