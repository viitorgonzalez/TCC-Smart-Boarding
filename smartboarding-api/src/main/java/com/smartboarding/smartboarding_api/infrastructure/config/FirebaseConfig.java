package com.smartboarding.smartboarding_api.infrastructure.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.credentials.path:}")
    private String credentialsPath;

    @PostConstruct
    public void initialize() {
        if (credentialsPath == null || credentialsPath.isBlank()) {
            log.warn("Firebase não configurado: FIREBASE_CREDENTIALS_PATH não definido. Notificações FCM desabilitadas.");
            return;
        }

        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        try (FileInputStream serviceAccount = new FileInputStream(credentialsPath)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("Firebase inicializado com sucesso.");
        } catch (IOException e) {
            log.error("Erro ao inicializar Firebase: {}", e.getMessage());
        }
    }
}
