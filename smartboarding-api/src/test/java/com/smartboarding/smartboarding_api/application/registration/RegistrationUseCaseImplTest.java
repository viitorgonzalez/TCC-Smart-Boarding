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
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RegistrationUseCaseImplTest {

    @Mock RegistrationRequestRepositoryPort registrationRepository;
    @Mock EmailPort emailPort;

    @Test
    void gerarConviteCriaPedidoComTokenECodigoEEnviaEmail() {
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, passwordEncoder, userRepository);
        when(userRepository.existsByEmail("aluno@edu.unifor.br")).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("hash-fake-do-codigo");
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.generateInvite("aluno@edu.unifor.br");

        ArgumentCaptor<RegistrationRequest> captor = ArgumentCaptor.forClass(RegistrationRequest.class);
        verify(registrationRepository).save(captor.capture());
        RegistrationRequest saved = captor.getValue();

        assertThat(saved.getEmail()).isEqualTo("aluno@edu.unifor.br");
        assertThat(saved.getStatus()).isEqualTo(RegistrationStatus.INVITED);
        assertThat(saved.getToken()).isNotBlank();
        assertThat(saved.getTokenExpiresAt()).isAfter(LocalDateTime.now().plusDays(6));
        assertThat(saved.getCodeHash()).isEqualTo("hash-fake-do-codigo");
        assertThat(saved.getCodeExpiresAt()).isAfter(LocalDateTime.now().plusMinutes(14));
        assertThat(saved.getCodeAttempts()).isZero();

        ArgumentCaptor<String> bodyCaptor = ArgumentCaptor.forClass(String.class);
        verify(emailPort).send(eq("aluno@edu.unifor.br"), anyString(), bodyCaptor.capture());
        assertThat(bodyCaptor.getValue()).containsPattern("\\d{6}");
        // Código nunca é enviado em texto puro pro repositório -- só o hash. O e-mail é o único
        // lugar onde o valor puro existe, e não é este teste que consegue lê-lo de volta (o
        // passwordEncoder está mockado); a asserção acima só confirma o formato (6 dígitos).
    }

    @Test
    void validarTokenExpiradoLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
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
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
        when(registrationRepository.findByToken("xyz")).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> useCase.validateToken("xyz"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.NotFoundException.class);
    }

    @Test
    void validarTokenValidoRetornaOPedido() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
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
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder, null);

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
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder, null);

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
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, passwordEncoder, null);

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

    @Test
    void listarPendentesRetornaSoOsPending() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
        var pending = RegistrationRequest.builder().status(RegistrationStatus.PENDING).build();
        when(registrationRepository.findAllByStatus(RegistrationStatus.PENDING)).thenReturn(List.of(pending));

        var result = useCase.listPending();

        assertThat(result).hasSize(1);
    }

    @Test
    void aprovarCriaAContaDeFatoEMarcaComoApproved() {
        // Ruling do controller: approve() precisa copiar a instituição escolhida pro User criado
        // (RN14) — diferente do 5-arg literal do brief, aqui institutionRepository não pode ser
        // null porque approve() resolve o nome da instituição antes de montar o User.
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var institutionId = java.util.UUID.randomUUID();
        var pending = RegistrationRequest.builder()
                .id(id).email("aluno@edu.unifor.br").fullName("Maria Oliveira")
                .passwordHash("hash-fake").institutionId(institutionId).status(RegistrationStatus.PENDING)
                .build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(pending));
        when(institutionRepository.findById(institutionId)).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder()
                        .id(institutionId).name("Unifor").build()));
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var user = useCase.approve(id);

        assertThat(user.getEmail()).isEqualTo("aluno@edu.unifor.br");
        assertThat(user.getRole()).isEqualTo(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT);
        assertThat(user.getPassword()).isEqualTo("hash-fake");
        assertThat(user.getInstitution()).isEqualTo("Unifor");
        verify(registrationRepository).save(argThat(r -> r.getStatus() == RegistrationStatus.APPROVED));
    }

    @Test
    void aprovarComInstituicaoInexistenteLancaExcecao() {
        // Defensivo: Task 6 já valida a instituição no submit, então isso não deveria acontecer
        // na prática — mas se acontecer, approve() se comporta como submitRegistration (404), não
        // silenciosamente cria o User sem instituição.
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var institutionId = java.util.UUID.randomUUID();
        var pending = RegistrationRequest.builder()
                .id(id).email("aluno@edu.unifor.br").fullName("Maria Oliveira")
                .passwordHash("hash-fake").institutionId(institutionId).status(RegistrationStatus.PENDING)
                .build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(pending));
        when(institutionRepository.findById(institutionId)).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> useCase.approve(id))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.NotFoundException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void negarMarcaComoRejectedSemCriarConta() {
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var pending = RegistrationRequest.builder().id(id).status(RegistrationStatus.PENDING).build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(pending));
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        useCase.reject(id);

        verify(registrationRepository).save(argThat(r -> r.getStatus() == RegistrationStatus.REJECTED));
        verify(userRepository, never()).save(any());
    }

    @Test
    void validarTokenDeCadastroJaAprovadoLancaExcecao() {
        // C1 do review final: um convite já APPROVED não pode voltar a validar — senão o aluno
        // reabre o link antigo, reenvia o submit e o approve() seguinte colide com o UNIQUE(email).
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
        var approved = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("ok")
                .tokenExpiresAt(LocalDateTime.now().plusDays(1))
                .status(RegistrationStatus.APPROVED)
                .build();
        when(registrationRepository.findByToken("ok")).thenReturn(java.util.Optional.of(approved));

        assertThatThrownBy(() -> useCase.validateToken("ok"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);
    }

    @Test
    void aprovarPedidoNaoPendenteLancaConflito() {
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var alreadyApproved = RegistrationRequest.builder().id(id).email("aluno@edu.unifor.br")
                .status(RegistrationStatus.APPROVED).build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(alreadyApproved));

        assertThatThrownBy(() -> useCase.approve(id))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void aprovarComEmailJaExistenteLancaConflito() {
        var institutionRepository = mock(com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort.class);
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, institutionRepository, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var pending = RegistrationRequest.builder().id(id).email("aluno@edu.unifor.br")
                .status(RegistrationStatus.PENDING).build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(pending));
        when(userRepository.existsByEmail("aluno@edu.unifor.br")).thenReturn(true);

        assertThatThrownBy(() -> useCase.approve(id))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(userRepository, never()).save(any());
        verify(institutionRepository, never()).findById(any());
    }

    @Test
    void negarPedidoNaoPendenteLancaConflito() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);

        var id = java.util.UUID.randomUUID();
        var alreadyRejected = RegistrationRequest.builder().id(id).status(RegistrationStatus.REJECTED).build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(alreadyRejected));

        assertThatThrownBy(() -> useCase.reject(id))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(registrationRepository, never()).save(any());
    }

    @Test
    void gerarConviteComEmailJaExistenteLancaConflito() {
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, userRepository);
        when(userRepository.existsByEmail("aluno@edu.unifor.br")).thenReturn(true);

        assertThatThrownBy(() -> useCase.generateInvite("aluno@edu.unifor.br"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(registrationRepository, never()).save(any());
        verify(emailPort, never()).send(any(), any(), any());
    }

    @Test
    void verificarCodigoValidoRetornaOToken() {
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, passwordEncoder, null);

        var request = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").token("token-interno")
                .codeHash("hash-do-123456").codeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .codeAttempts(0).status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("aluno@edu.unifor.br"))
                .thenReturn(java.util.Optional.of(request));
        when(passwordEncoder.matches("123456", "hash-do-123456")).thenReturn(true);

        var token = useCase.verifyCode("aluno@edu.unifor.br", "123456");

        assertThat(token).isEqualTo("token-interno");
        verify(registrationRepository, never()).save(any());
    }

    @Test
    void verificarCodigoErradoIncrementaTentativasELancaExcecao() {
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, passwordEncoder, null);

        var request = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br")
                .codeHash("hash-do-123456").codeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .codeAttempts(2).status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("aluno@edu.unifor.br"))
                .thenReturn(java.util.Optional.of(request));
        when(passwordEncoder.matches("000000", "hash-do-123456")).thenReturn(false);
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        assertThatThrownBy(() -> useCase.verifyCode("aluno@edu.unifor.br", "000000"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);

        ArgumentCaptor<RegistrationRequest> captor = ArgumentCaptor.forClass(RegistrationRequest.class);
        verify(registrationRepository).save(captor.capture());
        assertThat(captor.getValue().getCodeAttempts()).isEqualTo(3);
    }

    @Test
    void verificarCodigoComTentativasEsgotadasLancaExcecaoSemChecarHash() {
        var passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, passwordEncoder, null);

        var request = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br")
                .codeHash("hash-do-123456").codeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .codeAttempts(5).status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("aluno@edu.unifor.br"))
                .thenReturn(java.util.Optional.of(request));

        assertThatThrownBy(() -> useCase.verifyCode("aluno@edu.unifor.br", "123456"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);
        verify(passwordEncoder, never()).matches(any(), any());
        verify(registrationRepository, never()).save(any());
    }

    @Test
    void verificarCodigoExpiradoLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);

        var request = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br")
                .codeHash("hash-do-123456").codeExpiresAt(LocalDateTime.now().minusMinutes(1))
                .codeAttempts(0).status(RegistrationStatus.INVITED)
                .build();
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("aluno@edu.unifor.br"))
                .thenReturn(java.util.Optional.of(request));

        assertThatThrownBy(() -> useCase.verifyCode("aluno@edu.unifor.br", "123456"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);
    }

    @Test
    void verificarCodigoDeEmailInexistenteLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("ninguem@edu.unifor.br"))
                .thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> useCase.verifyCode("ninguem@edu.unifor.br", "123456"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.NotFoundException.class);
    }

    @Test
    void verificarCodigoDeCadastroJaAprovadoLancaExcecao() {
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, null);

        var request = RegistrationRequest.builder()
                .email("aluno@edu.unifor.br").status(RegistrationStatus.APPROVED)
                .codeHash("hash-do-123456").codeExpiresAt(LocalDateTime.now().plusMinutes(10))
                .build();
        when(registrationRepository.findTopByEmailOrderByCreatedAtDesc("aluno@edu.unifor.br"))
                .thenReturn(java.util.Optional.of(request));

        assertThatThrownBy(() -> useCase.verifyCode("aluno@edu.unifor.br", "123456"))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class);
    }
}
