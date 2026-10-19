package com.github.markusbear.trailtrack.auth;

import com.github.markusbear.trailtrack.security.JwtProperties;
import com.github.markusbear.trailtrack.user.User;
import java.time.Duration;
import java.time.Instant;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/**
 * Issues login tokens.
 */
@Service
public class JwtService {

    private final JwtEncoder jwtEncoder;
    private final Duration expiry;

    public JwtService(JwtEncoder jwtEncoder, JwtProperties properties) {
        this.jwtEncoder = jwtEncoder;
        this.expiry = properties.expiry();
    }

    /**
     * Issues a signed token identifying the user (subject = user id) and
     * carrying their role.
     *
     * @param user the user who has just registered or logged in
     * @return the token and when it expires
     */
    public IssuedToken issueToken(User user) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(expiry);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("trailtrack")
                .subject(user.getId().toString())
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claim("role", user.getRole().name())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new IssuedToken(token, expiresAt);
    }

    /**
     * @param value the encoded token
     * @param expiresAt when the token stops being accepted
     */
    public record IssuedToken(String value, Instant expiresAt) {
    }
}
