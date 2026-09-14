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

    /// Enum, nao o literal 'ADMIN': esta contagem alimenta a trava do ultimo
    /// admin E o portao do bootstrap. Num rename do enum o literal ficaria pra
    /// tras, a query voltaria 0 e todo cadastro com o e-mail de bootstrap
    /// viraria admin pra sempre.
    @Query("SELECT COUNT(u) FROM User u WHERE u.role = com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN")
    long countAdmins();

    /// Serializa quem mexe em papel de admin. Sem isto, duas transacoes que
    /// rebaixam admins diferentes leem a mesma contagem, as duas passam pela
    /// trava do ultimo admin, e o sistema fica sem administrador nenhum -- cuja
    /// unica recuperacao seria editar o banco a mao. Lock consultivo em vez de
    /// FOR UPDATE porque a trava protege um AGREGADO (quantos admins existem),
    /// nao uma linha especifica.
    @Query(value = "SELECT pg_advisory_xact_lock(2609121)", nativeQuery = true)
    void lockAdminRoleChanges();

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

    java.util.Optional<com.smartboarding.smartboarding_api.domain.user.entity.User> findByGoogleId(String googleId);
}
