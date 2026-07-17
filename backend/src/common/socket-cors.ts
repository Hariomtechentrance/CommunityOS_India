/**
 * Shared CORS allowlist for the HTTP API and all Socket.IO gateways. Reads
 * a comma-separated list of allowed browser origins from
 * CORS_ALLOWED_ORIGINS (e.g. "https://community-os-india.web.app,http://localhost:5000").
 * Falls back to allowing any origin only when that env var is unset, so
 * local dev keeps working out of the box - always set it in production.
 *
 * Native Android/iOS HTTP and socket clients don't send a browser `Origin`
 * header at all, so this restriction only affects web clients; it never
 * blocks the mobile app.
 */
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

export const corsOptions = {
  origin: allowedOrigins.length > 0 ? allowedOrigins : true,
  credentials: true,
};
