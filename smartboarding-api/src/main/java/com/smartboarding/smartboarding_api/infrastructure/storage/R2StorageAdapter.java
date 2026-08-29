package com.smartboarding.smartboarding_api.infrastructure.storage;

import com.smartboarding.smartboarding_api.domain.shared.port.out.StoragePort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.util.UUID;

@Slf4j
@Component
public class R2StorageAdapter implements StoragePort {

    private final S3Client s3Client;
    private final String bucketName;
    private final String publicBaseUrl;

    public R2StorageAdapter(
            S3Client s3Client,
            @Value("${r2.bucket.name:}") String bucketName,
            @Value("${r2.public.base.url:}") String publicBaseUrl) {
        this.s3Client = s3Client;
        this.bucketName = bucketName;
        this.publicBaseUrl = publicBaseUrl;
    }

    @Override
    public String uploadAndGetPublicUrl(byte[] content, String contentType, String fileName) {
        String key = UUID.randomUUID() + "-" + fileName;
        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .contentType(contentType)
                        .build(),
                RequestBody.fromBytes(content));
        String url = publicBaseUrl + "/" + key;
        log.info("Imagem enviada pro R2: {}", url);
        return url;
    }
}
