package com.smartboarding.smartboarding_api.application.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InstitutionUseCaseImplTest {

    @Mock
    InstitutionRepositoryPort repository;

    @Test
    void criaInstituicaoEDelegaPraORepositorio() {
        var useCase = new InstitutionUseCaseImpl(repository);
        var institution = Institution.builder().name("Unifor — Campus Central").build();
        when(repository.save(institution)).thenReturn(institution);

        var result = useCase.execute(institution);

        assertThat(result.getName()).isEqualTo("Unifor — Campus Central");
    }

    @Test
    void listaTodasAsInstituicoes() {
        var useCase = new InstitutionUseCaseImpl(repository);
        var institution = Institution.builder().name("Unifor — Campus Central").build();
        when(repository.findAll()).thenReturn(List.of(institution));

        var result = useCase.findAll();

        assertThat(result).hasSize(1);
    }
}
