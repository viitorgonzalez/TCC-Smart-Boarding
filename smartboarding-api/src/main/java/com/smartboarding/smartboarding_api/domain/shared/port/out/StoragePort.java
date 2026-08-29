package com.smartboarding.smartboarding_api.domain.shared.port.out;

public interface StoragePort {

    String uploadAndGetPublicUrl(byte[] content, String contentType, String fileName);
}
