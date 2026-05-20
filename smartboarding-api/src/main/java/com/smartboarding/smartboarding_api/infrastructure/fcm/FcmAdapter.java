package com.smartboarding.smartboarding_api.infrastructure.fcm;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.smartboarding.smartboarding_api.domain.notification.port.out.FcmPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
public class FcmAdapter implements FcmPort {

    @Override
    public void sendToTokens(List<String> tokens, String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("Firebase não inicializado. Notificação ignorada: {}", title);
            return;
        }

        List<Message> messages = tokens.stream()
                .map(token -> Message.builder()
                        .setToken(token)
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .build())
                .toList();

        try {
            var result = FirebaseMessaging.getInstance().sendEach(messages);
            log.info("FCM: {} enviados, {} falhas. Título: '{}'",
                    result.getSuccessCount(), result.getFailureCount(), title);
        } catch (Exception e) {
            log.error("Erro ao enviar notificações FCM: {}", e.getMessage());
        }
    }
}
