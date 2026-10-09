package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRole;
import java.time.Instant;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(AuthController.class)
@DisplayName("AuthController")
class AuthControllerTest {

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private AuthService authService;

    private MockMvcTester.MockMvcRequestBuilder register(String json) {
        return mvc.post().uri("/api/auth/register").contentType(MediaType.APPLICATION_JSON).content(json);
    }

    @Test
    @DisplayName("POST /api/auth/register returns 201 with the account, never the password hash")
    void registerReturnsCreatedAccount() {
        User user = new User();
        user.setId(5L);
        user.setEmail("hiker@example.com");
        user.setDisplayName("Markus");
        user.setRole(UserRole.HIKER);
        user.setPasswordHash("$2a$10$hash");
        user.setCreatedAt(Instant.now());
        when(authService.register(any())).thenReturn(user);

        var response = register("""
                {"displayName": "Markus", "email": "hiker@example.com", "password": "correct horse"}
                """).exchange();

        assertThat(response).hasStatus(201);
        assertThat(response).bodyJson().extractingPath("$.email").isEqualTo("hiker@example.com");
        assertThat(response).bodyJson().extractingPath("$.role").isEqualTo("HIKER");
        assertThat(response).bodyJson().doesNotHavePath("$.passwordHash");
    }

    @Test
    @DisplayName("returns 400 with a message for each invalid field")
    void registerRejectsInvalidFields() {
        var response = register("""
                {"displayName": " ", "email": "not-an-email", "password": "short"}
                """).exchange();

        assertThat(response).hasStatus(400);
        assertThat(response).bodyJson().extractingPath("$.errors.displayName").isEqualTo("Display name is required");
        assertThat(response).bodyJson().extractingPath("$.errors.email").isEqualTo("Email is not valid");
        assertThat(response).bodyJson().extractingPath("$.errors.password")
                .isEqualTo("Password must be at least 8 characters");
    }

    @Test
    @DisplayName("returns 400 for a password longer than BCrypt can use")
    void registerRejectsOverlongPassword() {
        // 40 characters, but 80 bytes in UTF-8.
        String password = "é".repeat(40);

        var response = register("""
                {"displayName": "Markus", "email": "hiker@example.com", "password": "%s"}
                """.formatted(password)).exchange();

        assertThat(response).hasStatus(400);
    }

    @Test
    @DisplayName("returns 409 when the email already has an account")
    void registerRejectsExistingEmail() {
        when(authService.register(any())).thenThrow(new EmailAlreadyRegisteredException());

        var response = register("""
                {"displayName": "Markus", "email": "hiker@example.com", "password": "correct horse"}
                """).exchange();

        assertThat(response).hasStatus(409);
        assertThat(response).bodyJson().extractingPath("$.detail")
                .isEqualTo("An account with this email already exists");
    }
}
