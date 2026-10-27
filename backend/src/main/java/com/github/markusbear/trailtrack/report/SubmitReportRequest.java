package com.github.markusbear.trailtrack.report;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Body of a condition report.
 *
 * @param conditionType what the hiker found
 * @param severity how bad it is; required unless the condition is CLEAR
 * @param note optional extra detail, up to 500 characters
 * @param clientRef a UUID the app creates once per report
 */
public record SubmitReportRequest(
        @NotNull(message = "Condition type is required")
        ConditionType conditionType,

        Severity severity,

        @Size(max = 500, message = "Note must be at most 500 characters")
        String note,

        @NotNull(message = "Client reference is required")
        UUID clientRef) {

    /** Clear reports have no severity; every other condition needs one. */
    @AssertTrue(message = "Severity is required unless the trail is clear")
    public boolean isSeverityGivenUnlessClear() {
        return conditionType == null || conditionType == ConditionType.CLEAR || severity != null;
    }
}
