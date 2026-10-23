package com.github.markusbear.trailtrack.trail;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponseException;

/**
 * Thrown when a request names a trail that does not exist. Returned to the
 * client as 404 Not Found.
 */
public class TrailNotFoundException extends ErrorResponseException {

    public TrailNotFoundException(long trailId) {
        super(HttpStatus.NOT_FOUND,
                ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "No trail with id " + trailId),
                null);
    }
}
