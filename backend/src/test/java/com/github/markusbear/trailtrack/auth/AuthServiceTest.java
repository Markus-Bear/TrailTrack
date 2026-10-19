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
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
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
        JwtService jwtService = mock(JwtService.class);
        when(jwtService.issueToken(any())).thenReturn(new JwtService.IssuedToken("signed-token", Instant.now()));
        authService = new AuthService(userRepository, passwordEncoder, jwtService);
    }

    private User existingUser(String password) {
        User user = new User();
        user.setId(5L);
        user.setEmail("hiker@example.com");
        user.setDisplayName("Markus");
        user.setRole(UserRole.HIKER);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setCreatedAt(Instant.now());
        return user;
    }

    @Test
    @DisplayName("registering creates a HIKER account with a hashed password and signs the user in")
    void registerCreatesHikerAndSignsIn() {
        when(userRepository.saveAndFlush(any(User.class))).thenAnswer(call -> call.getArgument(0));

        AuthResponse response = authService.register(new RegisterRequest(" Markus ", " Hiker@Example.com ", "correct horse"));

        ArgumentCaptor<User> saved = ArgumentCaptor.forClass(User.class);
        verify(userRepository).saveAndFlush(saved.capture());
        assertThat(saved.getValue().getEmail()).isEqualTo("hiker@example.com");
        assertThat(saved.getValue().getDisplayName()).isEqualTo("Markus");
        assertThat(saved.getValue().getRole()).isEqualTo(UserRole.HIKER);
        assertThat(saved.getValue().getCreatedAt()).isNotNull();
        assertThat(saved.getValue().getPasswordHash()).isNotEqualTo("correct horse");
        assertThat(passwordEncoder.matches("correct horse", saved.getValue().getPasswordHash())).isTrue();
        assertThat(response.accessToken()).isEqualTo("signed-token");
        assertThat(response.user().email()).isEqualTo("hiker@example.com");
    }

    @Test
    @DisplayName("registering rejects an email that already has an account, ignoring case")
    void registerRejectsExistingEmail() {
        when(userRepository.existsByEmail("hiker@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Markus", "Hiker@Example.com", "correct horse")))
                .isInstanceOf(EmailAlreadyRegisteredException.class);
        verify(userRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("registering rejects a duplicate email registered at the same moment")
    void registerRejectsDuplicateCaughtByConstraint() {
        when(userRepository.saveAndFlush(any(User.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate key"));

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Markus", "hiker@example.com", "correct horse")))
                .isInstanceOf(EmailAlreadyRegisteredException.class);
    }

    @Test
    @DisplayName("logging in with the right password signs the user in, ignoring email case")
    void loginSignsInWithCorrectPassword() {
        when(userRepository.findByEmail("hiker@example.com")).thenReturn(Optional.of(existingUser("correct horse")));

        AuthResponse response = authService.login(new LoginRequest(" Hiker@Example.com ", "correct horse"));

        assertThat(response.accessToken()).isEqualTo("signed-token");
        assertThat(response.user().id()).isEqualTo(5L);
    }

    @Test
    @DisplayName("logging in with a wrong password is rejected")
    void loginRejectsWrongPassword() {
        when(userRepository.findByEmail("hiker@example.com")).thenReturn(Optional.of(existingUser("correct horse")));

        assertThatThrownBy(() -> authService.login(new LoginRequest("hiker@example.com", "wrong horse")))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    @DisplayName("an unknown email gets the same error as a wrong password")
    void loginRejectsUnknownEmailLikeWrongPassword() {
        when(userRepository.findByEmail("hiker@example.com")).thenReturn(Optional.of(existingUser("correct horse")));
        when(userRepository.findByEmail("nobody@example.com")).thenReturn(Optional.empty());

        InvalidCredentialsException wrongPassword = catchInvalidCredentials(new LoginRequest("hiker@example.com", "wrong horse"));
        InvalidCredentialsException unknownEmail = catchInvalidCredentials(new LoginRequest("nobody@example.com", "correct horse"));

        assertThat(unknownEmail.getBody().getDetail()).isEqualTo(wrongPassword.getBody().getDetail());
        assertThat(unknownEmail.getStatusCode()).isEqualTo(wrongPassword.getStatusCode());
    }

    private InvalidCredentialsException catchInvalidCredentials(LoginRequest request) {
        try {
            authService.login(request);
        } catch (InvalidCredentialsException e) {
            return e;
        }
        throw new AssertionError("Expected InvalidCredentialsException");
    }
}
