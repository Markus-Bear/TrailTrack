package com.github.markusbear.trailtrack.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import com.github.markusbear.trailtrack.security.JwtConfig;
import com.github.markusbear.trailtrack.security.JwtProperties;
import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRole;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

@DisplayName("JwtService")
class JwtServiceTest {

    private final JwtConfig config = new JwtConfig();
    private final JwtProperties properties =
            new JwtProperties("test-only-signing-key-not-used-anywhere-else", Duration.ofDays(7));
    private final SecretKey key = config.jwtSigningKey(properties);

    @Test
    @DisplayName("issues a signed token with the user's id, role and expiry")
    void issuesTokenWithIdRoleAndExpiry() {
        User user = new User();
        user.setId(7L);
        user.setRole(UserRole.HIKER);

        JwtService.IssuedToken token = new JwtService(config.jwtEncoder(key), properties).issueToken(user);
        Jwt decoded = config.jwtDecoder(key).decode(token.value());

        assertThat(decoded.getSubject()).isEqualTo("7");
        assertThat(decoded.getClaimAsString("role")).isEqualTo("HIKER");
        assertThat(decoded.getExpiresAt()).isEqualTo(token.expiresAt().truncatedTo(ChronoUnit.SECONDS));
        assertThat(token.expiresAt()).isCloseTo(Instant.now().plus(Duration.ofDays(7)), within(5, ChronoUnit.SECONDS));
    }
}
