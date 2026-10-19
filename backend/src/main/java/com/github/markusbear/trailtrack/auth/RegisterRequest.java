package com.github.markusbear.trailtrack.auth;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.nio.charset.StandardCharsets;

/**
 * Body of a registration request.
 *
 * @param displayName the name shown to other users
 * @param email the email address used to log in
 * @param password the chosen password, at least 8 characters
 */
public record RegisterRequest(
        @NotBlank(message = "Display name is required")
        @Size(max = 50, message = "Display name must be at most 50 characters")
        String displayName,

        @NotBlank(message = "Email is required")
        @Email(message = "Email is not valid")
        @Size(max = 254, message = "Email is too long")
        String email,

        @NotNull(message = "Password is required")
        @Size(min = 8, message = "Password must be at least 8 characters")
        String password) {

    /**
     * BCrypt only uses the first 72 bytes of a password, so longer passwords
     * are rejected rather than silently cut short.
     */
    @AssertTrue(message = "Password is too long")
    public boolean isPasswordWithinBcryptLimit() {
        return password == null || password.getBytes(StandardCharsets.UTF_8).length <= 72;
    }
}
