package com.github.markusbear.trailtrack.trail;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.transaction.annotation.Transactional;

/**
 * Runs the PostGIS queries against the real database, with test trails off
 * the Cork coast, far from the imported Laois trails. Each test's changes are
 * rolled back.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@DisplayName("Trail search, end to end")
class TrailSearchIntegrationTest {

    private static final GeometryFactory WGS84 = new GeometryFactory(new PrecisionModel(), 4326);
    private static final String HERE = "lat=51.6&lon=-8.5";

    @Autowired
    private MockMvcTester mvc;

    @Autowired
    private TrailRepository trailRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private void trail(int sourceId, String name, double lon1, double lat1, double lon2, double lat2) {
        LineString line = WGS84.createLineString(
                new Coordinate[] {new Coordinate(lon1, lat1), new Coordinate(lon2, lat2)});
        MultiLineString geom = WGS84.createMultiLineString(new LineString[] {line});
        Trail trail = new Trail();
        trail.setSourceTrailId(sourceId);
        trail.setName(name);
        trail.setDifficulty("Easy");
        trail.setGeom(geom);
        trailRepository.saveAndFlush(trail);
    }

    @BeforeEach
    void setUp() {
        // About 0.7 km and 27 km east of the searcher at 51.6, -8.5.
        trail(-11, "Search Test Near Loop", -8.49, 51.6, -8.48, 51.61);
        trail(-12, "Search Test Far Walk", -8.10, 51.6, -8.09, 51.61);
    }

    @Test
    @DisplayName("near me lists only trails inside the radius, with their distance")
    void nearMeRespectsRadius() {
        var response = mvc.get().uri("/api/trails/search?" + HERE + "&radiusKm=10").exchange();

        assertThat(response).hasStatusOk();
        assertThat(response).bodyJson().extractingPath("$[*].name").asArray()
                .containsExactly("Search Test Near Loop");
        assertThat(response).bodyJson().extractingPath("$[0].distanceKm").asNumber().satisfies(
                km -> assertThat(km.doubleValue()).isBetween(0.6, 0.8));
    }

    @Test
    @DisplayName("a wider radius finds more trails, nearest first")
    void widerRadiusNearestFirst() {
        var response = mvc.get().uri("/api/trails/search?" + HERE + "&radiusKm=50").exchange();

        assertThat(response).bodyJson().extractingPath("$[*].name").asArray()
                .containsExactly("Search Test Near Loop", "Search Test Far Walk");
    }

    @Test
    @DisplayName("name search ignores case and can be combined with near me")
    void nameSearchIgnoresCase() {
        assertThat(mvc.get().uri("/api/trails/search?q={q}", "far WALK").exchange()).bodyJson()
                .extractingPath("$[*].name").asArray().containsExactly("Search Test Far Walk");
        assertThat(mvc.get().uri("/api/trails/search?q=far&" + HERE + "&radiusKm=10").exchange()).bodyJson()
                .extractingPath("$").asArray().isEmpty();
    }

    @Test
    @DisplayName("only one of lat and lon returns 400")
    void halfAPositionIsRejected() {
        assertThat(mvc.get().uri("/api/trails/search?lat=51.6").exchange()).hasStatus(400);
    }

    @Test
    @DisplayName("the spatial index for distance searches exists")
    void spatialIndexExists() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM pg_indexes WHERE indexname = 'idx_trails_geom_geography'", Integer.class);
        assertThat(count).isEqualTo(1);
    }
}
