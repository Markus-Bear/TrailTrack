package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.auth.JwtService;
import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

/**
 * Checks the ADMIN rule on /api/admin with real signed tokens. The import
 * itself is mocked, so the register is never called.
 */
@SpringBootTest
@AutoConfigureMockMvc
@DisplayName("Admin endpoints, end to end")
class AdminAccessIntegrationTest {

    @Autowired
    private MockMvcTester mvc;

    @Autowired
    private JwtService jwtService;

    @MockitoBean
    private TrailImportService trailImportService;

    private String tokenFor(UserRole role) {
        User user = new User();
        user.setId(999L);
        user.setRole(role);
        return jwtService.issueToken(user).value();
    }

    private MockMvcTester.MockMvcRequestBuilder importTrails() {
        return mvc.post().uri("/api/admin/trails/import");
    }

    @Test
    @DisplayName("the trail import rejects a request without a login token with 401")
    void anonymousIsRejected() {
        assertThat(importTrails()).hasStatus(401);
        verify(trailImportService, never()).importLaoisTrails();
    }

    @Test
    @DisplayName("the trail import rejects a HIKER's token with 403")
    void hikerIsForbidden() {
        var response = importTrails()
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + tokenFor(UserRole.HIKER)).exchange();

        assertThat(response).hasStatus(403);
        verify(trailImportService, never()).importLaoisTrails();
    }

    @Test
    @DisplayName("the trail import accepts an ADMIN's token")
    void adminIsAllowed() {
        when(trailImportService.importLaoisTrails()).thenReturn(new TrailImportService.TrailImportResult(0, 28));

        var response = importTrails()
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + tokenFor(UserRole.ADMIN)).exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.updated").isEqualTo(28);
    }
}
