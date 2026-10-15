package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.in.JoinRouteUseCase;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.UUID;

@Slf4j
@Service
public class JoinRouteUseCaseImpl implements JoinRouteUseCase {

    private final RouteInviteCodeRepositoryPort codeRepository;
    private final RouteMemberRepositoryPort memberRepository;
    private final UserInstitutionRepositoryPort userInstitutionRepository;
    private final InstitutionRepositoryPort institutionRepository;
    private final RouteRepositoryPort routeRepository;
    private final Clock clock;

    public JoinRouteUseCaseImpl(RouteInviteCodeRepositoryPort codeRepository,
                                RouteMemberRepositoryPort memberRepository,
                                UserInstitutionRepositoryPort userInstitutionRepository,
                                InstitutionRepositoryPort institutionRepository,
                                RouteRepositoryPort routeRepository,
                                Clock clock) {
        this.codeRepository = codeRepository;
        this.memberRepository = memberRepository;
        this.userInstitutionRepository = userInstitutionRepository;
        this.institutionRepository = institutionRepository;
        this.routeRepository = routeRepository;
        this.clock = clock;
    }

    private void conferirInstituicao(UUID routeId, List<UserInstitution> minhas) {
        Route rota = routeRepository.findById(routeId)
                .orElseThrow(() -> new NotFoundException("Rota não encontrada"));

        if (minhas.isEmpty()) {
            if (rota.isAdmitsNoInstitution()) return;
            throw new BadRequestException("PROFILE_INCOMPLETE",
                    "Defina sua instituição no perfil antes de entrar em uma rota.");
        }

        Set<UUID> atendidas = institutionRepository.findAll().stream()
                .filter(i -> routeId.equals(i.getRouteId()))
                .map(Institution::getId)
                .collect(Collectors.toSet());

        if (atendidas.isEmpty()) {
            throw new BadRequestException("ROUTE_WITHOUT_INSTITUTION",
                    "Essa rota ainda não atende nenhuma instituição. Fale com o administrador.");
        }

        boolean alguma = minhas.stream()
                .anyMatch(i -> atendidas.contains(i.getInstitutionId()));
        if (!alguma) {
            // Mensagem generica de proposito: dizer que o codigo e de outra instituicao
            // confirmaria a quem esta adivinhando codigos que aquele existe e e valido.
            log.info("Código recusado: a rota {} não atende nenhuma instituição do usuário", routeId);
            throw new BadRequestException("INVALID_CODE", "Código inválido.");
        }
    }

    @Override
    @Transactional
    public RouteMember join(UUID userId, String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase();
        if (normalized.isEmpty()) {
            throw new BadRequestException("INVALID_CODE", "Informe o código da rota.");
        }

        var minhasInstituicoes = userInstitutionRepository.findAllByUserId(userId);
        RouteInviteCode invite = codeRepository.findByCode(normalized)
                .orElseThrow(() -> new BadRequestException("INVALID_CODE",
                        "Código inválido."));

        LocalDateTime now = LocalDateTime.now(clock);
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

        conferirInstituicao(invite.getRouteId(), minhasInstituicoes);

        UUID exigida = invite.getInstitutionId();
        if (exigida != null
                && minhasInstituicoes.stream().noneMatch(i -> exigida.equals(i.getInstitutionId()))) {
            log.info("Código recusado: exige a instituição {} e o usuário {} não a tem",
                    exigida, userId);
            throw new BadRequestException("INVALID_CODE", "Código inválido.");
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
