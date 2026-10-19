package com.github.markusbear.trailtrack.auth;

import jakarta.validation.constraints.NotBlank;

/**
 * Body of a login request.
 *
 * @param email the account's email address
 * @param password the account's password
 */
public record LoginRequest(
        @NotBlank(message = "Email is required")
        String email,

        @NotBlank(message = "Password is required")
        String password) {
}
