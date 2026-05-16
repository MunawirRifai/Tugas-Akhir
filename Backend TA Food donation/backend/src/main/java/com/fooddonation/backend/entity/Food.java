package com.fooddonation.backend.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "foods")
@Getter
@Setter
public class Food {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "food_name", nullable = false)
    private String foodName;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    // Stok saat ini (berkurang saat diklaim, bertambah kembali saat dibatalkan)
    @Column(nullable = false)
    private Integer quantity;

    // Stok awal saat pertama kali dipost (tidak berubah)
    @Column(name = "original_quantity", nullable = false)
    private Integer originalQuantity;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private String address;

    @Column(name = "photo_url")
    private String photoUrl;

    @Column(name = "expired_at", nullable = false)
    private LocalDateTime expiredAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    private String status;

    private Long claimedBy;

    // Jumlah yang sedang dalam proses pengambilan (oleh claimedBy)
    @Column(name = "claimed_quantity")
    private Integer claimedQuantity;

    public Long getClaimedBy() {
        return claimedBy;
    }

    public void setClaimedBy(Long claimedBy) {
        this.claimedBy = claimedBy;
    }
}
