package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageRouteInviteCodeUseCase;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class RouteInviteCodeUseCaseImpl implements ManageRouteInviteCodeUseCase {

    /// Sem O/0, I/1 e L: o código é lido em voz alta e copiado do quadro, e esses
    /// pares são a fonte clássica de erro de digitação.
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

    /// Colisão é improvável, mas o código é UNIQUE no banco: sem o retry, o azar
    /// viraria erro 500 na cara do admin.
    private static final int MAX_GENERATION_ATTEMPTS = 10;

    private final RouteInviteCodeRepositoryPort codeRepository;
    private final RouteMemberRepositoryPort memberRepository;
    private final RouteRepositoryPort routeRepository;
    private final Clock clock;
    private final SecureRandom random = new SecureRandom();
    private final int codeLength;
    private final long defaultValidityDays;

    public RouteInviteCodeUseCaseImpl(RouteInviteCodeRepositoryPort codeRepository,
                                      RouteMemberRepositoryPort memberRepository,
                                      RouteRepositoryPort routeRepository,
                                      Clock clock,
                                      @Value("${app.route-invite.code-length}") int codeLength,
                                      @Value("${app.route-invite.default-validity-days}") long defaultValidityDays) {
        this.codeRepository = codeRepository;
        this.memberRepository = memberRepository;
        this.routeRepository = routeRepository;
        this.clock = clock;
        this.codeLength = codeLength;
        this.defaultValidityDays = defaultValidityDays;
    }

    @Override
    @Transactional
    public RouteInviteCode generate(UUID routeId, LocalDateTime expiresAt, UUID adminId) {
        routeRepository.findById(routeId)
                .orElseThrow(() -> new NotFoundException("Rota não encontrada com ID: " + routeId));

        LocalDateTime now = LocalDateTime.now(clock);
        LocalDateTime validUntil = expiresAt != null
                ? expiresAt
                : now.plusDays(defaultValidityDays);
        if (!validUntil.isAfter(now)) {
            throw new BadRequestException("INVALID_EXPIRY",
                    "A expiração precisa ser no futuro.");
        }

        RouteInviteCode saved = codeRepository.save(RouteInviteCode.builder()
                .routeId(routeId)
                .code(generateUniqueCode())
                .expiresAt(validUntil)
                .createdBy(adminId)
                .build());
        log.info("Código de convite gerado para a rota {}", routeId);
        return saved;
    }

    @Override
    @Transactional
    public RouteInviteCode revoke(UUID codeId) {
        RouteInviteCode code = codeRepository.findById(codeId)
                .orElseThrow(() -> new NotFoundException("Código não encontrado"));
        // Revogar de novo não é erro: o admin pode clicar duas vezes, e o
        // resultado que ele quer já está valendo.
        if (code.getRevokedAt() == null) {
            code.setRevokedAt(LocalDateTime.now(clock));
            code = codeRepository.save(code);
            log.info("Código de convite {} revogado", codeId);
        }
        return code;
    }

    @Override
    @Transactional(readOnly = true)
    public List<RouteInviteCode> listByRoute(UUID routeId) {
        return codeRepository.findAllByRouteId(routeId);
    }

    @Override
    @Transactional(readOnly = true)
    public long countUses(UUID codeId) {
        return memberRepository.countByInviteCodeId(codeId);
    }

    private String generateUniqueCode() {
        for (int attempt = 0; attempt < MAX_GENERATION_ATTEMPTS; attempt++) {
            String candidate = randomCode();
            if (!codeRepository.existsByCode(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException(
                "Não foi possível gerar um código único em " + MAX_GENERATION_ATTEMPTS + " tentativas");
    }

    private String randomCode() {
        StringBuilder sb = new StringBuilder(codeLength);
        for (int i = 0; i < codeLength; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
