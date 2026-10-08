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
                           String getWaymarking, Double getTrailheadLon, Double getTrailheadLat,
                           Integer getSiteId, String getGeometry) implements TrailSummary {
    }

    private static Summary summary(long id, String name, String waymarking, Integer siteId) {
        return new Summary(id, name, "Moderate", 2.0, waymarking, -7.1271, 53.0035, siteId,
                "{\"type\":\"MultiLineString\"}");
    }

    private static TrailFeatureCollection serve(Summary... summaries) {
        TrailRepository repository = mock(TrailRepository.class);
        when(repository.findAllSummaries(TrailService.DISPLAY_TOLERANCE_DEGREES, TrailService.SITE_RADIUS_METRES))
                .thenReturn(List.of(summaries));
        return new TrailService(repository).getTrailSummaries();
    }

    @Test
    @DisplayName("maps each trail summary to a GeoJSON feature")
    void mapsEachSummaryToAFeature() {
        TrailFeatureCollection result = serve(
                summary(1, "Glenbarrow - Eco Walk", "White arrow on red background", 0));

        assertThat(result.type()).isEqualTo("FeatureCollection");
        assertThat(result.features()).singleElement().satisfies(f -> {
            assertThat(f.type()).isEqualTo("Feature");
            assertThat(f.id()).isEqualTo(1L);
            assertThat(f.properties().name()).isEqualTo("Glenbarrow - Eco Walk");
            assertThat(f.properties().difficulty()).isEqualTo("Moderate");
            assertThat(f.properties().waymarkColour()).isEqualTo("red");
            assertThat(f.properties().trailhead()).containsExactly(-7.1271, 53.0035);
            assertThat(f.geometry()).isEqualTo("{\"type\":\"MultiLineString\"}");
        });
    }

    @Test
    @DisplayName("trails sharing a trailhead get the same site, named after their common prefix")
    void trailsSharingATrailheadGetTheSameSiteNamedAfterTheirCommonPrefix() {
        TrailFeatureCollection result = serve(
                summary(1, "Oughaval Woods - Beech Way Walk", null, 3),
                summary(2, "Oughaval Woods - Mass Rock Walk", null, 3),
                summary(3, "Slieve Bloom Way", null, 4));

        var props = result.features().stream().map(TrailFeatureCollection.Feature::properties).toList();
        assertThat(props.get(0).siteId()).isEqualTo(props.get(1).siteId()).isNotEqualTo(props.get(2).siteId());
        assertThat(props.get(0).siteName()).isEqualTo("Oughaval Woods");
        assertThat(props.get(2).siteName()).isEqualTo("Slieve Bloom Way");
    }

    @Test
    @DisplayName("a trail without a trailhead is a site of its own")
    void aTrailWithoutATrailheadIsItsOwnSite() {
        TrailFeatureCollection result = serve(
                summary(1, "Walk A", null, null),
                summary(2, "Walk B", null, null));

        assertThat(result.features().get(0).properties().siteId())
                .isNotEqualTo(result.features().get(1).properties().siteId());
    }

    @Test
    @DisplayName("site name is the words all trail names start with, or the first name if none")
    void siteNameUsesTheWordsAllNamesStartWith() {
        assertThat(TrailService.siteName(List.of("Durrow Leafy Loop Short", "Durrow Leafy Loop Long")))
                .isEqualTo("Durrow Leafy Loop");
        assertThat(TrailService.siteName(List.of(
                "Granstown Wood and Lake Nature Reserve Lake Trail",
                "Granstown Wood and Lake Nature Reserve Woodland Trail")))
                .isEqualTo("Granstown Wood and Lake Nature Reserve");
        assertThat(TrailService.siteName(List.of("Alpha Walk", "Beta Walk"))).isEqualTo("Alpha Walk");
    }
}
