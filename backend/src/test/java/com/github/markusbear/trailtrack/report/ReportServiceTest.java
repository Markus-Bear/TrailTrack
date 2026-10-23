package com.github.markusbear.trailtrack.report;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.trail.Trail;
import com.github.markusbear.trailtrack.trail.TrailNotFoundException;
import com.github.markusbear.trailtrack.trail.TrailRepository;
import com.github.markusbear.trailtrack.user.User;
import com.github.markusbear.trailtrack.user.UserRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.web.ErrorResponseException;

@DisplayName("ReportService")
class ReportServiceTest {

    private static final UUID CLIENT_REF = UUID.fromString("6f1c2b1e-8a43-4f4e-9d61-2c3b1a5e7f90");

    private ConditionReportRepository reportRepository;
    private TrailRepository trailRepository;
    private UserRepository userRepository;
    private ReportService service;
    private Trail trail;
    private User hiker;

    @BeforeEach
    void setUp() {
        reportRepository = mock(ConditionReportRepository.class);
        trailRepository = mock(TrailRepository.class);
        userRepository = mock(UserRepository.class);
        service = new ReportService(reportRepository, trailRepository, userRepository);

        trail = new Trail();
        trail.setId(12L);
        hiker = new User();
        hiker.setId(5L);
        when(trailRepository.findById(12L)).thenReturn(Optional.of(trail));
        when(userRepository.findById(5L)).thenReturn(Optional.of(hiker));
        when(reportRepository.findByClientRef(any())).thenReturn(Optional.empty());
        when(reportRepository.save(any())).thenAnswer(call -> {
            ConditionReport saved = call.getArgument(0);
            saved.setId(99L);
            return saved;
        });
    }

    private ConditionReport stored(User owner) {
        ConditionReport report = new ConditionReport();
        report.setId(99L);
        report.setTrail(trail);
        report.setUser(owner);
        report.setConditionType(ConditionType.MUD);
        report.setSeverity(Severity.MODERATE);
        report.setStatus(ReportStatus.OPEN);
        report.setReportedAt(Instant.now());
        report.setClientRef(CLIENT_REF);
        return report;
    }

    @Test
    @DisplayName("stores a new report as OPEN against the trail and the user")
    void storesNewReport() {
        ReportService.SubmitResult result = service.submit(12L, 5L,
                new SubmitReportRequest(ConditionType.MUD, Severity.HIGH, "  Deep mud by the bridge ", CLIENT_REF));

        assertThat(result.created()).isTrue();
        assertThat(result.report().trailId()).isEqualTo(12L);
        assertThat(result.report().status()).isEqualTo(ReportStatus.OPEN);
        assertThat(result.report().severity()).isEqualTo(Severity.HIGH);
        assertThat(result.report().note()).isEqualTo("Deep mud by the bridge");
        assertThat(result.report().reportedAt()).isNotNull();

        ArgumentCaptor<ConditionReport> saved = ArgumentCaptor.forClass(ConditionReport.class);
        verify(reportRepository).save(saved.capture());
        assertThat(saved.getValue().getUser()).isSameAs(hiker);
        assertThat(saved.getValue().getClientRef()).isEqualTo(CLIENT_REF);
    }

    @Test
    @DisplayName("a CLEAR report is stored without a severity")
    void clearReportHasNoSeverity() {
        ReportService.SubmitResult result = service.submit(12L, 5L,
                new SubmitReportRequest(ConditionType.CLEAR, Severity.HIGH, null, CLIENT_REF));

        assertThat(result.report().severity()).isNull();
    }

    @Test
    @DisplayName("a retry with the same clientRef returns the stored report instead of saving a copy")
    void retryReturnsStoredReport() {
        when(reportRepository.findByClientRef(CLIENT_REF)).thenReturn(Optional.of(stored(hiker)));

        ReportService.SubmitResult result = service.submit(12L, 5L,
                new SubmitReportRequest(ConditionType.MUD, Severity.MODERATE, null, CLIENT_REF));

        assertThat(result.created()).isFalse();
        assertThat(result.report().id()).isEqualTo(99L);
        verify(reportRepository, never()).save(any());
    }

    @Test
    @DisplayName("a clientRef already used by another user is rejected with 409")
    void clientRefOfAnotherUserIsRejected() {
        User someoneElse = new User();
        someoneElse.setId(6L);
        when(reportRepository.findByClientRef(CLIENT_REF)).thenReturn(Optional.of(stored(someoneElse)));

        assertThatThrownBy(() -> service.submit(12L, 5L,
                new SubmitReportRequest(ConditionType.MUD, Severity.MODERATE, null, CLIENT_REF)))
                .isInstanceOfSatisfying(ErrorResponseException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(409));
    }

    @Test
    @DisplayName("a report for an unknown trail is rejected")
    void unknownTrailIsRejected() {
        when(trailRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.submit(404L, 5L,
                new SubmitReportRequest(ConditionType.MUD, Severity.MODERATE, null, CLIENT_REF)))
                .isInstanceOf(TrailNotFoundException.class);
        verify(reportRepository, never()).save(any());
    }
}
