package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.jayway.jsonpath.JsonPath;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import org.springframework.transaction.annotation.Transactional;

/**
 * Runs against the real database; each test's changes are rolled back.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@DisplayName("Authentication, end to end")
class AuthFlowIntegrationTest {

    private static final String EMAIL = "auth-flow-test@example.com";
    private static final String PASSWORD = "correct horse";

    @Autowired
    private MockMvcTester mvc;

    @Autowired
    private JwtEncoder jwtEncoder;

    private MvcTestResult register() {
        return mvc.post().uri("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"displayName": "Flow Test", "email": "%s", "password": "%s"}
                        """.formatted(EMAIL, PASSWORD))
                .exchange();
    }

    private MvcTestResult me(String token) {
        return mvc.get().uri("/api/auth/me").header(HttpHeaders.AUTHORIZATION, "Bearer " + token).exchange();
    }

    private static <T> T read(MvcTestResult result, String path) throws Exception {
        return JsonPath.read(result.getResponse().getContentAsString(), path);
    }

    @Test
    @DisplayName("a registered user can log in and use the token on a protected endpoint")
    void registerLoginAndCallProtectedEndpoint() throws Exception {
        assertThat(register()).hasStatus(201);

        MvcTestResult login = mvc.post().uri("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"email": "%s", "password": "%s"}
                        """.formatted(EMAIL.toUpperCase(), PASSWORD))
                .exchange();
        assertThat(login).hasStatusOk();

        MvcTestResult me = me(read(login, "$.accessToken"));
        assertThat(me).hasStatusOk();
        assertThat(me).bodyJson().extractingPath("$.email").isEqualTo(EMAIL);
    }

    @Test
    @DisplayName("an expired token is rejected with 401")
    void expiredTokenIsRejected() throws Exception {
        Integer userId = read(register(), "$.user.id");
        Instant past = Instant.now().minus(1, ChronoUnit.HOURS);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .subject(userId.toString())
                .issuedAt(past)
                .expiresAt(past.plus(10, ChronoUnit.MINUTES))
                .claim("role", "HIKER")
                .build();
        String expired = jwtEncoder.encode(
                JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();

        assertThat(me(expired)).hasStatus(401);
    }

    @Test
    @DisplayName("a token edited to claim the ADMIN role is rejected with 401")
    void tamperedTokenIsRejected() throws Exception {
        String token = read(register(), "$.accessToken");
        String[] parts = token.split("\\.");
        String payload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
        assertThat(payload).contains("\"HIKER\"");

        String edited = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(payload.replace("\"HIKER\"", "\"ADMIN\"").getBytes(StandardCharsets.UTF_8));
        String tampered = parts[0] + "." + edited + "." + parts[2];

        assertThat(me(token)).hasStatusOk();
        assertThat(me(tampered)).hasStatus(401);
    }
}
