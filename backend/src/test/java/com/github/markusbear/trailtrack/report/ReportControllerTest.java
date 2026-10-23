package com.github.markusbear.trailtrack.report;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

import com.github.markusbear.trailtrack.security.WithApiSecurity;
import com.github.markusbear.trailtrack.trail.TrailNotFoundException;
import java.time.Instant;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(ReportController.class)
@WithApiSecurity
@DisplayName("ReportController")
class ReportControllerTest {

    private static final String VALID = """
            {"conditionType": "MUD", "severity": "MODERATE", "note": "Muddy after rain",
             "clientRef": "6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90"}
            """;
    private static final ReportResponse REPORT = new ReportResponse(99L, 12L, ConditionType.MUD,
            Severity.MODERATE, "Muddy after rain", ReportStatus.OPEN, Instant.now());

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private ReportService reportService;

    private MockMvcTester.MockMvcRequestBuilder post(String json) {
        return mvc.post().uri("/api/trails/12/reports").contentType(MediaType.APPLICATION_JSON).content(json)
                .with(jwt().jwt(token -> token.subject("5")));
    }

    @Test
    @DisplayName("POST /api/trails/{id}/reports returns 201 with the stored report")
    void submitReturnsCreated() {
        when(reportService.submit(eq(12L), eq(5L), any()))
                .thenReturn(new ReportService.SubmitResult(REPORT, true));

        var response = post(VALID).exchange();

        assertThat(response).hasStatus(201);
        assertThat(response).bodyJson().extractingPath("$.id").isEqualTo(99);
        assertThat(response).bodyJson().extractingPath("$.status").isEqualTo("OPEN");
    }

    @Test
    @DisplayName("a retried report returns 200 with the report already stored")
    void retryReturnsOk() {
        when(reportService.submit(anyLong(), anyLong(), any()))
                .thenReturn(new ReportService.SubmitResult(REPORT, false));

        assertThat(post(VALID).exchange()).hasStatusOk();
    }

    @Test
    @DisplayName("reporting without a login token returns 401")
    void submitRequiresToken() {
        var response = mvc.post().uri("/api/trails/12/reports")
                .contentType(MediaType.APPLICATION_JSON).content(VALID).exchange();

        assertThat(response).hasStatus(401);
    }

    @Test
    @DisplayName("a report without a condition type returns 400")
    void missingConditionTypeIsRejected() {
        var response = post("""
                {"severity": "LOW", "clientRef": "6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90"}
                """).exchange();

        assertThat(response).hasStatus(400);
        assertThat(response).bodyJson().extractingPath("$.errors.conditionType")
                .isEqualTo("Condition type is required");
    }

    @Test
    @DisplayName("a report other than CLEAR without a severity returns 400")
    void missingSeverityIsRejected() {
        var response = post("""
                {"conditionType": "FLOODING", "clientRef": "6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90"}
                """).exchange();

        assertThat(response).hasStatus(400);
    }

    @Test
    @DisplayName("a CLEAR report needs no severity")
    void clearNeedsNoSeverity() {
        when(reportService.submit(anyLong(), anyLong(), any()))
                .thenReturn(new ReportService.SubmitResult(REPORT, true));

        var response = post("""
                {"conditionType": "CLEAR", "clientRef": "6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90"}
                """).exchange();

        assertThat(response).hasStatus(201);
    }

    @Test
    @DisplayName("an unknown condition type returns 400")
    void unknownConditionTypeIsRejected() {
        var response = post("""
                {"conditionType": "SNOW", "severity": "LOW",
                 "clientRef": "6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90"}
                """).exchange();

        assertThat(response).hasStatus(400);
    }

    @Test
    @DisplayName("a report for an unknown trail returns 404")
    void unknownTrailReturnsNotFound() {
        when(reportService.submit(anyLong(), anyLong(), any())).thenThrow(new TrailNotFoundException(12L));

        assertThat(post(VALID).exchange()).hasStatus(404);
    }
}
