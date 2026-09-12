package com.smartboarding.smartboarding_api.infrastructure.persistence.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UserInstitutionJpaRepository extends JpaRepository<UserInstitution, UUID> {
    /// Ordem fixa: a PRIMEIRA da lista vira a instituicao principal do aluno
    /// (users.institution_id) e e a estrela na tela. Sem ORDER BY o Postgres
    /// devolve na ordem que quiser -- e ela muda depois de update ou vacuum,
    /// movendo o aluno de contagem sozinho.
    List<UserInstitution> findAllByUserIdOrderByCreatedAtAscIdAsc(UUID userId);

    boolean existsByUserIdAndInstitutionId(UUID userId, UUID institutionId);

    void deleteByUserIdAndInstitutionId(UUID userId, UUID institutionId);
}
