package com.mamacare.user;

import java.time.Instant;

public record UserDto(Long id, String fullName, String email, Role role, AccountStatus status, String phone,
                      Instant createdAt) {
    public static UserDto from(User u) {
        return new UserDto(u.getId(), u.getFullName(), u.getEmail(), u.getRole(), u.getStatus(), u.getPhone(),
                u.getCreatedAt());
    }
}
