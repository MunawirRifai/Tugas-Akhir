package com.fooddonation.backend.controller;

import com.fooddonation.backend.dto.CreateFoodRequest;
import com.fooddonation.backend.response.ApiResponse;
import com.fooddonation.backend.service.FoodService;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/v1/foods")
public class FoodController {

    private final FoodService foodService;

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<?> createFood(
            Authentication authentication,
            @RequestParam("foodName") String foodName,
            @RequestParam("description") String description,
            @RequestParam("quantity") Integer quantity,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude,
            @RequestParam("address") String address,
            @RequestParam("expiredAt") String expiredAt,
            @RequestParam("photo") MultipartFile photo) throws Exception {

        Long userId = Long.parseLong(authentication.getName());

        CreateFoodRequest request = new CreateFoodRequest();
        request.setFoodName(foodName);
        request.setDescription(description);
        request.setQuantity(quantity);
        request.setLatitude(latitude);
        request.setLongitude(longitude);
        request.setAddress(address);
        request.setExpiredAt(expiredAt);

        Map<String, Object> data = foodService.createFood(userId, request, photo);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Food created")
                        .data(data)
                        .build());
    }

    @GetMapping
    public ResponseEntity<?> getFoods() {

        List<Map<String, Object>> data = foodService.getAllFoods();

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Foods loaded")
                        .data(data)
                        .build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteFood(
            @PathVariable Long id,
            Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());

        foodService.deleteFood(id, userId);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Food deleted")
                        .build());
    }

    @GetMapping("/history")
    public ResponseEntity<?> getHistory(Authentication authentication) {

        Long userId = Long.parseLong(authentication.getName());

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .data(foodService.getHistory(userId))
                        .build());
    }

    @PutMapping("/{id}/pick")
    public ResponseEntity<?> pickFood(
            @PathVariable Long id,
            @RequestParam(value = "quantity", defaultValue = "1") Integer quantity,
            Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());

        foodService.pickFood(id, userId, quantity);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Food picked")
                        .build());
    }

    @PutMapping("/{id}/confirm")
    public ResponseEntity<?> confirmPickup(@PathVariable Long id) {
        foodService.confirmPickup(id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<?> cancelPickup(@PathVariable Long id) {
        foodService.cancelPickup(id);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/history/donation")
    public ResponseEntity<?> clearDonationHistory(
            Authentication authentication) {

        Long userId = Long.parseLong(authentication.getName());

        foodService.clearDonationHistory(userId);

        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/history/claim")
    public ResponseEntity<?> clearClaimHistory(
            Authentication authentication) {

        Long userId = Long.parseLong(authentication.getName());

        foodService.clearClaimHistory(userId);

        return ResponseEntity.ok().build();
    }

    // get data tanpa jwt
    @GetMapping("/test/public")
    public ResponseEntity<?> getFoodsWithoutJwt() {

        List<Map<String, Object>> data = foodService.getAllFoods();

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Foods loaded without JWT")
                        .data(data)
                        .build());
    }

    // rubah data tanpa jwt
    @PutMapping("/test/public/{id}/pick")
    public ResponseEntity<?> pickFoodWithoutJwt(
            @PathVariable Long id,
            @RequestParam(value = "quantity", defaultValue = "1") Integer quantity,
            @RequestParam Long userId) {

        foodService.pickFood(id, userId, quantity);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Food picked without JWT")
                        .build());
    }

    // post data tanpa jwt
    // tambah makanan tanpa jwt
    @PostMapping(value = "/test/public", consumes = "multipart/form-data")
    public ResponseEntity<?> createFoodWithoutJwt(

            @RequestParam Long userId,

            @RequestParam("foodName") String foodName,
            @RequestParam("description") String description,
            @RequestParam("quantity") Integer quantity,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude,
            @RequestParam("address") String address,
            @RequestParam("expiredAt") String expiredAt,
            @RequestParam("photo") MultipartFile photo

    ) throws Exception {

        CreateFoodRequest request = new CreateFoodRequest();

        request.setFoodName(foodName);
        request.setDescription(description);
        request.setQuantity(quantity);
        request.setLatitude(latitude);
        request.setLongitude(longitude);
        request.setAddress(address);
        request.setExpiredAt(expiredAt);

        Map<String, Object> data = foodService.createFood(userId, request, photo);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Food created without JWT")
                        .data(data)
                        .build());
    }
}