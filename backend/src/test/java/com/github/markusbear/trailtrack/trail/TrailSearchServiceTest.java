package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.report.ConditionReport;
import com.github.markusbear.trailtrack.report.ConditionReportRepository;
import com.github.markusbear.trailtrack.report.ConditionType;
import com.github.markusbear.trailtrack.report.ReportStatus;
import com.github.markusbear.trailtrack.report.Severity;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

@DisplayName("TrailSearchService")
class TrailSearchServiceTest {

    private record Row(Long getId, String getName, String getDifficulty, Double getLengthKm, String getWaymarking,
                       Double getDistanceMetres) implements TrailSearchRow {
    }

    private TrailRepository trails;
    private ConditionReportRepository reports;
    private TrailSearchService service;

    @BeforeEach
    void setUp() {
        trails = mock(TrailRepository.class);
        reports = mock(ConditionReportRepository.class);
        service = new TrailSearchService(trails, reports);
    }

    @Test
    @DisplayName("search text matches anywhere in a name, with LIKE wildcards treated literally")
    void likePatternEscapesWildcards() {
        assertThat(TrailSearchService.likePattern(" glen ")).isEqualTo("%glen%");
        assertThat(TrailSearchService.likePattern("100%_x")).isEqualTo("%100\\%\\_x%");
        assertThat(TrailSearchService.likePattern(null)).isEqualTo("%");
        assertThat(TrailSearchService.likePattern("  ")).isEqualTo("%");
    }

    @Test
    @DisplayName("a name-only search lists trails A to Z with no distance")
    void nameOnlySearch() {
        when(trails.searchByName("%glen%")).thenReturn(List.of(
                new Row(9L, "Glenbarrow - Waterfall Loop", "Moderate", 3.0, "Blue arrow on white background", null)));
        when(reports.findRecentForTrails(any(), any(), any())).thenReturn(List.of());

        List<TrailSearchResult> results = service.search("glen", null, null, null);

        assertThat(results).singleElement().satisfies(r -> {
            assertThat(r.name()).isEqualTo("Glenbarrow - Waterfall Loop");
            assertThat(r.waymarkColour()).isEqualTo("blue");
            assertThat(r.distanceKm()).isNull();
            assertThat(r.latestReport()).isNull();
        });
        verify(trails, never()).searchNear(any(Double.class), any(Double.class), any(Double.class), anyString());
    }

    @Test
    @DisplayName("a search near a position uses the radius in metres and returns distances in kilometres")
    void nearSearch() {
        when(trails.searchNear(-7.44, 53.15, 5000, "%")).thenReturn(List.of(
                new Row(9L, "Glenbarrow - Waterfall Loop", "Moderate", 3.0, null, 1234.0)));
        when(reports.findRecentForTrails(any(), any(), any())).thenReturn(List.of());

        List<TrailSearchResult> results = service.search(null, 53.15, -7.44, 5.0);

        assertThat(results.getFirst().distanceKm()).isEqualTo(1.234);
    }

    @Test
    @DisplayName("each result carries its trail's newest report")
    void attachesLatestReport() {
        Trail trail = new Trail();
        trail.setId(9L);
        ConditionReport mud = new ConditionReport();
        mud.setId(3L);
        mud.setTrail(trail);
        mud.setConditionType(ConditionType.MUD);
        mud.setSeverity(Severity.HIGH);
        mud.setStatus(ReportStatus.OPEN);
        mud.setReportedAt(Instant.now());
        when(trails.searchByName("%")).thenReturn(List.of(
                new Row(9L, "Glenbarrow - Waterfall Loop", "Moderate", 3.0, null, null),
                new Row(10L, "Glenbarrow - Eco Walk", "Easy", 2.0, null, null)));
        when(reports.findRecentForTrails(eq(List.of(9L, 10L)), any(), eq(ReportStatus.REMOVED)))
                .thenReturn(List.of(mud));

        List<TrailSearchResult> results = service.search(null, null, null, null);

        assertThat(results.get(0).latestReport().conditionType()).isEqualTo(ConditionType.MUD);
        assertThat(results.get(1).latestReport()).isNull();
    }

    @Test
    @DisplayName("lat without lon, a position out of range, or a bad radius is rejected with 400")
    void rejectsBadParameters() {
        assertThatThrownBy(() -> service.search(null, 53.0, null, null))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode().value()).isEqualTo(400));
        assertThatThrownBy(() -> service.search(null, 95.0, -7.0, null))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> service.search(null, 53.0, -7.0, 0.0))
                .isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> service.search(null, 53.0, -7.0, 500.0))
                .isInstanceOf(ResponseStatusException.class);
    }
}
