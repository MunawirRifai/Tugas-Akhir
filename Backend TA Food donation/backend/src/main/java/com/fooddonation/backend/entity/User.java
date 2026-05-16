package com.fooddonation.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(nullable = false, unique = true)
    private String phone;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String password;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "is_verified")
    private Boolean isVerified = false;

    @Column(name = "verification_code")
    private String verificationCode;

    @Column(name = "verification_expired_at")
    private LocalDateTime verificationExpiredAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "role")
    private String role = "ROLE_USER";

    @Column(name = "is_banned")
    private Boolean isBanned = false;

    @Column(name = "timeout_until")
    private LocalDateTime timeoutUntil;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}