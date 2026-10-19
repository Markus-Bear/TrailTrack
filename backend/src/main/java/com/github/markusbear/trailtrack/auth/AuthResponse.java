package com.github.markusbear.trailtrack.auth;

import java.time.Instant;

/**
 * Returned after registering or logging in.
 *
 * @param accessToken the login token to send with later requests
 * @param expiresAt when the token expires and the user must log in again
 * @param user the signed-in user's account details
 */
public record AuthResponse(String accessToken, Instant expiresAt, UserResponse user) {
}
