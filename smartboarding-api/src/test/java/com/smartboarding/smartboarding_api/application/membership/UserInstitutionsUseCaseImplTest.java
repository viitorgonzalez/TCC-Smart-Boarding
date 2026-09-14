package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserInstitutionsUseCaseImplTest {

    private static final UUID ALUNO = UUID.randomUUID();
    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();

    @Mock UserInstitutionRepositoryPort repository;
    @Mock InstitutionRepositoryPort institutionRepository;
    @Mock UserRepositoryPort userRepository;

    private UserInstitutionsUseCaseImpl useCase;
    private User aluno;

    @BeforeEach
    void setUp() {
        useCase = new UserInstitutionsUseCaseImpl(repository, institutionRepository, userRepository);
        aluno = User.builder().id(ALUNO).email("fernanda@edu.unifor.br").build();
        when(userRepository.findById(ALUNO)).thenReturn(Optional.of(aluno));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(institutionRepository.findById(any())).thenReturn(
                Optional.of(Institution.builder().id(UNIFOR).name("UNIFOR-MG").build()));
        when(repository.existsByUserIdAndInstitutionId(any(), any())).thenReturn(false);
        when(repository.findAllByUserId(ALUNO)).thenReturn(List.of());
    }

    private void declaradas(UUID... ids) {
        when(repository.findAllByUserId(ALUNO)).thenReturn(
                java.util.Arrays.stream(ids)
                        .map(i -> UserInstitution.builder().userId(ALUNO).institutionId(i).build())
                        .toList());
    }

    @Test
    void alunoPodeDeclararMaisDeUmaInstituicao() {
        useCase.add(ALUNO, UNIFOR);
        declaradas(UNIFOR, IFMG);

        assertThat(useCase.institutionsOf(ALUNO)).containsExactly(UNIFOR, IFMG);
    }

    /// Declarar a mesma duas vezes duplicaria o aluno na contagem da lista.
    @Test
    void aMesmaInstituicaoNaoEDeclaradaDuasVezes() {
        when(repository.existsByUserIdAndInstitutionId(ALUNO, UNIFOR)).thenReturn(true);

        assertThatThrownBy(() -> useCase.add(ALUNO, UNIFOR))
                .isInstanceOf(ConflictException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void instituicaoInexistenteNaoEDeclarada() {
        when(institutionRepository.findById(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.add(ALUNO, UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    /// users.institution_id segue sendo a PRINCIPAL, usada pela contagem da
    /// lista. A primeira declarada assume.
    @Test
    void aPrimeiraDeclaradaViraAPrincipal() {
        declaradas(UNIFOR);

        useCase.add(ALUNO, UNIFOR);

        assertThat(aluno.getInstitutionId()).isEqualTo(UNIFOR);
    }

    /// Trocar a principal por outra que ele ja tinha bagunçaria a contagem sem
    /// motivo -- so muda se a atual saiu da lista.
    @Test
    void declararOutraNaoTrocaAPrincipal() {
        aluno.setInstitutionId(UNIFOR);
        declaradas(UNIFOR, IFMG);

        useCase.add(ALUNO, IFMG);

        assertThat(aluno.getInstitutionId()).isEqualTo(UNIFOR);
    }

    @Test
    void removerAPrincipalPromoveAQueSobrou() {
        aluno.setInstitutionId(UNIFOR);
        declaradas(IFMG);

        useCase.remove(ALUNO, UNIFOR);

        assertThat(aluno.getInstitutionId()).isEqualTo(IFMG);
    }

    /// Sem instituicao nenhuma o aluno perde o acesso a rota (o gate do join
    /// recusa), e o campo precisa refletir isso em vez de apontar pra um vinculo
    /// que nao existe mais.
    @Test
    void removerTodasLimpaAPrincipal() {
        aluno.setInstitutionId(UNIFOR);
        declaradas();

        useCase.remove(ALUNO, UNIFOR);

        assertThat(aluno.getInstitutionId()).isNull();
    }

    @Test
    void alunoSemDeclaracaoDevolveListaVazia() {
        assertThat(useCase.institutionsOf(ALUNO)).isEmpty();
    }
}
