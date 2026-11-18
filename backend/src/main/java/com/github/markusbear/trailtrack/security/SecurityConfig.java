package com.github.markusbear.trailtrack.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Who can call which endpoint. Trails can be viewed without an account,
 * endpoints under /api/admin need an ADMIN account, and everything else needs
 * a login token, sent in the Authorization header as "Bearer" followed by the
 * token. When trailtrack.require-https is true, plain http requests are
 * redirected to https.
 */
@Configuration
public class SecurityConfig {

    /**
     * @param http the security builder
     * @param requireHttps whether plain http requests are redirected to https
     * @return the access rules above, with login tokens checked on every request
     * @throws Exception if the rules cannot be built
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
            @Value("${trailtrack.require-https:false}") boolean requireHttps) throws Exception {
        http
                // The API is stateless: no sessions or cookies, so no CSRF risk.
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.POST, "/api/auth/register", "/api/auth/login").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/trails/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        // Lets failed requests show their real error instead of 401.
                        .requestMatchers("/error").permitAll()
                        .anyRequest().authenticated())
                .oauth2ResourceServer(resourceServer -> resourceServer
                        .jwt(jwt -> jwt.jwtAuthenticationConverter(roleConverter())));
        if (requireHttps) {
            // Behind a hosting proxy the original scheme comes from X-Forwarded-Proto.
            http.redirectToHttps(Customizer.withDefaults());
        }
        return http.build();
    }

    /**
     * Turns the token's role claim into a Spring Security role, e.g. "ADMIN"
     * into ROLE_ADMIN.
     */
    private JwtAuthenticationConverter roleConverter() {
        JwtGrantedAuthoritiesConverter authorities = new JwtGrantedAuthoritiesConverter();
        authorities.setAuthoritiesClaimName("role");
        authorities.setAuthorityPrefix("ROLE_");

        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(authorities);
        return converter;
    }
}
