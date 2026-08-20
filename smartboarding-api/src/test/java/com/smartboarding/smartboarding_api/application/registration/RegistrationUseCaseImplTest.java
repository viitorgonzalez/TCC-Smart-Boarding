package com.smartboarding.smartboarding_api.application.registration;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RegistrationUseCaseImplTest {

    @Mock RegistrationRequestRepositoryPort registrationRepository;
    @Mock EmailPort emailPort;

    @Test
    void gerarConviteCriaPedidoComTokenEEnviaEmail() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null);
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.generateInvite("aluno@edu.unifor.br");

        ArgumentCaptor<RegistrationRequest> captor = ArgumentCaptor.forClass(RegistrationRequest.class);
        verify(registrationRepository).save(captor.capture());
        RegistrationRequest saved = captor.getValue();

        assertThat(saved.getEmail()).isEqualTo("aluno@edu.unifor.br");
        assertThat(saved.getStatus()).isEqualTo(RegistrationStatus.INVITED);
        assertThat(saved.getToken()).isNotBlank();
        assertThat(saved.getTokenExpiresAt()).isAfter(LocalDateTime.now().plusDays(6));
        verify(emailPort).send(eq("aluno@edu.unifor.br"), anyString(), contains(saved.getToken()));
    }

    @Test
    void validarTokenExpiradoLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null);
        var expired = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("abc")
                .tokenExpiresAt(LocalDateTime.now().minusDays(1))
                .status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findByToken("abc")).thenReturn(java.util.Optional.of(expired));

        assertThatThrownBy(() -> useCase.validateToken("abc"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);
    }

    @Test
    void validarTokenInexistenteLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null);
        when(registrationRepository.findByToken("xyz")).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> useCase.validateToken("xyz"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.NotFoundException.class);
    }

    @Test
    void validarTokenValidoRetornaOPedido() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null);
        var valid = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("ok")
                .tokenExpiresAt(LocalDateTime.now().plusDays(1))
                .status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findByToken("ok")).thenReturn(java.util.Optional.of(valid));

        var result = useCase.validateToken("ok");

        assertThat(result.getEmail()).isEqualTo("aluno@edu.unifor.br");
    }

    @Test
    void submeterComTokenValidoMarcaComoPending() {
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder);

        var institutionId = java.util.UUID.randomUUID();
        var invited = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("ok")
                .tokenExpiresAt(LocalDateTime.now().plusDays(1))
                .status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findByToken("ok")).thenReturn(java.util.Optional.of(invited));
        when(institutionRepository.findById(institutionId))
                .thenReturn(java.util.Optional.of(com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder().id(institutionId).build()));
        when(passwordEncoder.encode("senha123")).thenReturn("hash-fake");
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var data = new com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase.SubmitData(
                "Maria Oliveira", "senha123", institutionId, null, null, null, null);
        var result = useCase.submitRegistration("ok", data);

        assertThat(result.getStatus()).isEqualTo(RegistrationStatus.PENDING);
        assertThat(result.getFullName()).isEqualTo("Maria Oliveira");
        assertThat(result.getPasswordHash()).isEqualTo("hash-fake");
    }

    @Test
    void submeterComInstituicaoInexistenteLancaExcecao() {
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder);

        var invited = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("ok")
                .tokenExpiresAt(LocalDateTime.now().plusDays(1))
                .status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findByToken("ok")).thenReturn(java.util.Optional.of(invited));
        var missingId = java.util.UUID.randomUUID();
        when(institutionRepository.findById(missingId)).thenReturn(java.util.Optional.empty());

        var data = new com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase.SubmitData(
                "Maria Oliveira", "senha123", missingId, null, null, null, null);

        assertThatThrownBy(() -> useCase.submitRegistration("ok", data))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.NotFoundException.class);
    }

    @Test
    void reenvioAposNegacaoVoltaPraPending() {
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder);

        var institutionId = java.util.UUID.randomUUID();
        var rejected = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("ok")
                .tokenExpiresAt(LocalDateTime.now().plusDays(1))
                .status(RegistrationStatus.REJECTED)
                .build();
        when(registrationRepository.findByToken("ok")).thenReturn(java.util.Optional.of(rejected));
        when(institutionRepository.findById(institutionId))
                .thenReturn(java.util.Optional.of(com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder().id(institutionId).build()));
        when(passwordEncoder.encode(anyString())).thenReturn("hash-fake");
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var data = new com.smartboarding.smartboarding_api.domain.registration.port.in.SubmitRegistrationUseCase.SubmitData(
                "Maria Oliveira", "senha123", institutionId, null, null, null, null);
        var result = useCase.submitRegistration("ok", data);

        assertThat(result.getStatus()).isEqualTo(RegistrationStatus.PENDING);
    }
}
