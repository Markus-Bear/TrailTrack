package com.github.markusbear.trailtrack.auth;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponseException;

/**
 * Thrown when a login's email or password is wrong. The same message is used
 * for both, so login cannot reveal which emails have accounts. Returned to
 * the client as 401 Unauthorized.
 */
public class InvalidCredentialsException extends ErrorResponseException {

    public InvalidCredentialsException() {
        super(HttpStatus.UNAUTHORIZED,
                ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, "Email or password is incorrect"),
                null);
    }
}
