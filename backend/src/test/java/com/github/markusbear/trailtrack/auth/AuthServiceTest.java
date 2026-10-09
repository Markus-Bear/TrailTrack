package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import com.github.markusbear.trailtrack.user.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@DisplayName("AuthService")
class AuthServiceTest {

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private UserRepository userRepository;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        authService = new AuthService(userRepository, passwordEncoder);
    }

    @Test
    @DisplayName("creates a HIKER account with a hashed password and a lower-case email")
    void registerCreatesHikerWithHashedPassword() {
        when(userRepository.saveAndFlush(any(User.class))).thenAnswer(call -> call.getArgument(0));

        User user = authService.register(new RegisterRequest(" Markus ", " Hiker@Example.com ", "correct horse"));

        assertThat(user.getEmail()).isEqualTo("hiker@example.com");
        assertThat(user.getDisplayName()).isEqualTo("Markus");
        assertThat(user.getRole()).isEqualTo(UserRole.HIKER);
        assertThat(user.getCreatedAt()).isNotNull();
        assertThat(user.getPasswordHash()).isNotEqualTo("correct horse");
        assertThat(passwordEncoder.matches("correct horse", user.getPasswordHash())).isTrue();
    }

    @Test
    @DisplayName("rejects an email that already has an account, ignoring case")
    void registerRejectsExistingEmail() {
        when(userRepository.existsByEmail("hiker@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Markus", "Hiker@Example.com", "correct horse")))
                .isInstanceOf(EmailAlreadyRegisteredException.class);
        verify(userRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("rejects a duplicate email registered at the same moment")
    void registerRejectsDuplicateCaughtByConstraint() {
        when(userRepository.saveAndFlush(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate key"));

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Markus", "hiker@example.com", "correct horse")))
                .isInstanceOf(EmailAlreadyRegisteredException.class);
    }
}
