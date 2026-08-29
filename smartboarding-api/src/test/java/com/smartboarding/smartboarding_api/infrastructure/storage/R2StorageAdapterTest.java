package com.smartboarding.smartboarding_api.infrastructure.storage;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import software.amazon.awssdk.services.s3.model.S3Exception;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class R2StorageAdapterTest {

    @Mock
    private S3Client s3Client;

    @Test
    void uploadAndGetPublicUrl_retornaUrlComBaseConfigurada() {
        var adapter = new R2StorageAdapter(s3Client, "bucket", "https://cdn.example.com");
        when(s3Client.putObject(any(PutObjectRequest.class), any(software.amazon.awssdk.core.sync.RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        String url = adapter.uploadAndGetPublicUrl("conteudo".getBytes(), "image/png", "foto.png");

        assertThat(url).startsWith("https://cdn.example.com/");
        assertThat(url).endsWith("-foto.png");
    }

    @Test
    void uploadAndGetPublicUrl_propagaFalhaDoR2() {
        var adapter = new R2StorageAdapter(s3Client, "bucket", "https://cdn.example.com");
        when(s3Client.putObject(any(PutObjectRequest.class), any(software.amazon.awssdk.core.sync.RequestBody.class)))
                .thenThrow(S3Exception.builder().message("falha no upload").build());

        assertThatThrownBy(() -> adapter.uploadAndGetPublicUrl("x".getBytes(), "image/png", "foto.png"))
                .isInstanceOf(S3Exception.class);
    }
}
