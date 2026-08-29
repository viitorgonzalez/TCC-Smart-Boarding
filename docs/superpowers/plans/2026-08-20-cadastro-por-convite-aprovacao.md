# Cadastro por convite e aprovação — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar o fluxo de cadastro por convite ponta-a-ponta — admin gera convite, aluno recebe e-mail e preenche o cadastro, admin aprova/nega — incluindo o mínimo de `Institution` pro dropdown do formulário funcionar.

**Architecture:** Duas entidades novas no backend (`RegistrationRequest`, `Institution`), seguindo a arquitetura hexagonal já usada em `route` (um `*UseCaseImpl` por feature implementando todas as portas `in`, um `*RepositoryAdapter` por porta `out`). Uma feature nova no Flutter (`lib/features/registration/`, feature-first) mais uma tela mínima de criar instituição dentro de `lib/features/routes/`. Deep-link (`app_links`) intercepta o link do convite e empurra pra `RegisterScreen`.

**Tech Stack:** Java 21 · Spring Boot 4.0.5 · Spring Security (JWT já existente, BCrypt) · Flyway · Postgres — Flutter · Dart · Provider · Dio · mocktail.

**Spec:** `docs/superpowers/specs/2026-08-20-cadastro-por-convite-aprovacao-design.md`

## Global Constraints

- Token de convite válido por **7 dias** a partir da geração (RN13).
- `RegistrationRequest` **nunca** vira `User` até a aprovação — aprovar "cria a conta de fato" (RN14).
- Negar **não invalida o token** — enquanto válido, aluno reenvia e gera nova avaliação (RN14).
- `POST /api/auth/register` continua existindo só pra `ADMIN` criar outro `ADMIN` — não mexer nele, não aceita `role=STUDENT` nem instituição.
- Senha nunca fica em texto puro em lugar nenhum — hash (`PasswordEncoder`/BCrypt, já injetável) no submit, copiado direto pro `User` na aprovação.
- Domínio de App Link real e publicação nas lojas ficam fora de escopo (ver spec §5, §7) — código no formato final, deploy é pendência conhecida.
- Todo teste novo é `*Test.java` (Surefire, sem Docker) no backend — mesmo padrão do resto da API; nenhuma integração nova via Testcontainers é necessária aqui.
- Comentário só explica o porquê, nunca o quê (convenção do harness, `personal-harness/docs/CONVENTIONS.md` §4).

---

### Task 1: Migration — tabelas `institutions` e `registration_requests`

**Files:**
- Create: `smartboarding-api/src/main/resources/db/migration/V4__registration_and_institutions.sql`

**Interfaces:**
- Produces: tabelas `institutions` (id, name, address, latitude, longitude, created_at, updated_at) e `registration_requests` (id, email, token, token_expires_at, status, full_name, password_hash, institution_id FK, course, phone, address, birth_date, created_at, updated_at) — consumidas pelas entidades JPA das Tasks 2 e 3.

- [ ] **Step 1: Escrever a migration**

```sql
-- Cadastro por convite (RN13/RN14) precisa de instituição real pro dropdown
-- (User.institution era só string solta) e de um lugar pra guardar o pedido
-- pendente sem virar conta antes da aprovação.
CREATE TABLE institutions (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(150) NOT NULL,
    address    VARCHAR(255),
    latitude   DOUBLE PRECISION,
    longitude  DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE registration_requests (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email             VARCHAR(100) NOT NULL,
    token             VARCHAR(64)  NOT NULL UNIQUE,
    token_expires_at  TIMESTAMP    NOT NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'INVITED',
    full_name         VARCHAR(150),
    password_hash     VARCHAR(255),
    institution_id    UUID REFERENCES institutions(id),
    course            VARCHAR(100),
    phone             VARCHAR(20),
    address           TEXT,
    birth_date        DATE,
    created_at        TIMESTAMP DEFAULT NOW(),
    updated_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_registration_requests_token ON registration_requests(token);
CREATE INDEX idx_registration_requests_status ON registration_requests(status);
```

- [ ] **Step 2: Rodar a suíte pra confirmar que a migration aplica limpo**

Run: `cd smartboarding-api && ./mvnw test`
Expected: `SmartboardingApiApplicationIT`-equivalente sobe o schema do zero sem erro de migration (o teste de contexto valida isso implicitamente). Se `test` não sobe contexto Spring, confirme com `./mvnw flyway:info` (precisa do Postgres de pé via `docker compose up -d`) que `V4` aparece como aplicável sem conflito.

- [ ] **Step 3: Commitar**

```bash
git add smartboarding-api/src/main/resources/db/migration/V4__registration_and_institutions.sql
git commit -m "feat(db): migration das tabelas institutions e registration_requests"
```

---

### Task 2: Backend — `Institution` (entidade, portas, adapter, use cases, endpoints)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/institution/entity/Institution.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/institution/port/in/CreateInstitutionUseCase.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/institution/port/in/ListInstitutionsUseCase.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/institution/port/out/InstitutionRepositoryPort.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/institution/InstitutionUseCaseImpl.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/institution/InstitutionJpaRepository.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/institution/InstitutionRepositoryAdapter.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/institution/InstitutionController.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/institution/dto/CreateInstitutionRequest.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/institution/dto/InstitutionResponse.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Test: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/institution/InstitutionUseCaseImplTest.java`

**Interfaces:**
- Produces: `CreateInstitutionUseCase.execute(Institution)`, `ListInstitutionsUseCase.findAll()` — consumidos por `RegistrationRequest`'s `institutionId` FK validation na Task 4 (indiretamente, via `InstitutionRepositoryPort.findById`).

- [ ] **Step 1: Entidade**

```java
package com.smartboarding.smartboarding_api.domain.institution.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "institutions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Institution {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(length = 255)
    private String address;

    private Double latitude;
    private Double longitude;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 2: Portas**

```java
package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

public interface CreateInstitutionUseCase {
    Institution execute(Institution institution);
}
```

```java
package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.List;

public interface ListInstitutionsUseCase {
    List<Institution> findAll();
}
```

```java
package com.smartboarding.smartboarding_api.domain.institution.port.out;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InstitutionRepositoryPort {
    Institution save(Institution institution);
    Optional<Institution> findById(UUID id);
    List<Institution> findAll();
}
```

- [ ] **Step 3: Escrever o teste do use case (falhando)**

```java
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
```

- [ ] **Step 4: Rodar o teste e confirmar que falha**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=InstitutionUseCaseImplTest test`
Expected: FAIL — `InstitutionUseCaseImpl` não existe ainda.

- [ ] **Step 5: Implementar o use case**

```java
package com.smartboarding.smartboarding_api.application.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class InstitutionUseCaseImpl implements CreateInstitutionUseCase, ListInstitutionsUseCase {

    private final InstitutionRepositoryPort institutionRepository;

    public InstitutionUseCaseImpl(InstitutionRepositoryPort institutionRepository) {
        this.institutionRepository = institutionRepository;
    }

    @Override
    @Transactional
    public Institution execute(Institution institution) {
        return institutionRepository.save(institution);
    }

    @Override
    public List<Institution> findAll() {
        return institutionRepository.findAll();
    }
}
```

- [ ] **Step 6: JPA repository + adapter**

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface InstitutionJpaRepository extends JpaRepository<Institution, UUID> {}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class InstitutionRepositoryAdapter implements InstitutionRepositoryPort {

    private final InstitutionJpaRepository jpa;

    public InstitutionRepositoryAdapter(InstitutionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public Institution save(Institution institution) { return jpa.save(institution); }
    @Override public Optional<Institution> findById(UUID id) { return jpa.findById(id); }
    @Override public List<Institution> findAll() { return jpa.findAll(); }
}
```

- [ ] **Step 7: DTOs + controller**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateInstitutionRequest(
        @NotBlank(message = "name can't be empty") String name,
        String address,
        Double latitude,
        Double longitude
) {}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.web.institution.dto;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.UUID;

public record InstitutionResponse(UUID id, String name, String address, Double latitude, Double longitude) {
    public static InstitutionResponse from(Institution institution) {
        return new InstitutionResponse(institution.getId(), institution.getName(),
                institution.getAddress(), institution.getLatitude(), institution.getLongitude());
    }
}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.web.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.CreateInstitutionRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.InstitutionResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/institutions")
public class InstitutionController {

    private final CreateInstitutionUseCase createInstitutionUseCase;
    private final ListInstitutionsUseCase listInstitutionsUseCase;

    public InstitutionController(CreateInstitutionUseCase createInstitutionUseCase,
                                 ListInstitutionsUseCase listInstitutionsUseCase) {
        this.createInstitutionUseCase = createInstitutionUseCase;
        this.listInstitutionsUseCase = listInstitutionsUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<InstitutionResponse>> create(@RequestBody @Valid CreateInstitutionRequest request) {
        Institution institution = Institution.builder()
                .name(request.name()).address(request.address())
                .latitude(request.latitude()).longitude(request.longitude())
                .build();
        Institution saved = createInstitutionUseCase.execute(institution);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(InstitutionResponse.from(saved)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<InstitutionResponse>>> findAll() {
        List<InstitutionResponse> institutions = listInstitutionsUseCase.findAll().stream()
                .map(InstitutionResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(institutions));
    }
}
```

- [ ] **Step 8: `SecurityConfig` — `GET` público (dropdown do cadastro não tem sessão), `POST` só admin**

Em `SecurityConfig.java`, no bloco `authorizeHttpRequests`, adicionar (perto das outras regras de `/api/routes`):

```java
                        .requestMatchers(HttpMethod.GET, "/api/institutions").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/institutions").hasRole("ADMIN")
```

- [ ] **Step 9: Rodar o teste e confirmar que passa**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=InstitutionUseCaseImplTest test`
Expected: PASS — 2/2.

- [ ] **Step 10: Rodar a suíte inteira (gate do harness)**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test`
Expected: PASS, sem regressão nos testes existentes.

- [ ] **Step 11: Commitar**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/institution \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/institution \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/institution \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/institution \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/institution
git commit -m "feat(api): entidade Institution com CRUD básico (create + list)"
```

---

### Task 3: Backend — `RegistrationRequest` (entidade, portas, adapter — sem endpoint ainda)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/entity/RegistrationRequest.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/entity/RegistrationStatus.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/out/RegistrationRequestRepositoryPort.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/registration/RegistrationRequestJpaRepository.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/registration/RegistrationRequestRepositoryAdapter.java`

**Interfaces:**
- Consumes: `Institution` (Task 2) via `institutionId` — sem FK de objeto Java, só `UUID`, resolvido no use case da Task 6.
- Produces: `RegistrationRequestRepositoryPort` (`save`, `findByToken`, `findById`, `findAllByStatus`) — consumido pelas Tasks 4-7.

- [ ] **Step 1: Enum de status**

```java
package com.smartboarding.smartboarding_api.domain.registration.entity;

public enum RegistrationStatus {
    INVITED, PENDING, APPROVED, REJECTED
}
```

- [ ] **Step 2: Entidade**

```java
package com.smartboarding.smartboarding_api.domain.registration.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "registration_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegistrationRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String email;

    @Column(nullable = false, unique = true, length = 64)
    private String token;

    @Column(name = "token_expires_at", nullable = false)
    private LocalDateTime tokenExpiresAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RegistrationStatus status;

    @Column(name = "full_name", length = 150)
    private String fullName;

    @Column(name = "password_hash")
    private String passwordHash;

    @Column(name = "institution_id")
    private UUID institutionId;

    @Column(length = 100)
    private String course;

    @Column(length = 20)
    private String phone;

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public boolean isTokenExpired() {
        return LocalDateTime.now().isAfter(tokenExpiresAt);
    }
}
```

- [ ] **Step 3: Porta de repositório**

```java
package com.smartboarding.smartboarding_api.domain.registration.port.out;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RegistrationRequestRepositoryPort {
    RegistrationRequest save(RegistrationRequest request);
    Optional<RegistrationRequest> findByToken(String token);
    Optional<RegistrationRequest> findById(UUID id);
    List<RegistrationRequest> findAllByStatus(RegistrationStatus status);
}
```

- [ ] **Step 4: JPA repository + adapter**

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.registration;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RegistrationRequestJpaRepository extends JpaRepository<RegistrationRequest, UUID> {
    Optional<RegistrationRequest> findByToken(String token);
    List<RegistrationRequest> findAllByStatus(RegistrationStatus status);
}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.persistence.registration;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class RegistrationRequestRepositoryAdapter implements RegistrationRequestRepositoryPort {

    private final RegistrationRequestJpaRepository jpa;

    public RegistrationRequestRepositoryAdapter(RegistrationRequestJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public RegistrationRequest save(RegistrationRequest request) { return jpa.save(request); }
    @Override public Optional<RegistrationRequest> findByToken(String token) { return jpa.findByToken(token); }
    @Override public Optional<RegistrationRequest> findById(UUID id) { return jpa.findById(id); }
    @Override public List<RegistrationRequest> findAllByStatus(RegistrationStatus status) { return jpa.findAllByStatus(status); }
}
```

- [ ] **Step 5: Rodar a suíte (nada quebrado, sem teste próprio nesta task — é só persistência, coberta pelos use cases das Tasks 4-7)**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test`
Expected: PASS.

- [ ] **Step 6: Commitar**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/persistence/registration
git commit -m "feat(api): entidade RegistrationRequest e persistência"
```

---

### Task 4: Backend — gerar convite (`GenerateInviteUseCase` + `POST /api/registration/invite`)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/GenerateInviteUseCase.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationController.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/dto/InviteRequest.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Test: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImplTest.java`

**Interfaces:**
- Consumes: `RegistrationRequestRepositoryPort` (Task 3), `EmailPort` (já existe, `ResendEmailAdapter`).
- Produces: `RegistrationUseCaseImpl` — as Tasks 5-7 adicionam mais métodos na MESMA classe (implementando as demais portas `in`), não criam uma nova.

- [ ] **Step 1: Porta**

Diferente do precedente de `route` (cada porta com um método `execute` só) — aqui uma única classe (`RegistrationUseCaseImpl`) vai implementar até 6 portas, várias com a mesma assinatura de parâmetro (`String`/`UUID`) e retornos diferentes, o que não compila como overload em Java. Por isso cada porta de `registration` declara um método com nome próprio (`generateInvite`, `validateToken`, `submitRegistration`, `listPending`, `approve`, `reject`) em vez de `execute` — decisão local a este domínio, não muda o padrão de `route`/`institution`.

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

public interface GenerateInviteUseCase {
    void generateInvite(String email);
}
```

- [ ] **Step 2: Teste (falhando)**

```java
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
}
```

- [ ] **Step 3: Rodar e confirmar falha**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: FAIL — `RegistrationUseCaseImpl` não existe.

- [ ] **Step 4: Implementar (construtor já recebe os 4 parâmetros que as Tasks 5-7 vão usar — `institutionRepository` e `passwordEncoder` ficam `null`-tolerantes até lá, só usados nos métodos que essas tasks adicionam)**

```java
package com.smartboarding.smartboarding_api.application.registration;

import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.shared.port.out.EmailPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HexFormat;

@Slf4j
@Service
public class RegistrationUseCaseImpl implements GenerateInviteUseCase {

    private static final long TOKEN_TTL_DAYS = 7;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final RegistrationRequestRepositoryPort registrationRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;

    public RegistrationUseCaseImpl(RegistrationRequestRepositoryPort registrationRepository,
                                   InstitutionRepositoryPort institutionRepository,
                                   EmailPort emailPort,
                                   PasswordEncoder passwordEncoder) {
        this.registrationRepository = registrationRepository;
        this.institutionRepository = institutionRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void generateInvite(String email) {
        String token = generateToken();
        RegistrationRequest request = RegistrationRequest.builder()
                .email(email)
                .token(token)
                .tokenExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS))
                .status(RegistrationStatus.INVITED)
                .build();
        registrationRepository.save(request);

        String link = "https://smartboarding.app/register/" + token; // domínio real fica pendente do deploy — ver spec §5
        emailPort.send(email, "Convite Smart Boarding",
                "<p>Você foi convidado a se cadastrar no Smart Boarding.</p><p><a href=\"" + link + "\">Completar cadastro</a></p>");
        log.info("Convite de cadastro gerado pra {}", email);
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }
}
```

- [ ] **Step 5: Confirmar que o teste passa**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: PASS — 1/1.

- [ ] **Step 6: DTO + controller (só o endpoint de convite por enquanto)**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record InviteRequest(
        @NotBlank @Email(message = "e-mail inválido") String email
) {}
```

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import com.smartboarding.smartboarding_api.domain.registration.port.in.GenerateInviteUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.registration.dto.InviteRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/registration")
public class RegistrationController {

    private final GenerateInviteUseCase generateInviteUseCase;

    public RegistrationController(GenerateInviteUseCase generateInviteUseCase) {
        this.generateInviteUseCase = generateInviteUseCase;
    }

    @PostMapping("/invite")
    public ResponseEntity<ApiResponse<?>> invite(@RequestBody @Valid InviteRequest request) {
        generateInviteUseCase.generateInvite(request.email());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success());
    }
}
```

- [ ] **Step 7: `SecurityConfig`**

```java
                        .requestMatchers(HttpMethod.POST, "/api/registration/invite").hasRole("ADMIN")
```

- [ ] **Step 8: Suíte inteira + commit**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test` → PASS.

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/GenerateInviteUseCase.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration
git commit -m "feat(api): gera convite de cadastro (token + e-mail via Resend)"
```

---

### Task 5: Backend — validar token (`ValidateTokenUseCase` + `GET /api/registration/invite/{token}`)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/ValidateTokenUseCase.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationController.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/dto/InviteInfoResponse.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Modify: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImplTest.java`

**Interfaces:**
- Consumes: `RegistrationRequestRepositoryPort.findByToken` (Task 3).
- Produces: `ValidateTokenUseCase.validateToken(String token) -> RegistrationRequest` — consumido pela Task 6 (o submit reusa a mesma validação).

- [ ] **Step 1: Porta**

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

public interface ValidateTokenUseCase {
    RegistrationRequest validateToken(String token);
}
```

- [ ] **Step 2: Testes (falhando) — adicionar ao arquivo existente**

```java
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
```

- [ ] **Step 3: Rodar e confirmar falha**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: FAIL — método não existe.

- [ ] **Step 4: Implementar — adicionar `implements ValidateTokenUseCase` e o método na classe da Task 4**

```java
// assinatura da classe passa a ser:
public class RegistrationUseCaseImpl implements GenerateInviteUseCase, ValidateTokenUseCase {

    // ... construtor e execute(String email) da Task 4 continuam iguais ...

    @Override
    public RegistrationRequest validateToken(String token) {
        RegistrationRequest request = registrationRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Convite não encontrado"));
        if (request.isTokenExpired()) {
            throw new BadRequestException("TOKEN_EXPIRED", "Convite expirado");
        }
        return request;
    }
}
```

Imports novos no arquivo: `com.smartboarding.smartboarding_api.shared.exception.NotFoundException`, `com.smartboarding.smartboarding_api.shared.exception.BadRequestException`.

- [ ] **Step 5: Confirmar que os testes passam**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: PASS — 4/4.

- [ ] **Step 6: DTO + endpoint no controller**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

public record InviteInfoResponse(String email) {
    public static InviteInfoResponse from(RegistrationRequest request) {
        return new InviteInfoResponse(request.getEmail());
    }
}
```

Adicionar ao `RegistrationController` (construtor ganha `ValidateTokenUseCase`):

```java
    @GetMapping("/invite/{token}")
    public ResponseEntity<ApiResponse<InviteInfoResponse>> getInvite(@PathVariable String token) {
        var request = validateTokenUseCase.validateToken(token);
        return ResponseEntity.ok(ApiResponse.data(InviteInfoResponse.from(request)));
    }
```

- [ ] **Step 7: `SecurityConfig`**

```java
                        .requestMatchers(HttpMethod.GET, "/api/registration/invite/{token}").permitAll()
```

- [ ] **Step 8: Suíte inteira + commit**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test` → PASS.

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/ValidateTokenUseCase.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration
git commit -m "feat(api): valida token de convite (existe + não expirado)"
```

---

### Task 6: Backend — submeter cadastro (`SubmitRegistrationUseCase` + `POST /api/registration/{token}/submit`)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/SubmitRegistrationUseCase.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationController.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/dto/SubmitRegistrationRequest.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Modify: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImplTest.java`

**Interfaces:**
- Consumes: `InstitutionRepositoryPort.findById` (Task 2, valida `institutionId`), `PasswordEncoder` (bean já existente, `SecurityConfig`).
- Produces: `submitRegistration(token, ...)` — não expõe nada novo pras próximas tasks, é terminal desse sub-fluxo.

- [ ] **Step 1: Porta**

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.time.LocalDate;
import java.util.UUID;

public interface SubmitRegistrationUseCase {
    record SubmitData(String fullName, String rawPassword, UUID institutionId,
                       String course, String phone, String address, LocalDate birthDate) {}

    RegistrationRequest submitRegistration(String token, SubmitData data);
}
```

- [ ] **Step 2: Testes (falhando) — adicionar ao arquivo existente**

```java
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
```

- [ ] **Step 3: Rodar e confirmar falha**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: FAIL — `submitRegistration` não existe.

- [ ] **Step 4: Implementar**

```java
// assinatura da classe:
public class RegistrationUseCaseImpl implements GenerateInviteUseCase, ValidateTokenUseCase, SubmitRegistrationUseCase {

    // ... métodos anteriores continuam iguais ...

    @Override
    @Transactional
    public RegistrationRequest submitRegistration(String token, SubmitData data) {
        RegistrationRequest request = validateToken(token); // reusa a validação de expiração/existência

        Institution institution = institutionRepository.findById(data.institutionId())
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));

        request.setFullName(data.fullName());
        request.setPasswordHash(passwordEncoder.encode(data.rawPassword()));
        request.setInstitutionId(institution.getId());
        request.setCourse(data.course());
        request.setPhone(data.phone());
        request.setAddress(data.address());
        request.setBirthDate(data.birthDate());
        request.setStatus(RegistrationStatus.PENDING);

        RegistrationRequest saved = registrationRepository.save(request);
        log.info("Cadastro submetido: {}", request.getEmail());
        return saved;
    }
}
```

Import novo: `com.smartboarding.smartboarding_api.domain.institution.entity.Institution`.

Note que `submitRegistration` chama o método `validateToken` (Task 5) — que por sua vez não bloqueia reenvio de um pedido `REJECTED` (só checa expiração), exatamente o comportamento da RN14.

- [ ] **Step 5: Confirmar que os testes passam**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: PASS — 7/7.

- [ ] **Step 6: DTO + endpoint**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public record SubmitRegistrationRequest(
        @NotBlank(message = "fullName can't be empty") String fullName,
        @NotBlank(message = "password can't be empty") String password,
        @NotNull(message = "institutionId is required") UUID institutionId,
        String course,
        String phone,
        String address,
        LocalDate birthDate
) {}
```

Adicionar ao `RegistrationController` (construtor ganha `SubmitRegistrationUseCase`):

```java
    @PostMapping("/{token}/submit")
    public ResponseEntity<ApiResponse<?>> submit(@PathVariable String token,
                                                  @RequestBody @Valid SubmitRegistrationRequest request) {
        submitRegistrationUseCase.submitRegistration(token, new SubmitRegistrationUseCase.SubmitData(
                request.fullName(), request.password(), request.institutionId(),
                request.course(), request.phone(), request.address(), request.birthDate()));
        return ResponseEntity.ok(ApiResponse.data(java.util.Map.of("status", "SUBMITTED")));
    }
```

- [ ] **Step 7: `SecurityConfig`**

```java
                        .requestMatchers(HttpMethod.POST, "/api/registration/{token}/submit").permitAll()
```

- [ ] **Step 8: Suíte inteira + commit**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test` → PASS.

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/SubmitRegistrationUseCase.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration
git commit -m "feat(api): submissão do cadastro (marca PENDING, sem criar conta ainda)"
```

---

### Task 7: Backend — listar/aprovar/negar (`GET pending`, `POST approve`, `POST reject`)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/ListPendingRegistrationsUseCase.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/ApproveRegistrationUseCase.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in/RejectRegistrationUseCase.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationController.java`
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/dto/PendingRegistrationResponse.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`
- Modify: `smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImplTest.java`

**Interfaces:**
- Consumes: `UserRepositoryPort.save` (já existe, `domain.user.port.out`) — a aprovação cria o `User` real.
- Produces: nada consumido por task futura — fecha o sub-fluxo de cadastro.

- [ ] **Step 1: Portas**

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.util.List;

public interface ListPendingRegistrationsUseCase {
    List<RegistrationRequest> listPending();
}
```

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.util.UUID;

public interface ApproveRegistrationUseCase {
    User approve(UUID id);
}
```

```java
package com.smartboarding.smartboarding_api.domain.registration.port.in;

import java.util.UUID;

public interface RejectRegistrationUseCase {
    void reject(UUID id);
}
```

- [ ] **Step 2: Testes (falhando) — adicionar ao arquivo existente. O construtor do `RegistrationUseCaseImpl` ganha um 5º parâmetro, `UserRepositoryPort` — todos os testes anteriores que instanciam a classe com 4 argumentos precisam de um 5º (`null` ou um mock, conforme o teste use)**

Primeiro, ajustar TODAS as chamadas `new RegistrationUseCaseImpl(registrationRepository, ..., emailPort, ...)` já escritas nos testes anteriores (Tasks 4-6) pra passar um 5º argumento — nos testes que não envolvem aprovação, `null` mesmo (o teste unitário não invoca esse caminho). Depois, adicionar:

```java
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
        var userRepository = mock(com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort.class);
        var useCase = new RegistrationUseCaseImpl(registrationRepository, null, emailPort, null, userRepository);

        var id = java.util.UUID.randomUUID();
        var pending = RegistrationRequest.builder()
                .id(id).email("aluno@edu.unifor.br").fullName("Maria Oliveira")
                .passwordHash("hash-fake").status(RegistrationStatus.PENDING)
                .build();
        when(registrationRepository.findById(id)).thenReturn(java.util.Optional.of(pending));
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(registrationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var user = useCase.approve(id);

        assertThat(user.getEmail()).isEqualTo("aluno@edu.unifor.br");
        assertThat(user.getRole()).isEqualTo(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT);
        assertThat(user.getPassword()).isEqualTo("hash-fake");
        verify(registrationRepository).save(argThat(r -> r.getStatus() == RegistrationStatus.APPROVED));
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
```

- [ ] **Step 3: Rodar e confirmar falha**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: FAIL — `listPending`/`approve`/`reject` não existem, construtor com 5 args não bate.

- [ ] **Step 4: Implementar**

```java
// assinatura final da classe:
public class RegistrationUseCaseImpl implements GenerateInviteUseCase, ValidateTokenUseCase,
        SubmitRegistrationUseCase, ListPendingRegistrationsUseCase, ApproveRegistrationUseCase, RejectRegistrationUseCase {

    private final RegistrationRequestRepositoryPort registrationRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final EmailPort emailPort;
    private final PasswordEncoder passwordEncoder;
    private final UserRepositoryPort userRepository;

    public RegistrationUseCaseImpl(RegistrationRequestRepositoryPort registrationRepository,
                                   InstitutionRepositoryPort institutionRepository,
                                   EmailPort emailPort,
                                   PasswordEncoder passwordEncoder,
                                   UserRepositoryPort userRepository) {
        this.registrationRepository = registrationRepository;
        this.institutionRepository = institutionRepository;
        this.emailPort = emailPort;
        this.passwordEncoder = passwordEncoder;
        this.userRepository = userRepository;
    }

    // ... métodos anteriores continuam iguais ...

    @Override
    public List<RegistrationRequest> listPending() {
        return registrationRepository.findAllByStatus(RegistrationStatus.PENDING);
    }

    @Override
    @Transactional
    public User approve(UUID id) {
        RegistrationRequest request = registrationRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Pedido de cadastro não encontrado"));

        User user = User.builder()
                .email(request.getEmail())
                .password(request.getPasswordHash())
                .role(Role.STUDENT)
                .fullName(request.getFullName())
                .course(request.getCourse())
                .phone(request.getPhone())
                .address(request.getAddress())
                .birthDate(request.getBirthDate())
                .isActive(true)
                .build();
        User saved = userRepository.save(user);

        request.setStatus(RegistrationStatus.APPROVED);
        registrationRepository.save(request);
        log.info("Cadastro aprovado, conta criada: {}", request.getEmail());
        return saved;
    }

    @Override
    @Transactional
    public void reject(UUID id) {
        RegistrationRequest request = registrationRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Pedido de cadastro não encontrado"));
        request.setStatus(RegistrationStatus.REJECTED);
        registrationRepository.save(request);
        log.info("Cadastro negado: {}", request.getEmail());
    }
}
```

Imports novos: `com.smartboarding.smartboarding_api.domain.user.entity.Role`, `com.smartboarding.smartboarding_api.domain.user.entity.User`, `com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort`.

- [ ] **Step 5: Confirmar que os testes passam**

Run: `cd smartboarding-api && ./mvnw -B -Dtest=RegistrationUseCaseImplTest test`
Expected: PASS — 10/10.

- [ ] **Step 6: DTO + endpoints**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration.dto;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.time.LocalDateTime;
import java.util.UUID;

public record PendingRegistrationResponse(UUID id, String email, String fullName,
                                           UUID institutionId, LocalDateTime createdAt) {
    public static PendingRegistrationResponse from(RegistrationRequest request) {
        return new PendingRegistrationResponse(request.getId(), request.getEmail(), request.getFullName(),
                request.getInstitutionId(), request.getCreatedAt());
    }
}
```

Adicionar ao `RegistrationController` (construtor ganha `ListPendingRegistrationsUseCase`, `ApproveRegistrationUseCase`, `RejectRegistrationUseCase`):

```java
    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<PendingRegistrationResponse>>> pending() {
        var result = listPendingRegistrationsUseCase.listPending().stream()
                .map(PendingRegistrationResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(result));
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<?>> approve(@PathVariable UUID id) {
        approveRegistrationUseCase.approve(id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<?>> reject(@PathVariable UUID id) {
        rejectRegistrationUseCase.reject(id);
        return ResponseEntity.ok(ApiResponse.success());
    }
```

- [ ] **Step 7: `SecurityConfig`**

```java
                        .requestMatchers(HttpMethod.GET, "/api/registration/pending").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/registration/{id}/approve").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/registration/{id}/reject").hasRole("ADMIN")
```

- [ ] **Step 8: Suíte inteira + commit**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test` → PASS.

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/domain/registration/port/in \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/application/registration/RegistrationUseCaseImpl.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java \
        smartboarding-api/src/test/java/com/smartboarding/smartboarding_api/application/registration
git commit -m "feat(api): admin lista, aprova e nega pedidos de cadastro"
```

---

### Task 8: Backend — página de fallback (`GET /register/{token}`, HTML, não-REST)

**Files:**
- Create: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationFallbackController.java`
- Modify: `smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java`

**Interfaces:**
- Consumes: nenhuma (não valida o token — só existe pra responder algo caso o App Link não abra o app; validação real acontece no `GET /api/registration/invite/{token}` que o app chama).

- [ ] **Step 1: Controller HTML inline (sem motor de template novo)**

```java
package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class RegistrationFallbackController {

    // Só existe pro caso "App Link clicado sem o app instalado" (RN13) — quando
    // o app está instalado, o SO nem chega a bater aqui, abre a tela direto.
    @GetMapping(value = "/register/{token}", produces = MediaType.TEXT_HTML_VALUE)
    @ResponseBody
    public String fallback(@PathVariable String token) {
        return """
                <!DOCTYPE html>
                <html lang="pt-BR">
                <head><meta charset="UTF-8"><title>Smart Boarding — Cadastro</title></head>
                <body style="font-family: sans-serif; text-align: center; padding: 48px 24px;">
                    <h1>Smart Boarding</h1>
                    <p>Pra completar seu cadastro, instale o app Smart Boarding e abra este link de novo.</p>
                </body>
                </html>
                """;
    }
}
```

- [ ] **Step 2: `SecurityConfig`**

```java
                        .requestMatchers(HttpMethod.GET, "/register/{token}").permitAll()
```

- [ ] **Step 3: Rodar a suíte + testar manualmente**

Run: `cd smartboarding-api && ./mvnw -B --no-transfer-progress test` → PASS.
Com a API local de pé (`./run-local.sh`), `curl -s http://localhost:8080/register/qualquer-token` → confirma que retorna o HTML (não precisa de token válido, é só a página estática).

- [ ] **Step 4: Commitar**

```bash
git add smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/web/registration/RegistrationFallbackController.java \
        smartboarding-api/src/main/java/com/smartboarding/smartboarding_api/infrastructure/config/SecurityConfig.java
git commit -m "feat(api): página de fallback do App Link (app não instalado)"
```

---

### Task 9: Flutter — models (`InstitutionModel`, `RegistrationRequestModel`)

**Files:**
- Create: `smartboarding_app/lib/features/registration/models/institution_model.dart`
- Create: `smartboarding_app/lib/features/registration/models/registration_request_model.dart`

**Interfaces:**
- Produces: `InstitutionModel.fromJson`, `RegistrationRequestModel.fromJson` — consumidos pelas Tasks 10-14.

- [ ] **Step 1: `InstitutionModel`**

```dart
class InstitutionModel {
  final String id;
  final String name;
  final String? address;

  const InstitutionModel({required this.id, required this.name, this.address});

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }
}
```

- [ ] **Step 2: `RegistrationRequestModel` (pedido pendente, visão do admin)**

```dart
class RegistrationRequestModel {
  final String id;
  final String email;
  final String? fullName;
  final String? institutionId;
  final String createdAt;

  const RegistrationRequestModel({
    required this.id,
    required this.email,
    this.fullName,
    this.institutionId,
    required this.createdAt,
  });

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      institutionId: json['institutionId'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
```

- [ ] **Step 3: `flutter analyze` (sem teste próprio — são só modelos de dados, cobertos indiretamente pelos testes do provider na Task 11)**

Run: `cd smartboarding_app && flutter analyze`
Expected: sem erro nos dois arquivos novos.

- [ ] **Step 4: Commitar**

```bash
git add smartboarding_app/lib/features/registration/models
git commit -m "feat(app): models de Institution e RegistrationRequest"
```

---

### Task 10: Flutter — services (`InstitutionService`, `RegistrationService`)

**Files:**
- Create: `smartboarding_app/lib/features/registration/services/institution_service.dart`
- Create: `smartboarding_app/lib/features/registration/services/registration_service.dart`

**Interfaces:**
- Consumes: `InstitutionModel`, `RegistrationRequestModel` (Task 9), `DioClient.instance` (já existe).
- Produces: métodos consumidos pelo `RegistrationProvider` (Task 11).

- [ ] **Step 1: `InstitutionService`**

```dart
import '../../../core/services/dio_client.dart';
import '../models/institution_model.dart';

class InstitutionService {
  final _dio = DioClient.instance;

  Future<List<InstitutionModel>> getInstitutions() async {
    final response = await _dio.get('/api/institutions');
    final List data = response.data['data'] as List;
    return data
        .map((e) => InstitutionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createInstitution(
    String name,
    String? address,
    double? latitude,
    double? longitude,
  ) async {
    await _dio.post(
      '/api/institutions',
      data: {
        'name': name,
        if (address != null && address.isNotEmpty) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }
}
```

- [ ] **Step 2: `RegistrationService`**

```dart
import '../../../core/services/dio_client.dart';
import '../models/registration_request_model.dart';

class RegistrationService {
  final _dio = DioClient.instance;

  Future<void> generateInvite(String email) async {
    await _dio.post('/api/registration/invite', data: {'email': email});
  }

  Future<String> getInviteEmail(String token) async {
    final response = await _dio.get('/api/registration/invite/$token');
    return response.data['data']['email'] as String;
  }

  Future<void> submit({
    required String token,
    required String fullName,
    required String password,
    required String institutionId,
    String? course,
    String? phone,
    String? address,
    String? birthDate,
  }) async {
    await _dio.post(
      '/api/registration/$token/submit',
      data: {
        'fullName': fullName,
        'password': password,
        'institutionId': institutionId,
        if (course != null && course.isNotEmpty) 'course': course,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (birthDate != null) 'birthDate': birthDate,
      },
    );
  }

  Future<List<RegistrationRequestModel>> getPending() async {
    final response = await _dio.get('/api/registration/pending');
    final List data = response.data['data'] as List;
    return data
        .map((e) => RegistrationRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String id) async {
    await _dio.post('/api/registration/$id/approve');
  }

  Future<void> reject(String id) async {
    await _dio.post('/api/registration/$id/reject');
  }
}
```

- [ ] **Step 3: `flutter analyze` + commit**

Run: `cd smartboarding_app && flutter analyze` → sem erro.

```bash
git add smartboarding_app/lib/features/registration/services
git commit -m "feat(app): services de Institution e Registration (chamadas REST)"
```

---

### Task 11: Flutter — `RegistrationProvider` (TDD)

**Files:**
- Create: `smartboarding_app/lib/features/registration/providers/registration_provider.dart`
- Test: `smartboarding_app/test/unit/registration_provider_test.dart`

**Interfaces:**
- Consumes: `RegistrationService`, `InstitutionService` (Task 10), `AsyncValue`/`AsyncLoading`/`AsyncData`/`AsyncError` (`core/utils/async_value.dart`, já existe), `AppException` (`core/errors/app_exception.dart`, já existe).
- Produces: `RegistrationProvider` — consumido pelas Tasks 13-14.

- [ ] **Step 1: Escrever o teste (falhando)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartboarding_app/core/utils/async_value.dart';
import 'package:smartboarding_app/features/registration/models/institution_model.dart';
import 'package:smartboarding_app/features/registration/models/registration_request_model.dart';
import 'package:smartboarding_app/features/registration/providers/registration_provider.dart';
import 'package:smartboarding_app/features/registration/services/institution_service.dart';
import 'package:smartboarding_app/features/registration/services/registration_service.dart';

class _MockRegistrationService extends Mock implements RegistrationService {}
class _MockInstitutionService extends Mock implements InstitutionService {}

void main() {
  late _MockRegistrationService registrationService;
  late _MockInstitutionService institutionService;
  late RegistrationProvider provider;

  setUp(() {
    registrationService = _MockRegistrationService();
    institutionService = _MockInstitutionService();
    provider = RegistrationProvider(registrationService, institutionService);
  });

  test('loadInstitutions popula a lista', () async {
    when(() => institutionService.getInstitutions()).thenAnswer(
      (_) async => const [InstitutionModel(id: '1', name: 'Unifor')],
    );

    await provider.loadInstitutions();

    expect(provider.institutions, isA<AsyncData<List<InstitutionModel>>>());
  });

  test('loadPending popula a lista de pendentes', () async {
    when(() => registrationService.getPending()).thenAnswer(
      (_) async => const [
        RegistrationRequestModel(id: '1', email: 'a@x.com', createdAt: '2026-08-20'),
      ],
    );

    await provider.loadPending();

    expect(provider.pending, isA<AsyncData<List<RegistrationRequestModel>>>());
  });

  test('approve chama o service e recarrega pendentes', () async {
    when(() => registrationService.approve('1')).thenAnswer((_) async {});
    when(() => registrationService.getPending()).thenAnswer((_) async => const []);

    await provider.approve('1');

    verify(() => registrationService.approve('1')).called(1);
    verify(() => registrationService.getPending()).called(1);
  });

  test('reject chama o service e recarrega pendentes', () async {
    when(() => registrationService.reject('1')).thenAnswer((_) async {});
    when(() => registrationService.getPending()).thenAnswer((_) async => const []);

    await provider.reject('1');

    verify(() => registrationService.reject('1')).called(1);
    verify(() => registrationService.getPending()).called(1);
  });

  test('submit propaga erro como AppException legível', () async {
    when(() => registrationService.submit(
          token: any(named: 'token'),
          fullName: any(named: 'fullName'),
          password: any(named: 'password'),
          institutionId: any(named: 'institutionId'),
          course: any(named: 'course'),
          phone: any(named: 'phone'),
          address: any(named: 'address'),
          birthDate: any(named: 'birthDate'),
        )).thenThrow(Exception('falhou'));

    await provider.submit(token: 't', fullName: 'Maria', password: '123456', institutionId: 'inst-1');

    expect(provider.submitState, isA<AsyncError>());
  });
}
```

- [ ] **Step 2: Rodar e confirmar falha**

Run: `cd smartboarding_app && flutter test test/unit/registration_provider_test.dart`
Expected: FAIL — `RegistrationProvider` não existe.

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/async_value.dart';
import '../models/institution_model.dart';
import '../models/registration_request_model.dart';
import '../services/institution_service.dart';
import '../services/registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService;
  final InstitutionService _institutionService;

  AsyncValue<List<InstitutionModel>> _institutions = const AsyncLoading();
  AsyncValue<List<RegistrationRequestModel>> _pending = const AsyncLoading();
  AsyncValue<void> _submitState = const AsyncData(null);

  AsyncValue<List<InstitutionModel>> get institutions => _institutions;
  AsyncValue<List<RegistrationRequestModel>> get pending => _pending;
  AsyncValue<void> get submitState => _submitState;

  RegistrationProvider(this._registrationService, this._institutionService);

  Future<void> loadInstitutions() async {
    _institutions = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _institutionService.getInstitutions();
      _institutions = AsyncData(result);
    } catch (e) {
      _institutions = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> loadPending() async {
    _pending = const AsyncLoading();
    notifyListeners();
    try {
      final result = await _registrationService.getPending();
      _pending = AsyncData(result);
    } catch (e) {
      _pending = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }

  Future<void> approve(String id) async {
    await _registrationService.approve(id);
    await loadPending();
  }

  Future<void> reject(String id) async {
    await _registrationService.reject(id);
    await loadPending();
  }

  Future<void> submit({
    required String token,
    required String fullName,
    required String password,
    required String institutionId,
    String? course,
    String? phone,
    String? address,
    String? birthDate,
  }) async {
    _submitState = const AsyncLoading();
    notifyListeners();
    try {
      await _registrationService.submit(
        token: token,
        fullName: fullName,
        password: password,
        institutionId: institutionId,
        course: course,
        phone: phone,
        address: address,
        birthDate: birthDate,
      );
      _submitState = const AsyncData(null);
    } catch (e) {
      _submitState = AsyncError(AppException.fromError(e));
    }
    notifyListeners();
  }
}
```

- [ ] **Step 4: Confirmar que os testes passam**

Run: `cd smartboarding_app && flutter test test/unit/registration_provider_test.dart`
Expected: PASS — 5/5.

- [ ] **Step 5: Suíte inteira + commit**

Run: `cd smartboarding_app && flutter test` → PASS, sem regressão.

```bash
git add smartboarding_app/lib/features/registration/providers smartboarding_app/test/unit/registration_provider_test.dart
git commit -m "feat(app): RegistrationProvider (institutions, pending, approve/reject, submit)"
```

---

### Task 12: Flutter — criar instituição (ícone na AppBar do shell, só na aba Rotas)

**Files:**
- Modify: `smartboarding_app/lib/features/home/admin_home_screen.dart`

**Interfaces:**
- Consumes: `InstitutionService` (Task 10) — instanciado direto no diálogo, mesmo padrão simples de `routes_screen.dart` (sem provider dedicado pra essa mini-feature).

**Contexto:** nenhuma aba do `_AdminShell` (Listas/Rotas/Relatórios/Broadcast/Usuários) tem `AppBar` própria — todas usam só a `AppBar` compartilhada do shell ("Smart Boarding" + botão de sair). Dar uma `AppBar` só pra aba de Rotas empilharia duas barras. O ícone de criar instituição entra nessa mesma `AppBar` compartilhada, mas só renderiza quando `_index == 1` (aba Rotas selecionada) — decisão confirmada com o usuário.

- [ ] **Step 1: Import novo + diálogo de criar instituição**

No topo do arquivo, adicionar:

```dart
import '../../core/widgets/loading_filled_button.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../registration/services/institution_service.dart';
```

No fim do arquivo (novo widget privado, mesmo padrão de formulário do `LoginScreen`/`RouteFormScreen`):

```dart
// ─── Diálogo de criar instituição (mínimo pro dropdown do cadastro) ──────────

class _CreateInstitutionDialog extends StatefulWidget {
  const _CreateInstitutionDialog();

  @override
  State<_CreateInstitutionDialog> createState() => _CreateInstitutionDialogState();
}

class _CreateInstitutionDialogState extends State<_CreateInstitutionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _service = InstitutionService();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.createInstitution(
        _nameCtrl.text.trim(),
        _addressCtrl.text.trim(),
        null,
        null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Falha ao criar instituição: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova instituição'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Endereço (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        LoadingFilledButton(loading: _loading, onPressed: _submit, label: 'Criar'),
      ],
    );
  }
}
```

- [ ] **Step 2: Ação condicional na `AppBar` do `_AdminShell`**

Em `_AdminShellState.build`, trocar o `actions` fixo da `AppBar`:

```dart
      appBar: AppBar(
        title: const Text('Smart Boarding'),
        actions: [
          if (_index == 1)
            IconButton(
              icon: const Icon(Icons.school_outlined),
              tooltip: 'Nova instituição',
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const _CreateInstitutionDialog(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
```

- [ ] **Step 3: `flutter analyze` + smoke manual**

Run: `cd smartboarding_app && flutter analyze` → sem erro.
Rodar o app (`flutter run --dart-define=API_BASE_URL=...`), logar como admin, ir pra aba Rotas — confirmar que o ícone de instituição só aparece ali (some nas outras abas) —, criar uma instituição de teste, confirmar que `GET /api/institutions` (chamado na Task 13) passa a retornar ela.

- [ ] **Step 4: Commitar**

```bash
git add smartboarding_app/lib/features/home/admin_home_screen.dart
git commit -m "feat(app): cria instituição via ícone na AppBar (aba Rotas) — mínimo pro dropdown do cadastro"
```

---

### Task 13: Flutter — `RegisterScreen` (pública, fluxo do token)

**Files:**
- Create: `smartboarding_app/lib/features/registration/screens/register_screen.dart`

**Interfaces:**
- Consumes: `RegistrationProvider` (Task 11), `LoadingFilledButton` (`core/widgets/`, já existe), `RegistrationService.getInviteEmail` (validação inicial do token).

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_filled_button.dart';
import '../providers/registration_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String token;
  const RegisterScreen({super.key, required this.token});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedInstitutionId;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationProvider>().loadInstitutions();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedInstitutionId == null) return;
    final provider = context.read<RegistrationProvider>();
    await provider.submit(
      token: widget.token,
      fullName: _fullNameCtrl.text.trim(),
      password: _passwordCtrl.text,
      institutionId: _selectedInstitutionId!,
    );
    if (!mounted) return;
    if (provider.submitState is AsyncData) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Cadastro enviado, aguardando aprovação do administrador',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seu convite')),
      body: SafeArea(
        child: Consumer<RegistrationProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 16),
                    switch (provider.institutions) {
                      AsyncData(:final value) => DropdownButtonFormField<String>(
                          initialValue: _selectedInstitutionId,
                          decoration: const InputDecoration(labelText: 'Instituição', border: OutlineInputBorder()),
                          items: value
                              .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedInstitutionId = v),
                          validator: (v) => v == null ? 'Selecione a instituição' : null,
                        ),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                    const SizedBox(height: 24),
                    LoadingFilledButton(
                      loading: provider.submitState is AsyncLoading,
                      onPressed: _submit,
                      label: 'Enviar cadastro',
                    ),
                    if (provider.submitState case AsyncError(:final message))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(message, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

Import que falta no topo pro `switch`/`case` funcionar: `import '../../../core/utils/async_value.dart';`.

- [ ] **Step 2: `flutter analyze` + smoke manual**

Run: `cd smartboarding_app && flutter analyze` → sem erro.
Manual: gerar um convite de teste via `curl -X POST .../api/registration/invite`, pegar o token direto do banco (ou do log — `ResendEmailAdapter` loga o envio), navegar até `RegisterScreen(token: '<token>')` via um botão temporário de debug (removido antes do commit final, ou via `flutter run` apontando uma rota de teste) — confirma que carrega instituições, valida campos, envia e mostra a confirmação.

- [ ] **Step 3: Commitar**

```bash
git add smartboarding_app/lib/features/registration/screens/register_screen.dart
git commit -m "feat(app): RegisterScreen — formulário público de cadastro por convite"
```

---

### Task 14: Flutter — `RegistrationApprovalsScreen` (admin)

**Files:**
- Create: `smartboarding_app/lib/features/registration/screens/registration_approvals_screen.dart`

**Interfaces:**
- Consumes: `RegistrationProvider` (Task 11).

**Contexto:** vira a 6ª aba do `_AdminShell` (Task 14 Step 3), no mesmo `IndexedStack` de `RoutesScreen`/`ReportsScreen`/etc. — nenhuma delas tem `AppBar` própria (só a compartilhada do shell). Por isso o `Scaffold` abaixo **não** leva `appBar:`, mesmo padrão de `RoutesScreen`.

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/async_value.dart';
import '../providers/registration_provider.dart';

// Sem estado próprio — mesmo padrão de RoutesScreen. O load inicial da lista
// de pendentes é responsabilidade de quem cria o RegistrationProvider
// (Task 14 Step 3, `..loadPending()` no MultiProvider do AdminHomeScreen),
// não desta tela.
class RegistrationApprovalsScreen extends StatelessWidget {
  const RegistrationApprovalsScreen({super.key});

  Future<void> _confirmAndAct(BuildContext context, String id, {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Aprovar cadastro?' : 'Negar cadastro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<RegistrationProvider>();
    if (approve) {
      await provider.approve(id);
    } else {
      await provider.reject(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, _) {
          return switch (provider.pending) {
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            AsyncError(:final message) => Center(child: Text(message)),
            AsyncData(:final value) when value.isEmpty =>
              const Center(child: Text('Nenhuma solicitação pendente')),
            AsyncData(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final item = value[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(item.fullName ?? item.email),
                      subtitle: Text(item.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () => _confirmAndAct(context, item.id, approve: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            onPressed: () => _confirmAndAct(context, item.id, approve: false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze` + smoke manual**

Run: `cd smartboarding_app && flutter analyze` → sem erro.
Manual: com um pedido `PENDING` no banco (gerado pela Task 13), abrir a tela como admin, aprovar um e negar outro, confirmar que a lista atualiza e que aprovar realmente cria o `User` (checável via `GET /api/users`).

- [ ] **Step 3: Registrar como 6ª aba no `_AdminShell`**

`AdminHomeScreen` (`lib/features/home/admin_home_screen.dart`) hoje não tem painel de cartões — é uma `NavigationBar` de 5 abas (Listas/Rotas/Relatórios/Broadcast/Usuários). Adicionar "Cadastros" como 6ª, mesmo padrão das outras 5 (decisão confirmada com o usuário).

Imports novos no topo do arquivo:

```dart
import '../registration/providers/registration_provider.dart';
import '../registration/screens/registration_approvals_screen.dart';
import '../registration/services/institution_service.dart';
import '../registration/services/registration_service.dart';
```

Em `AdminHomeScreen.build`, adicionar ao `providers` do `MultiProvider` (junto dos outros 5 já existentes):

```dart
        ChangeNotifierProvider(
          create: (_) => RegistrationProvider(RegistrationService(), InstitutionService())..loadPending(),
        ),
```

Em `_AdminShellState.build`, adicionar o 6º item ao `IndexedStack.children`:

```dart
        children: const [
          _AdminListsTab(),
          RoutesScreen(),
          ReportsScreen(),
          BroadcastScreen(),
          UserManagementScreen(),
          RegistrationApprovalsScreen(),
        ],
```

E o 6º `NavigationDestination`:

```dart
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Cadastros',
          ),
```

- [ ] **Step 4: `flutter analyze` + smoke manual**

Run: `cd smartboarding_app && flutter analyze` → sem erro.
Rodar o app, logar como admin, confirmar que as 6 abas aparecem e que "Cadastros" abre sem duplicar `AppBar`.

- [ ] **Step 5: Commitar**

```bash
git add smartboarding_app/lib/features/registration/screens/registration_approvals_screen.dart smartboarding_app/lib/features/home/admin_home_screen.dart
git commit -m "feat(app): RegistrationApprovalsScreen — admin aprova/nega cadastros (6ª aba)"
```

---

### Task 15: Flutter — deep-link do convite (`app_links` + `main.dart` + config nativa)

**Files:**
- Modify: `smartboarding_app/pubspec.yaml`
- Modify: `smartboarding_app/lib/main.dart`
- Modify: `smartboarding_app/android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `RegisterScreen` (Task 13).
- Produces: nada consumido por outra task — é o último fio solto do fluxo (fecha "clicar no e-mail abre a tela").

- [ ] **Step 1: Adicionar a dependência**

Em `pubspec.yaml`, sob `dependencies:`, junto de `dio`/`provider`:

```yaml
  app_links: ^6.3.3
```

Run: `cd smartboarding_app && flutter pub get`

- [ ] **Step 2: Intent-filter Android — App Link pro domínio (autoVerify liga a verificação real quando o domínio existir; sem verificação, o link ainda funciona clicado dentro do app já aberto)**

Em `AndroidManifest.xml`, dentro do `<activity>` da `MainActivity`, depois do `intent-filter` do launcher existente:

```xml
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="smartboarding.app" android:pathPrefix="/register"/>
            </intent-filter>
```

(`smartboarding.app` é o placeholder do domínio final, mesmo usado no `link` do e-mail na Task 4 — trocar nos dois lugares junto quando o domínio real de deploy existir.)

- [ ] **Step 3: iOS — associated domain (`ios/Runner/Runner.entitlements`, criar se não existir)**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:smartboarding.app</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 4: Interceptar o link em `main.dart`**

```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/lists/providers/student_list_provider.dart';
import 'features/lists/services/list_service.dart';
import 'features/registration/providers/registration_provider.dart';
import 'features/registration/screens/register_screen.dart';
import 'features/registration/services/institution_service.dart';
import 'features/registration/services/registration_service.dart';

void main() {
  runApp(const SmartBoardingApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class SmartBoardingApp extends StatefulWidget {
  const SmartBoardingApp({super.key});

  @override
  State<SmartBoardingApp> createState() => _SmartBoardingAppState();
}

class _SmartBoardingAppState extends State<SmartBoardingApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenForInviteLinks();
  }

  // Convite chega como link externo (e-mail) — precisa interceptar tanto o
  // cold-start (app fechado, abriu pelo link) quanto o app já aberto em
  // segundo plano (RN13).
  void _listenForInviteLinks() {
    _appLinks.getInitialLink().then(_handleLink);
    _linkSub = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri? uri) {
    if (uri == null || !uri.path.startsWith('/register/')) return;
    final token = uri.pathSegments.last;
    // Quem clica o link do convite não está logado — RegisterScreen nunca
    // está dentro da árvore de providers do AdminHomeScreen, então precisa
    // do próprio RegistrationProvider aqui, não herdado de lugar nenhum.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => RegistrationProvider(RegistrationService(), InstitutionService()),
          child: RegisterScreen(token: token),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProxyProvider<AuthProvider, StudentListProvider>(
          create: (_) => StudentListProvider(ListService()),
          update: (_, auth, prev) {
            final email = auth.token?.email ?? '';
            prev!.setUserEmail(email);
            return prev;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Smart Boarding',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}
```

(`SmartBoardingApp` vira `StatefulWidget` — era `StatelessWidget`; o resto do `MultiProvider`/`MaterialApp` é o mesmo já existente, só movido pro `build` da nova classe de estado.)

- [ ] **Step 5: `flutter analyze` + `flutter test` (suíte inteira) + smoke manual**

Run: `cd smartboarding_app && flutter analyze && flutter test`
Expected: sem erro, sem regressão.

Manual (dev, sem domínio real — RN13 §5 da spec): `adb shell am start -a android.intent.action.VIEW -d "https://smartboarding.app/register/<token-de-teste>"` com o app rodando no emulador → confirma que abre `RegisterScreen` com o token certo.

- [ ] **Step 6: Commitar**

```bash
git add smartboarding_app/pubspec.yaml smartboarding_app/pubspec.lock smartboarding_app/lib/main.dart \
        smartboarding_app/android/app/src/main/AndroidManifest.xml smartboarding_app/ios/Runner/Runner.entitlements
git commit -m "feat(app): intercepta o link do convite (app_links) e abre o RegisterScreen"
```
