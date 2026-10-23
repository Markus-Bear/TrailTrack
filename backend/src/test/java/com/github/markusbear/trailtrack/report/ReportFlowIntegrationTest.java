package com.github.markusbear.trailtrack.report;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.markusbear.trailtrack.trail.Trail;
import com.github.markusbear.trailtrack.trail.TrailRepository;
import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import org.springframework.transaction.annotation.Transactional;

/**
 * Runs against the real database with a trail made for the test; each test's
 * changes are rolled back.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@DisplayName("Condition reports, end to end")
class ReportFlowIntegrationTest {

    @Autowired
    private MockMvcTester mvc;

    @Autowired
    private TrailRepository trailRepository;

    @Autowired
    private ConditionReportRepository reportRepository;

    private long trailId;
    private String token;

    @BeforeEach
    void setUp() throws Exception {
        Trail trail = new Trail();
        trail.setSourceTrailId(-1);
        trail.setName("Report Test Loop");
        trailId = trailRepository.save(trail).getId();

        MvcTestResult registered = mvc.post().uri("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"displayName": "Report Tester", "email": "report-flow-test@example.com",
                         "password": "correct horse"}
                        """)
                .exchange();
        token = JsonPath.read(registered.getResponse().getContentAsString(), "$.accessToken");
    }

    private MvcTestResult report(long trail, UUID clientRef) {
        return mvc.post().uri("/api/trails/{id}/reports", trail)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"conditionType": "FALLEN_TREE", "severity": "HIGH", "clientRef": "%s"}
                        """.formatted(clientRef))
                .exchange();
    }

    @Test
    @DisplayName("a logged-in hiker's report is stored once, even when the app sends it twice")
    void reportIsStoredOnce() throws Exception {
        UUID clientRef = UUID.randomUUID();

        MvcTestResult first = report(trailId, clientRef);
        MvcTestResult retry = report(trailId, clientRef);

        assertThat(first).hasStatus(201);
        assertThat(retry).hasStatusOk();
        Integer firstId = JsonPath.read(first.getResponse().getContentAsString(), "$.id");
        Integer retryId = JsonPath.read(retry.getResponse().getContentAsString(), "$.id");
        assertThat(retryId).isEqualTo(firstId);
        assertThat(reportRepository.findByClientRef(clientRef)).get()
                .satisfies(stored -> {
                    assertThat(stored.getTrail().getId()).isEqualTo(trailId);
                    assertThat(stored.getUser().getEmail()).isEqualTo("report-flow-test@example.com");
                    assertThat(stored.getStatus()).isEqualTo(ReportStatus.OPEN);
                });
    }

    @Test
    @DisplayName("a report for a trail that does not exist returns 404")
    void unknownTrailReturnsNotFound() {
        assertThat(report(Long.MAX_VALUE, UUID.randomUUID())).hasStatus(404);
    }
}
