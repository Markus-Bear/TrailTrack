package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

import com.github.markusbear.trailtrack.security.WithApiSecurity;
import java.time.Instant;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(AuthController.class)
@WithApiSecurity
@DisplayName("AuthController")
class AuthControllerTest {

    private static final UserResponse HIKER = new UserResponse(5L, "Markus", "hiker@example.com", "HIKER");

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private AuthService authService;

    private MockMvcTester.MockMvcRequestBuilder post(String uri, String json) {
        return mvc.post().uri(uri).contentType(MediaType.APPLICATION_JSON).content(json);
    }

    @Test
    @DisplayName("POST /api/auth/register returns 201 with a token and the account, never the password hash")
    void registerReturnsTokenAndAccount() {
        when(authService.register(any())).thenReturn(new AuthResponse("signed-token", Instant.now(), HIKER));

        var response = post("/api/auth/register", """
                {"displayName": "Markus", "email": "hiker@example.com", "password": "correct horse"}
                """).exchange();

        assertThat(response).hasStatus(201);
        assertThat(response).bodyJson().extractingPath("$.accessToken").isEqualTo("signed-token");
        assertThat(response).bodyJson().extractingPath("$.user.email").isEqualTo("hiker@example.com");
        assertThat(response).bodyJson().doesNotHavePath("$.user.passwordHash");
    }

    @Test
    @DisplayName("registering returns 400 with a message for each invalid field")
    void registerRejectsInvalidFields() {
        var response = post("/api/auth/register", """
                {"displayName": " ", "email": "not-an-email", "password": "short"}
                """).exchange();

        assertThat(response).hasStatus(400);
        assertThat(response).bodyJson().extractingPath("$.errors.displayName").isEqualTo("Display name is required");
        assertThat(response).bodyJson().extractingPath("$.errors.email").isEqualTo("Email is not valid");
        assertThat(response).bodyJson().extractingPath("$.errors.password")
                .isEqualTo("Password must be at least 8 characters");
    }

    @Test
    @DisplayName("registering returns 400 for a password longer than BCrypt can use")
    void registerRejectsOverlongPassword() {
        // 40 characters, but 80 bytes in UTF-8.
        String password = "é".repeat(40);

        var response = post("/api/auth/register", """
                {"displayName": "Markus", "email": "hiker@example.com", "password": "%s"}
                """.formatted(password)).exchange();

        assertThat(response).hasStatus(400);
    }

    @Test
    @DisplayName("registering returns 409 when the email already has an account")
    void registerRejectsExistingEmail() {
        when(authService.register(any())).thenThrow(new EmailAlreadyRegisteredException());

        var response = post("/api/auth/register", """
                {"displayName": "Markus", "email": "hiker@example.com", "password": "correct horse"}
                """).exchange();

        assertThat(response).hasStatus(409);
        assertThat(response).bodyJson().extractingPath("$.detail")
                .isEqualTo("An account with this email already exists");
    }

    @Test
    @DisplayName("POST /api/auth/login returns 200 with a token for the right password")
    void loginReturnsToken() {
        when(authService.login(any())).thenReturn(new AuthResponse("signed-token", Instant.now(), HIKER));

        var response = post("/api/auth/login", """
                {"email": "hiker@example.com", "password": "correct horse"}
                """).exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.accessToken").isEqualTo("signed-token");
    }

    @Test
    @DisplayName("logging in returns 401 for a wrong email or password")
    void loginRejectsBadCredentials() {
        when(authService.login(any())).thenThrow(new InvalidCredentialsException());

        var response = post("/api/auth/login", """
                {"email": "hiker@example.com", "password": "wrong horse"}
                """).exchange();

        assertThat(response).hasStatus(401);
        assertThat(response).bodyJson().extractingPath("$.detail").isEqualTo("Email or password is incorrect");
    }

    @Test
    @DisplayName("GET /api/auth/me returns 401 without a login token")
    void meRequiresToken() {
        assertThat(mvc.get().uri("/api/auth/me")).hasStatus(401);
    }

    @Test
    @DisplayName("GET /api/auth/me returns the account of the token's user")
    void meReturnsSignedInUser() {
        when(authService.currentUser(5L)).thenReturn(HIKER);

        var response = mvc.get().uri("/api/auth/me").with(jwt().jwt(token -> token.subject("5"))).exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.displayName").isEqualTo("Markus");
    }
}
