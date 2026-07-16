/** Strips passwordHash before a User (or anything spreading its fields) is
 * ever returned from a controller - it must never reach the client. */
export function sanitizeUser<T extends { passwordHash?: string | null }>(
  user: T,
): Omit<T, 'passwordHash'> {
  const { passwordHash: _passwordHash, ...rest } = user;
  return rest;
}
