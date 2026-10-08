package com.github.markusbear.trailtrack.trail;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.geojson.GeoJsonReader;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;
import java.util.HashMap;
import java.util.Map;

/**
 * Imports trails from the Sport Ireland National Trails Register into the
 * trails table.
 *
 * Downloads trails and their official start points (trailheads) from the
 * register's ArcGIS feature services, creates a trail for each TrailID not
 * seen before, and updates trails that already exist.
 */
@Service
public class TrailImportService {

    private static final int SRID = 4326;
    private static final GeometryFactory GEOMETRY_FACTORY = new GeometryFactory(new PrecisionModel(), SRID);

    private final RestClient restClient;
    private final TrailRepository trailRepository;
    private final ObjectMapper objectMapper;
    private final GeoJsonReader geoJsonReader = new GeoJsonReader();
    private final String trailRoutesUrl;
    private final String trailheadsUrl;

    public TrailImportService(
            TrailRepository trailRepository,
            ObjectMapper objectMapper,
            @Value("${trailtrack.import.trail-routes-url}") String trailRoutesUrl,
            @Value("${trailtrack.import.trailheads-url}") String trailheadsUrl) {
        this.restClient = RestClient.create();
        this.trailRepository = trailRepository;
        this.objectMapper = objectMapper;
        this.trailRoutesUrl = trailRoutesUrl;
        this.trailheadsUrl = trailheadsUrl;
    }

    /**
     * Imports every trail in County Laois, including trails that cross into
     * neighbouring counties.
     *
     * Runs as a single transaction: if any trail fails to import, no changes
     * are saved.
     *
     * @return the number of trails created and updated
     * @throws TrailImportException if the response cannot be parsed or a
     *         trail has an unsupported geometry type
     * @throws org.springframework.web.client.RestClientException if the
     *         register cannot be reached
     */
    @Transactional
    public TrailImportResult importLaoisTrails() {
        String uri = UriComponentsBuilder.fromUriString(trailRoutesUrl)
                // County lists every county a trail crosses (e.g. "Laois, Offaly"),
                // so an exact match would drop cross-county trails.
                .queryParam("where", "County LIKE '%Laois%'")
                .queryParam("outFields", "TrailID,Name,County,Difficulty,Grade,TrailType,LengthKm,TimeToComplete,Description,Website,WaymarkingDescription")
                // The service defaults to Irish Grid coordinates; request WGS84 instead.
                .queryParam("outSR", SRID)
                .queryParam("f", "geojson")
                .build()
                .toUriString();

        String responseBody = restClient.get().uri(uri).retrieve().body(String.class);

        int created = 0;
        int updated = 0;

        try {
            Map<Integer, Point> trailheads = fetchTrailheads();
            JsonNode root = objectMapper.readTree(responseBody);
            for (JsonNode feature : root.get("features")) {
                JsonNode properties = feature.get("properties");
                Integer sourceTrailId = properties.get("TrailID").asInt();

                Trail trail = trailRepository.findBySourceTrailId(sourceTrailId).orElse(null);
                boolean isNew = trail == null;
                if (isNew) {
                    trail = new Trail();
                    trail.setSourceTrailId(sourceTrailId);
                }

                applyProperties(trail, properties);
                MultiLineString geom = readGeometry(feature.get("geometry"));
                trail.setGeom(geom);
                trail.setTrailhead(trailheads.getOrDefault(sourceTrailId, startOf(geom)));
                trailRepository.save(trail);

                if (isNew) {
                    created++;
                } else {
                    updated++;
                }
            }
        } catch (Exception e) {
            throw new TrailImportException("Failed to parse trail import response", e);
        }

        return new TrailImportResult(created, updated);
    }

    /**
     * Fetches the official start point of each Laois route from the register's
     * trailheads service.
     *
     * @return start points keyed by the register's TrailID
     * @throws org.locationtech.jts.io.ParseException if a point is not valid GeoJSON
     */
    private Map<Integer, Point> fetchTrailheads() throws org.locationtech.jts.io.ParseException {
        String uri = UriComponentsBuilder.fromUriString(trailheadsUrl)
                .queryParam("where", "County LIKE '%Laois%' AND TrailHeadType = 'Start'")
                .queryParam("outFields", "TrailID")
                .queryParam("outSR", SRID)
                .queryParam("f", "geojson")
                .build()
                .toUriString();
        JsonNode root = objectMapper.readTree(restClient.get().uri(uri).retrieve().body(String.class));

        Map<Integer, Point> trailheads = new HashMap<>();
        for (JsonNode feature : root.get("features")) {
            Geometry point = geoJsonReader.read(feature.get("geometry").toString());
            if (point instanceof Point p) {
                p.setSRID(SRID);
                trailheads.putIfAbsent(feature.get("properties").get("TrailID").asInt(), p);
            }
        }
        return trailheads;
    }

    /**
     * Fallback trailhead for a route with no official one: its first point.
     *
     * @param geom the route
     * @return the route's first point
     */
    private Point startOf(MultiLineString geom) {
        Point start = GEOMETRY_FACTORY.createPoint(geom.getGeometryN(0).getCoordinates()[0]);
        start.setSRID(SRID);
        return start;
    }

    /**
     * Copies the register's attribute fields onto a trail.
     *
     * @param trail the trail to update
     * @param properties the feature's properties from the register
     */
    private void applyProperties(Trail trail, JsonNode properties) {
        trail.setName(textOrNull(properties, "Name"));
        trail.setCounty(textOrNull(properties, "County"));
        trail.setDifficulty(textOrNull(properties, "Difficulty"));
        trail.setGrade(textOrNull(properties, "Grade"));
        trail.setTrailType(textOrNull(properties, "TrailType"));
        trail.setTimeToComplete(textOrNull(properties, "TimeToComplete"));
        trail.setDescription(textOrNull(properties, "Description"));
        trail.setWebsite(textOrNull(properties, "Website"));
        trail.setWaymarking(textOrNull(properties, "WaymarkingDescription"));

        JsonNode lengthKm = properties.get("LengthKm");
        trail.setLengthKm(lengthKm != null && !lengthKm.isNull() ? lengthKm.asDouble() : null);
    }

    /**
     * @return the field's text, or null if the field is missing or null
     */
    private String textOrNull(JsonNode node, String field) {
        JsonNode value = node.get(field);
        return value != null && !value.isNull() ? value.asText() : null;
    }

    /**
     * Converts a GeoJSON geometry into a MultiLineString in SRID 4326.
     *
     * @param geometryNode the feature's GeoJSON geometry
     * @return the trail's route
     * @throws org.locationtech.jts.io.ParseException if the geometry is not valid GeoJSON
     * @throws TrailImportException if the geometry is not a line
     */
    private MultiLineString readGeometry(JsonNode geometryNode) throws org.locationtech.jts.io.ParseException {
        Geometry geometry = geoJsonReader.read(geometryNode.toString());
        geometry.setSRID(SRID);

        if (geometry instanceof MultiLineString multiLineString) {
            return multiLineString;
        }
        if (geometry instanceof LineString lineString) {
            // Single-section trails arrive as a LineString; wrap them so every
            // row has the same geometry type.
            MultiLineString wrapped = GEOMETRY_FACTORY.createMultiLineString(new LineString[] {lineString});
            wrapped.setSRID(SRID);
            return wrapped;
        }
        throw new TrailImportException("Unexpected geometry type for trail: " + geometry.getGeometryType(), null);
    }

    /**
     * Result of one import run.
     *
     * @param created number of trails added
     * @param updated number of existing trails updated
     */
    public record TrailImportResult(int created, int updated) {
    }

    /**
     * Thrown when trail data from the register cannot be imported.
     */
    public static class TrailImportException extends RuntimeException {
        public TrailImportException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
