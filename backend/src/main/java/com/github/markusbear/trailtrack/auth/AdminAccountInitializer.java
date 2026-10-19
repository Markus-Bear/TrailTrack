package com.github.markusbear.trailtrack.auth;

import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import com.github.markusbear.trailtrack.user.UserRole;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Creates the first administrator account on startup, from the ADMIN_EMAIL
 * and ADMIN_PASSWORD environment variables. Registration only creates HIKER
 * accounts, so this is the only way to get an ADMIN.
 *
 * Does nothing if either variable is unset. If an account with that email
 * already exists, it is made an ADMIN and keeps its own password.
 */
@Component
public class AdminAccountInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminAccountInitializer.class);
    private static final int MIN_PASSWORD_LENGTH = 8;
    private static final int MAX_PASSWORD_BYTES = 72;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final String email;
    private final String password;

    public AdminAccountInitializer(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            @Value("${trailtrack.admin.email:}") String email,
            @Value("${trailtrack.admin.password:}") String password) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.email = email;
        this.password = password;
    }

    /**
     * @param args ignored
     * @throws IllegalStateException if the configured password is shorter than
     *         8 characters or longer than 72 bytes
     */
    @Override
    public void run(ApplicationArguments args) {
        if (email.isBlank() || password.isBlank()) {
            return;
        }
        String normalisedEmail = AuthService.normaliseEmail(email);

        Optional<User> existing = userRepository.findByEmail(normalisedEmail);
        if (existing.isPresent()) {
            User user = existing.get();
            if (user.getRole() != UserRole.ADMIN) {
                user.setRole(UserRole.ADMIN);
                userRepository.save(user);
                log.info("Made the existing account {} an administrator", normalisedEmail);
            }
            return;
        }

        int passwordBytes = password.getBytes(StandardCharsets.UTF_8).length;
        if (password.length() < MIN_PASSWORD_LENGTH || passwordBytes > MAX_PASSWORD_BYTES) {
            throw new IllegalStateException("ADMIN_PASSWORD must be at least 8 characters and at most 72 bytes");
        }

        User admin = new User();
        admin.setEmail(normalisedEmail);
        admin.setPasswordHash(passwordEncoder.encode(password));
        admin.setDisplayName("Administrator");
        admin.setRole(UserRole.ADMIN);
        admin.setCreatedAt(Instant.now());
        userRepository.save(admin);
        log.info("Created the administrator account {}", normalisedEmail);
    }
}
