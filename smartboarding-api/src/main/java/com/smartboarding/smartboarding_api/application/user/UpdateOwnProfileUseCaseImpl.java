package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.in.UpdateOwnProfileUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class UpdateOwnProfileUseCaseImpl implements UpdateOwnProfileUseCase {

    private final UserRepositoryPort userRepository;

    public UpdateOwnProfileUseCaseImpl(UserRepositoryPort userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public void update(UUID userId, String phone, String course) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        if (phone != null) user.setPhone(limpo(phone));
        if (course != null) user.setCourse(limpo(course));

        userRepository.save(user);
    }

    /// Branco vira nulo. Guardar "" obrigaria missingForList() a conhecer duas
    /// formas de vazio, e uma delas escaparia -- deixando entrar na lista quem
    /// tem telefone em branco.
    private static String limpo(String valor) {
        String t = valor.trim();
        return t.isEmpty() ? null : t;
    }
}
