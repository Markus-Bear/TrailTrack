package com.github.markusbear.trailtrack.trail;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.locationtech.jts.geom.MultiLineString;

/**
 * A trail from the Sport Ireland National Trails Register, with its route
 * geometry. Mapped to the trails table.
 */
@Entity
@Table(name = "trails")
@Getter
@Setter
@NoArgsConstructor
public class Trail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The register's own TrailID, used to find this trail when importing again. */
    @Column(nullable = false, unique = true)
    private Integer sourceTrailId;

    @Column(nullable = false, columnDefinition = "text")
    private String name;

    private String county;
    private String difficulty;
    private String grade;
    private String trailType;
    private Double lengthKm;
    private String timeToComplete;

    @Column(columnDefinition = "text")
    private String description;

    @Column(columnDefinition = "text")
    private String website;

    /** The trail's route, in WGS84 latitude and longitude (SRID 4326). */
    @Column(columnDefinition = "geometry(MultiLineString,4326)")
    private MultiLineString geom;
}
