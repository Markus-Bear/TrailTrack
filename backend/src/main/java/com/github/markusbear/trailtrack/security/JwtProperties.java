package com.github.markusbear.trailtrack.security;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Settings for login tokens, from trailtrack.jwt.* in application.properties.
 *
 * @param secret the key tokens are signed with, from the JWT_SECRET environment variable
 * @param expiry how long a token stays valid after it is issued
 */
@ConfigurationProperties("trailtrack.jwt")
public record JwtProperties(String secret, Duration expiry) {
}
