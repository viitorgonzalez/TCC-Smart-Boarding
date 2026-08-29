package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken;
import com.smartboarding.smartboarding_api.domain.notification.port.in.RegisterDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.RemoveDeviceTokenUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
public class DeviceTokenUseCaseImpl implements RegisterDeviceTokenUseCase, RemoveDeviceTokenUseCase {

    private final DeviceTokenRepositoryPort deviceTokenRepository;
    private final UserRepositoryPort userRepository;

    public DeviceTokenUseCaseImpl(DeviceTokenRepositoryPort deviceTokenRepository,
                                  UserRepositoryPort userRepository) {
        this.deviceTokenRepository = deviceTokenRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public void execute(UUID userId, String token, String platform) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        deviceTokenRepository.findByUserIdAndToken(userId, token).ifPresentOrElse(
                existing -> {
                    deviceTokenRepository.save(existing);
                    log.info("Token FCM atualizado para usuário {}", userId);
                },
                () -> {
                    DeviceToken newToken = DeviceToken.builder()
                            .user(user)
                            .token(token)
                            .platform(platform)
                            .build();
                    deviceTokenRepository.save(newToken);
                    log.info("Token FCM registrado para usuário {} ({})", userId, platform);
                }
        );
    }

    @Override
    @Transactional
    public void execute(UUID userId) {
        deviceTokenRepository.deleteByUserId(userId);
        log.info("Tokens FCM removidos para usuário {}", userId);
    }
}
