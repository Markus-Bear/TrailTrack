package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("TrailService")
class TrailServiceTest {

    private record Summary(Long getId, String getName, String getDifficulty, Double getLengthKm,
                           String getWaymarking, String getGeometry) implements TrailSummary {
    }

    @Test
    @DisplayName("maps each trail summary to a GeoJSON feature")
    void getTrailSummariesMapsEachSummaryToAFeature() {
        TrailRepository repository = mock(TrailRepository.class);
        when(repository.findAllSummaries(TrailService.DISPLAY_TOLERANCE_DEGREES)).thenReturn(List.of(
                new Summary(1L, "Glenbarrow - Eco Walk", "Challenging", 8.5, "White arrow on red background",
                        "{\"type\":\"MultiLineString\"}")));

        TrailFeatureCollection result = new TrailService(repository).getTrailSummaries();

        assertThat(result.type()).isEqualTo("FeatureCollection");
        assertThat(result.features()).singleElement().satisfies(f -> {
            assertThat(f.type()).isEqualTo("Feature");
            assertThat(f.id()).isEqualTo(1L);
            assertThat(f.properties().name()).isEqualTo("Glenbarrow - Eco Walk");
            assertThat(f.properties().difficulty()).isEqualTo("Challenging");
            assertThat(f.properties().waymarkColour()).isEqualTo("red");
            assertThat(f.geometry()).isEqualTo("{\"type\":\"MultiLineString\"}");
        });
    }
}
