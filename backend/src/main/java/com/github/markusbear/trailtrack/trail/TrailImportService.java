package com.github.markusbear.trailtrack.trail;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.geojson.GeoJsonReader;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * Imports trails from the Sport Ireland National Trails Register into the
 * trails table.
 *
 * Downloads trails as GeoJSON from the register's ArcGIS feature service,
 * creates a trail for each TrailID not seen before, and updates trails
 * that already exist.
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

    /**
     * @param trailRepository repository the imported trails are saved to
     * @param objectMapper JSON parser for the register's response
     * @param trailRoutesUrl query URL of the register's trail routes service
     */
    public TrailImportService(
            TrailRepository trailRepository,
            ObjectMapper objectMapper,
            @Value("${trailtrack.import.trail-routes-url}") String trailRoutesUrl) {
        this.restClient = RestClient.create();
        this.trailRepository = trailRepository;
        this.objectMapper = objectMapper;
        this.trailRoutesUrl = trailRoutesUrl;
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
                .queryParam("outFields", "TrailID,Name,County,Difficulty,Grade,TrailType,LengthKm,TimeToComplete,Description,Website")
                // The service defaults to Irish Grid coordinates; request WGS84 instead.
                .queryParam("outSR", SRID)
                .queryParam("f", "geojson")
                .build()
                .toUriString();

        String responseBody = restClient.get().uri(uri).retrieve().body(String.class);

        int created = 0;
        int updated = 0;

        try {
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
                trail.setGeom(readGeometry(feature.get("geometry")));
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

        JsonNode lengthKm = properties.get("LengthKm");
        trail.setLengthKm(lengthKm != null && !lengthKm.isNull() ? lengthKm.asDouble() : null);
    }

    /**
     * Returns a field's text value.
     *
     * @param node the JSON object to read from
     * @param field the field name
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
