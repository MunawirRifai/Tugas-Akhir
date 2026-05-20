package com.fooddonation.backend.repository;

import com.fooddonation.backend.entity.Food;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

import java.util.List;

public interface FoodRepository extends JpaRepository<Food, Long> {

    List<Food> findByUserIdOrderByIdDesc(Long userId);

    List<Food> findByStatusOrStatusIsNull(String status);

    List<Food> findByStatusIn(List<String> statuses);

    List<Food> findByClaimedByAndStatus(Long claimedBy, String status);

    List<Food> findByClaimedByAndStatusOrderByIdDesc(Long claimedBy, String status);

    List<Food> findByClaimedByOrderByIdDesc(Long claimedBy);

    long countByUserId(Long userId);

    long countByClaimedByAndStatus(Long claimedBy, String status);
}