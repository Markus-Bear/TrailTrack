package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;

import com.github.markusbear.trailtrack.report.ConditionReport;
import com.github.markusbear.trailtrack.report.ConditionReportRepository;
import com.github.markusbear.trailtrack.report.ConditionType;
import com.github.markusbear.trailtrack.report.ReportStatus;
import com.github.markusbear.trailtrack.report.Severity;
import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import com.github.markusbear.trailtrack.user.UserRole;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.transaction.annotation.Transactional;

/**
 * Runs against the real database with its own trail and reports; each test's
 * changes are rolled back.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@DisplayName("Trail detail, end to end")
class TrailDetailIntegrationTest {

    @Autowired
    private MockMvcTester mvc;

    @Autowired
    private TrailRepository trailRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ConditionReportRepository reportRepository;

    private void store(Trail trail, User user, ConditionType type, ReportStatus status, Duration age) {
        ConditionReport report = new ConditionReport();
        report.setTrail(trail);
        report.setUser(user);
        report.setConditionType(type);
        report.setSeverity(Severity.MODERATE);
        report.setStatus(status);
        report.setReportedAt(Instant.now().minus(age));
        report.setClientRef(UUID.randomUUID());
        reportRepository.save(report);
    }

    @Test
    @DisplayName("shows only reports from the last 7 days that have not been removed, newest first")
    void showsRecentVisibleReports() {
        Trail trail = new Trail();
        trail.setSourceTrailId(-2);
        trail.setName("Detail Test Loop");
        trail = trailRepository.save(trail);
        User user = new User();
        user.setEmail("detail-test@example.com");
        user.setPasswordHash("not-a-real-hash");
        user.setDisplayName("Detail Tester");
        user.setRole(UserRole.HIKER);
        user.setCreatedAt(Instant.now());
        user = userRepository.save(user);

        store(trail, user, ConditionType.MUD, ReportStatus.OPEN, Duration.ofDays(2));
        store(trail, user, ConditionType.FALLEN_TREE, ReportStatus.OPEN, Duration.ofHours(3));
        store(trail, user, ConditionType.FLOODING, ReportStatus.OPEN, Duration.ofDays(10));
        store(trail, user, ConditionType.LIVESTOCK, ReportStatus.REMOVED, Duration.ofHours(1));

        var response = mvc.get().uri("/api/trails/{id}", trail.getId()).exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.recentReports[*].conditionType")
                .asArray().containsExactly("FALLEN_TREE", "MUD");
    }
}
