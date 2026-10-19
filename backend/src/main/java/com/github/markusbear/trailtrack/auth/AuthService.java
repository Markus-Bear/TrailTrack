package com.github.markusbear.trailtrack.auth;

import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import com.github.markusbear.trailtrack.user.UserRole;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.ErrorResponseException;

/**
 * Registering, logging in and looking up the signed-in user.
 */
@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    /** Checked against when an email is unknown, so login takes the same time either way. */
    private final String unknownUserHash;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.unknownUserHash = passwordEncoder.encode(UUID.randomUUID().toString());
    }

    /**
     * Creates a HIKER account with a hashed password and signs the user in.
     *
     * @param request the validated registration details
     * @return a login token and the new account
     * @throws EmailAlreadyRegisteredException if the email already has an account
     */
    public AuthResponse register(RegisterRequest request) {
        String email = normaliseEmail(request.email());
        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyRegisteredException();
        }

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.displayName().trim());
        user.setRole(UserRole.HIKER);
        user.setCreatedAt(Instant.now());

        try {
            return signIn(userRepository.saveAndFlush(user));
        } catch (DataIntegrityViolationException e) {
            // Two registrations with the same email at the same moment both
            // pass the check above; the unique constraint stops the second.
            throw new EmailAlreadyRegisteredException();
        }
    }

    /**
     * Checks an email and password and signs the user in.
     *
     * @param request the login details
     * @return a login token and the user's account
     * @throws InvalidCredentialsException if the email is unknown or the password is wrong
     */
    public AuthResponse login(LoginRequest request) {
        Optional<User> user = userRepository.findByEmail(normaliseEmail(request.email()));
        String hash = user.map(User::getPasswordHash).orElse(unknownUserHash);
        boolean passwordMatches = passwordEncoder.matches(request.password(), hash);
        if (user.isEmpty() || !passwordMatches) {
            throw new InvalidCredentialsException();
        }
        return signIn(user.get());
    }

    /**
     * @param userId the id from the user's login token
     * @return the user's account details
     * @throws ErrorResponseException 401 if the account no longer exists
     */
    public UserResponse currentUser(long userId) {
        return userRepository.findById(userId)
                .map(UserResponse::from)
                .orElseThrow(() -> new ErrorResponseException(HttpStatus.UNAUTHORIZED));
    }

    private AuthResponse signIn(User user) {
        JwtService.IssuedToken token = jwtService.issueToken(user);
        return new AuthResponse(token.value(), token.expiresAt(), UserResponse.from(user));
    }

    /**
     * @param email an email address as typed
     * @return the address trimmed and in lower case
     */
    static String normaliseEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
