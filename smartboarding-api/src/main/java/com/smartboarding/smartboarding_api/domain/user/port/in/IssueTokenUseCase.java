package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.application.user.AuthToken;
import com.smartboarding.smartboarding_api.domain.user.entity.User;

public interface IssueTokenUseCase {
    AuthToken issueFor(User user);
}
