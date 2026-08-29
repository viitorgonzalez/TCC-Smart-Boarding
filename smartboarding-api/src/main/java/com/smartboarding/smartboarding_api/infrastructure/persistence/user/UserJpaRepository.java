package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserJpaRepository extends JpaRepository<User, UUID> {

    @Query("SELECT COUNT(u) FROM User u WHERE u.role = com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT AND u.isActive = true")
    long countActiveStudents();

    long countByInstitutionId(UUID institutionId);

    @Query("""
            SELECT u FROM User u
            WHERE u.institutionId IN (
                SELECT i.id FROM Institution i WHERE i.routeId = :routeId
            )
            ORDER BY u.fullName
            """)
    List<User> findByRouteId(@Param("routeId") UUID routeId);
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
