package com.github.markusbear.trailtrack.user;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Database access for User entities.
 */
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * @param email the email address, in lower case
     * @return the user with that email, or empty if there is none
     */
    Optional<User> findByEmail(String email);

    /**
     * @param email the email address, in lower case
     * @return whether an account already uses that email
     */
    boolean existsByEmail(String email);
}
