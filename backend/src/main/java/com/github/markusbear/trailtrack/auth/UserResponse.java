package com.github.markusbear.trailtrack.auth;

import com.github.markusbear.trailtrack.user.User;

/**
 * A user's public account details. Never includes the password hash.
 *
 * @param id the user's id
 * @param displayName the name shown to other users
 * @param email the email address used to log in
 * @param role HIKER or ADMIN
 */
public record UserResponse(Long id, String displayName, String email, String role) {

    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getDisplayName(), user.getEmail(), user.getRole().name());
    }
}
