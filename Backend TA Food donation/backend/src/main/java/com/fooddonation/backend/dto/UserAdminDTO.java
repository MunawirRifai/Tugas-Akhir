package com.fooddonation.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserAdminDTO {
    private Long id;
    private String fullName;
    private String email;
    private String phone;
    private String photoUrl;
    private String role;
    private Boolean isBanned;
    private LocalDateTime timeoutUntil;
    private Long totalDonations;
    private Long totalClaims;
}
