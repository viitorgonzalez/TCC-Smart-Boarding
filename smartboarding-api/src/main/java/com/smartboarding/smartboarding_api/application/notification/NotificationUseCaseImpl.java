package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.SendBroadcastUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.out.FcmPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class NotificationUseCaseImpl implements SendBroadcastUseCase, SendToUserUseCase {

    private final FcmPort fcmPort;
    private final DeviceTokenRepositoryPort deviceTokenRepository;

    public NotificationUseCaseImpl(FcmPort fcmPort, DeviceTokenRepositoryPort deviceTokenRepository) {
        this.fcmPort = fcmPort;
        this.deviceTokenRepository = deviceTokenRepository;
    }

    @Override
    public void execute(String title, String body) {
        List<String> tokens = deviceTokenRepository.findAllTokens();
        if (tokens.isEmpty()) {
            log.info("Broadcast ignorado: nenhum dispositivo registrado.");
            return;
        }
        fcmPort.sendToTokens(tokens, title, body);
        log.info("Broadcast enviado para {} dispositivos: {}", tokens.size(), title);
    }

    @Override
    public void execute(UUID userId, String title, String body) {
        List<String> tokens = deviceTokenRepository.findByUserId(userId)
                .stream()
                .map(dt -> dt.getToken())
                .toList();

        if (tokens.isEmpty()) {
            log.info("Notificação ignorada: usuário {} sem dispositivos registrados.", userId);
            return;
        }
        fcmPort.sendToTokens(tokens, title, body);
        log.info("Notificação enviada para usuário {}: {}", userId, title);
    }
}
