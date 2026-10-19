package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import com.github.markusbear.trailtrack.user.UserRole;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@DisplayName("AdminAccountInitializer")
class AdminAccountInitializerTest {

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
    }

    private void run(String email, String password) {
        new AdminAccountInitializer(userRepository, passwordEncoder, email, password).run(null);
    }

    @Test
    @DisplayName("does nothing when the admin email or password is not set")
    void doesNothingWhenNotConfigured() {
        run("", "admin password");
        run("admin@example.com", "");

        verifyNoInteractions(userRepository);
    }

    @Test
    @DisplayName("creates an ADMIN account with a hashed password and a lower-case email")
    void createsAdminAccount() {
        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.empty());

        run(" Admin@Example.com ", "admin password");

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(saved.capture());
        assertThat(saved.getValue().getEmail()).isEqualTo("admin@example.com");
        assertThat(saved.getValue().getRole()).isEqualTo(UserRole.ADMIN);
        assertThat(passwordEncoder.matches("admin password", saved.getValue().getPasswordHash())).isTrue();
    }

    @Test
    @DisplayName("makes an existing account an ADMIN without changing its password")
    void promotesExistingAccount() {
        User hiker = new User();
        hiker.setEmail("admin@example.com");
        hiker.setRole(UserRole.HIKER);
        hiker.setPasswordHash("existing-hash");
        hiker.setCreatedAt(Instant.now());
        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.of(hiker));

        run("admin@example.com", "a different password");

        assertThat(hiker.getRole()).isEqualTo(UserRole.ADMIN);
        assertThat(hiker.getPasswordHash()).isEqualTo("existing-hash");
        verify(userRepository).save(hiker);
    }

    @Test
    @DisplayName("refuses to create an admin with a password under 8 characters")
    void rejectsShortPassword() {
        when(userRepository.findByEmail("admin@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> run("admin@example.com", "short"))
                .isInstanceOf(IllegalStateException.class);
        verify(userRepository, never()).save(any());
    }
}
