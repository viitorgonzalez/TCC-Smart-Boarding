package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.CreateRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.DeleteRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.FindRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class RouteUseCaseImpl implements CreateRouteUseCase, FindRouteUseCase,
        UpdateRouteUseCase, DeleteRouteUseCase {

    private final RouteRepositoryPort routeRepository;

    public RouteUseCaseImpl(RouteRepositoryPort routeRepository) {
        this.routeRepository = routeRepository;
    }

    @Override
    @Transactional
    public Route execute(Route route) {
        if (routeRepository.existsByName(route.getName())) {
            throw new ConflictException("ROUTE_ALREADY_EXISTS", "Rota já cadastrada: " + route.getName());
        }
        Route saved = routeRepository.save(route);
        log.info("Rota criada: {}", saved.getName());
        return saved;
    }

    @Override
    public List<Route> findAllActive() {
        return routeRepository.findAllByIsActiveTrue();
    }

    @Override
    public Route findById(UUID id) {
        return routeRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Rota não encontrada com ID: " + id));
    }

    @Override
    @Transactional
    public Route execute(UUID id, Route route) {
        Route existing = findById(id);
        if (routeRepository.existsByNameAndIdNot(route.getName(), id)) {
            throw new ConflictException("ROUTE_NAME_CONFLICT", "Nome de rota já utilizado: " + route.getName());
        }
        existing.setName(route.getName());
        existing.setDescription(route.getDescription());
        return routeRepository.save(existing);
    }

    @Override
    @Transactional
    public void execute(UUID id) {
        Route route = findById(id);
        route.setActive(false);
        routeRepository.save(route);
        log.info("Rota desativada: {}", route.getName());
    }
}
