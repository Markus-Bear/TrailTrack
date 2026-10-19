package com.github.markusbear.trailtrack.auth;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponseException;

/**
 * Thrown when registering with an email that already has an account.
 * Returned to the client as 409 Conflict.
 */
public class EmailAlreadyRegisteredException extends ErrorResponseException {

    public EmailAlreadyRegisteredException() {
        super(HttpStatus.CONFLICT,
                ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "An account with this email already exists"),
                null);
    }
}
