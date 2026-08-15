package com.smartboarding.smartboarding_api.infrastructure.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

import java.net.URI;

@Configuration
public class R2Config {

    // O construtor do S3Client valida credencial não-branco na hora (AwsBasicCredentials.create),
    // então sem R2 configurado (dev/CI antes da Fase 4 consumir StoragePort) o app não sobe sem
    // um default não-branco — falha real só acontece na primeira chamada (putObject), não no
    // boot. Default vem de application.properties (${R2_ACCESS_KEY_ID:unconfigured} etc.).
    @Bean
    public S3Client r2Client(
            @Value("${r2.account.id:}") String accountId,
            @Value("${r2.access.key.id:}") String accessKeyId,
            @Value("${r2.secret.access.key:}") String secretAccessKey) {
        return S3Client.builder()
                .endpointOverride(URI.create("https://" + accountId + ".r2.cloudflarestorage.com"))
                .region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(accessKeyId, secretAccessKey)))
                .build();
    }
}
