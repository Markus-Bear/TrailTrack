package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.github.markusbear.trailtrack.report.ConditionType;
import com.github.markusbear.trailtrack.report.ReportResponse;
import com.github.markusbear.trailtrack.report.ReportStatus;
import com.github.markusbear.trailtrack.report.Severity;
import com.github.markusbear.trailtrack.security.WithApiSecurity;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;

@WebMvcTest(TrailController.class)
@WithApiSecurity
@DisplayName("TrailController")
class TrailControllerTest {

    @Autowired
    private MockMvcTester mvc;

    @MockitoBean
    private TrailService trailService;

    @MockitoBean
    private TrailDetailService trailDetailService;

    @MockitoBean
    private TrailSearchService trailSearchService;

    @Test
    @DisplayName("GET /api/trails works without logging in and returns GeoJSON with the geometry as an object")
    void getTrailsReturnsGeoJsonWithGeometryAsAnObject() {
        when(trailService.getTrailSummaries()).thenReturn(TrailFeatureCollection.of(List.of(
                new TrailFeatureCollection.Feature("Feature", 7L,
                        "{\"type\":\"MultiLineString\",\"coordinates\":[[[-7.5,53.1],[-7.6,53.2]]]}",
                        new TrailFeatureCollection.Properties("Waterfall Loop", "Easy", 2.0, "blue",
                                "site-0", "Glenbarrow", List.of(-7.45, 53.12))))));

        var response = mvc.get().uri("/api/trails").exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.type").isEqualTo("FeatureCollection");
        assertThat(response).bodyJson().extractingPath("$.features[0].id").isEqualTo(7);
        assertThat(response).bodyJson().extractingPath("$.features[0].geometry.type")
                .isEqualTo("MultiLineString");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.name")
                .isEqualTo("Waterfall Loop");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.waymarkColour")
                .isEqualTo("blue");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.siteName")
                .isEqualTo("Glenbarrow");
        assertThat(response).bodyJson().extractingPath("$.features[0].properties.trailhead[0]")
                .isEqualTo(-7.45);
    }

    @Test
    @DisplayName("GET /api/trails/{id} works without logging in and returns the trail with its reports")
    void getTrailReturnsDetail() {
        ReportResponse mud = new ReportResponse(3L, 9L, ConditionType.MUD, Severity.MODERATE, "Muddy steps",
                ReportStatus.OPEN, Instant.parse("2026-10-23T07:40:00Z"));
        when(trailDetailService.getTrailDetail(9L)).thenReturn(new TrailDetailResponse(9L,
                "Glenbarrow - Waterfall Loop", "Moderate", null, "Looped Walk", 3.0, "1 hour", "By the river",
                null, "blue", List.of(mud), List.of(mud)));

        var response = mvc.get().uri("/api/trails/9").exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$.name").isEqualTo("Glenbarrow - Waterfall Loop");
        assertThat(response).bodyJson().extractingPath("$.recentReports[0].conditionType").isEqualTo("MUD");
        assertThat(response).bodyJson().doesNotHavePath("$.recentReports[0].user");
    }

    @Test
    @DisplayName("GET /api/trails/{id} returns 404 for a trail that does not exist")
    void getTrailReturnsNotFound() {
        when(trailDetailService.getTrailDetail(999L)).thenThrow(new TrailNotFoundException(999L));

        assertThat(mvc.get().uri("/api/trails/999")).hasStatus(404);
    }

    @Test
    @DisplayName("GET /api/trails/search works without logging in and passes on the search")
    void searchReturnsResults() {
        when(trailSearchService.search("glen", 53.15, -7.44, 10.0)).thenReturn(List.of(
                new TrailSearchResult(9L, "Glenbarrow - Waterfall Loop", "Moderate", 3.0, "blue", 1.2, null)));

        var response = mvc.get().uri("/api/trails/search?q=glen&lat=53.15&lon=-7.44&radiusKm=10").exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$[0].name").isEqualTo("Glenbarrow - Waterfall Loop");
        assertThat(response).bodyJson().extractingPath("$[0].distanceKm").isEqualTo(1.2);
    }
}
