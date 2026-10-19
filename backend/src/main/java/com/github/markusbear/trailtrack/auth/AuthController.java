package com.github.markusbear.trailtrack.auth;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST endpoints for creating an account, logging in and getting the
 * signed-in user.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * Registers a new HIKER account and signs the user in.
     *
     * @param request the registration details
     * @return a login token and the new account, with 201 Created
     */
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    /**
     * Logs in with an email and password.
     *
     * @param request the login details
     * @return a login token and the user's account
     */
    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    /**
     * @param token the caller's validated login token
     * @return the signed-in user's account details
     */
    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal Jwt token) {
        return authService.currentUser(Long.parseLong(token.getSubject()));
    }
}
