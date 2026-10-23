package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.report.ConditionReportRepository;
import com.github.markusbear.trailtrack.report.ConditionType;
import com.github.markusbear.trailtrack.report.ReportResponse;
import com.github.markusbear.trailtrack.report.ReportStatus;
import com.github.markusbear.trailtrack.report.Severity;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("TrailDetailService")
class TrailDetailServiceTest {

    private static ReportResponse report(long id, ConditionType type, String time) {
        return new ReportResponse(id, 9L, type, type == ConditionType.CLEAR ? null : Severity.LOW, null,
                ReportStatus.OPEN, Instant.parse(time));
    }

    @Test
    @DisplayName("current conditions are the newest report of each condition type")
    void currentConditionsAreNewestPerType() {
        List<ReportResponse> newestFirst = List.of(
                report(4, ConditionType.MUD, "2026-10-23T10:00:00Z"),
                report(3, ConditionType.FALLEN_TREE, "2026-10-22T10:00:00Z"),
                report(2, ConditionType.MUD, "2026-10-21T10:00:00Z"));

        assertThat(TrailDetailService.currentConditions(newestFirst)).extracting(ReportResponse::id)
                .containsExactly(4L, 3L);
    }

    @Test
    @DisplayName("a CLEAR report replaces the conditions reported before it")
    void clearReplacesOlderConditions() {
        List<ReportResponse> newestFirst = List.of(
                report(4, ConditionType.MUD, "2026-10-23T10:00:00Z"),
                report(3, ConditionType.CLEAR, "2026-10-22T10:00:00Z"),
                report(2, ConditionType.FLOODING, "2026-10-21T10:00:00Z"));

        assertThat(TrailDetailService.currentConditions(newestFirst)).extracting(ReportResponse::id)
                .containsExactly(4L, 3L);
    }

    @Test
    @DisplayName("returns the trail's details with its waymark colour")
    void returnsTrailDetails() {
        TrailRepository trails = mock(TrailRepository.class);
        ConditionReportRepository reports = mock(ConditionReportRepository.class);
        Trail trail = new Trail();
        trail.setId(9L);
        trail.setName("Glenbarrow - Waterfall Loop");
        trail.setDifficulty("Moderate");
        trail.setWaymarking("Blue arrow on white background");
        when(trails.findById(9L)).thenReturn(Optional.of(trail));
        when(reports.findRecentForTrail(eq(9L), any(), eq(ReportStatus.REMOVED), any())).thenReturn(List.of());

        TrailDetailResponse detail = new TrailDetailService(trails, reports).getTrailDetail(9L);

        assertThat(detail.name()).isEqualTo("Glenbarrow - Waterfall Loop");
        assertThat(detail.waymarkColour()).isEqualTo("blue");
        assertThat(detail.recentReports()).isEmpty();
        assertThat(detail.currentConditions()).isEmpty();
    }

    @Test
    @DisplayName("an unknown trail is rejected")
    void unknownTrailIsRejected() {
        TrailRepository trails = mock(TrailRepository.class);
        when(trails.findById(anyLong())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> new TrailDetailService(trails, mock(ConditionReportRepository.class))
                .getTrailDetail(999L))
                .isInstanceOf(TrailNotFoundException.class);
    }
}
