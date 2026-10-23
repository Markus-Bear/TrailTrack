package com.github.markusbear.trailtrack.report;

import com.github.markusbear.trailtrack.trail.Trail;
import com.github.markusbear.trailtrack.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * A hiker's report of a trail's condition. Mapped to the condition_reports
 * table, indexed for reading a trail's most recent reports.
 */
@Entity
@Table(name = "condition_reports",
        indexes = @Index(name = "idx_condition_reports_trail_time", columnList = "trail_id, reported_at"))
@Getter
@Setter
@NoArgsConstructor
public class ConditionReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trail_id")
    private Trail trail;

    /** Who reported it. Never shown with the report. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ConditionType conditionType;

    /** Null for CLEAR reports. */
    @Enumerated(EnumType.STRING)
    @Column(length = 10)
    private Severity severity;

    @Column(length = 500)
    private String note;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ReportStatus status;

    @Column(nullable = false)
    private Instant reportedAt;

    /**
     * Created by the app for each report, so a submission retried after a
     * dropped connection is recognised and not stored twice.
     */
    @Column(nullable = false, unique = true)
    private UUID clientRef;
}
