package com.mamacare.common;

import com.mamacare.user.AccountStatus;
import com.mamacare.user.Role;

/** Authenticated principal. Built from the DATABASE on every request, never from token claims. */
public record AuthUser(Long id, String email, Role role, AccountStatus status) {
}
