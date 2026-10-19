package com.github.markusbear.trailtrack.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;

/**
 * Applies the real security rules to a @WebMvcTest, with a test-only signing
 * key instead of JWT_SECRET.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Import({SecurityConfig.class, JwtConfig.class})
@TestPropertySource(properties = "trailtrack.jwt.secret=" + WithApiSecurity.TEST_SECRET)
public @interface WithApiSecurity {

    String TEST_SECRET = "test-only-signing-key-not-used-anywhere-else";
}
