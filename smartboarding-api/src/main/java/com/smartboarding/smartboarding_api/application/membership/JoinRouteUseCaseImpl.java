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

    /// A rota decide quem entra: a lista de instituições atendidas deixa de ser
    /// enfeite e passa a valer na porta.
    ///
    /// Antes só o código era conferido, então um código aberto deixava entrar
    /// aluno de instituição que aquela rota nem atende -- a lista existia na
    /// tela do admin e não significava nada na entrada.
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
            // Rota sem instituição nenhuma ainda não atende ninguém. Recusar
            // aqui é mais honesto que deixar entrar e o aluno descobrir depois
            // que não aparece em contagem alguma.
            throw new BadRequestException("ROUTE_WITHOUT_INSTITUTION",
                    "Essa rota ainda não atende nenhuma instituição. Fale com o administrador.");
        }

        boolean alguma = minhas.stream()
                .anyMatch(i -> atendidas.contains(i.getInstitutionId()));
        if (!alguma) {
            throw new BadRequestException("INSTITUTION_NOT_SERVED",
                    "Essa rota não atende a sua instituição. Confira o perfil ou "
                            + "peça o código da rota certa.");
        }
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

        var minhasInstituicoes = userInstitutionRepository.findAllByUserId(userId);

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

        conferirInstituicao(invite.getRouteId(), minhasInstituicoes);

        // Código preso a uma instituição só serve a quem a declarou. Nulo é o
        // código aberto: vale pra qualquer um dos que a rota atende, e é o que
        // os códigos antigos continuam sendo.
        UUID exigida = invite.getInstitutionId();
        if (exigida != null
                && minhasInstituicoes.stream().noneMatch(i -> exigida.equals(i.getInstitutionId()))) {
            String nome = institutionRepository.findById(exigida)
                    .map(Institution::getName)
                    .orElse("outra instituição");
            throw new BadRequestException("INSTITUTION_MISMATCH",
                    "Esse código é só para alunos de " + nome
                            + ". Adicione essa instituição no seu perfil ou peça outro código.");
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
