package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.in.JoinRouteUseCase;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class JoinRouteUseCaseImpl implements JoinRouteUseCase {

    private final RouteInviteCodeRepositoryPort codeRepository;
    private final RouteMemberRepositoryPort memberRepository;
    private final UserInstitutionRepositoryPort userInstitutionRepository;
    private final Clock clock;

    public JoinRouteUseCaseImpl(RouteInviteCodeRepositoryPort codeRepository,
                                RouteMemberRepositoryPort memberRepository,
                                UserInstitutionRepositoryPort userInstitutionRepository,
                                Clock clock) {
        this.codeRepository = codeRepository;
        this.memberRepository = memberRepository;
        this.userInstitutionRepository = userInstitutionRepository;
        this.clock = clock;
    }

    @Override
    @Transactional
    public RouteMember join(UUID userId, String code) {
        // Normaliza porque o código é digitado à mão: espaço colado e minúscula
        // são erro de digitação, não código errado.
        String normalized = code == null ? "" : code.trim().toUpperCase();
        if (normalized.isEmpty()) {
            throw new BadRequestException("INVALID_CODE", "Informe o código da rota.");
        }

        // A instituicao e o que diz onde o aluno desce e em que contagem ele
        // entra. Deixar entrar sem ela poria na lista alguem que o motorista nao
        // sabe onde deixar.
        if (userInstitutionRepository.findAllByUserId(userId).isEmpty()) {
            throw new BadRequestException("PROFILE_INCOMPLETE",
                    "Defina sua instituição no perfil antes de entrar em uma rota.");
        }

        RouteInviteCode invite = codeRepository.findByCode(normalized)
                .orElseThrow(() -> new BadRequestException("INVALID_CODE",
                        "Código inválido."));

        LocalDateTime now = LocalDateTime.now(clock);
        // Expirado e revogado viram mensagens diferentes de propósito: o aluno
        // precisa saber se pede um código novo ou se errou a digitação. O código
        // não é dado pessoal, então distinguir não entrega nada a ninguém.
        if (invite.isRevoked()) {
            throw new BadRequestException("CODE_REVOKED",
                    "Esse código foi cancelado. Peça um novo ao administrador.");
        }
        if (invite.isExpired(now)) {
            throw new BadRequestException("CODE_EXPIRED",
                    "Esse código expirou. Peça um novo ao administrador.");
        }

        if (memberRepository.existsByUserIdAndRouteId(userId, invite.getRouteId())) {
            throw new ConflictException("ALREADY_MEMBER", "Você já está nessa rota.");
        }

        RouteMember saved = memberRepository.save(RouteMember.builder()
                .userId(userId)
                .routeId(invite.getRouteId())
                .inviteCodeId(invite.getId())
                .build());
        log.info("Usuário {} entrou na rota {} pelo código", userId, invite.getRouteId());
        return saved;
    }

    @Override
    @Transactional
    public void leave(UUID userId, UUID routeId) {
        memberRepository.deleteByUserIdAndRouteId(userId, routeId);
        log.info("Usuário {} saiu da rota {}", userId, routeId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UUID> routesOf(UUID userId) {
        return memberRepository.findAllByUserId(userId).stream()
                .map(RouteMember::getRouteId)
                .toList();
    }
}
