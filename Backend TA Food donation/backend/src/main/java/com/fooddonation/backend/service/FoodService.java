package com.fooddonation.backend.service;

import com.fooddonation.backend.dto.CreateFoodRequest;
import com.fooddonation.backend.entity.Food;
import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.repository.FoodRepository;
import com.fooddonation.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FoodService {

    private final FoodRepository foodRepository;
    private final UserRepository userRepository;

    public Map<String, Object> createFood(
            Long userId,
            CreateFoodRequest request,
            MultipartFile photo) throws Exception {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));

        if (user.getTimeoutUntil() != null && user.getTimeoutUntil().isAfter(LocalDateTime.now())) {
            throw new RuntimeException("ACCOUNT_TIMEOUT");
        }

        String uploadDir = System.getProperty("user.dir") + "/uploads/foods/";
        File folder = new File(uploadDir);

        if (!folder.exists()) {
            folder.mkdirs();
        }

        String filename = UUID.randomUUID() + "_" + photo.getOriginalFilename();
        File destination = new File(uploadDir + filename);
        photo.transferTo(destination);

        String photoUrl = "http://localhost:8080/uploads/foods/" + filename;

        Food food = new Food();
        food.setUser(user);
        food.setFoodName(request.getFoodName());
        food.setDescription(request.getDescription());
        food.setQuantity(request.getQuantity());
        food.setOriginalQuantity(request.getQuantity()); // simpan stok awal
        food.setLatitude(request.getLatitude());
        food.setLongitude(request.getLongitude());
        food.setAddress(request.getAddress());
        food.setPhotoUrl(photoUrl);
        food.setExpiredAt(LocalDateTime.parse(request.getExpiredAt()));

        food.setStatus("POSTED");
        food.setClaimedBy(null);
        food.setClaimedQuantity(0);
        foodRepository.save(food);

        Map<String, Object> data = new HashMap<>();
        data.put("id", food.getId());
        data.put("food_name", food.getFoodName());
        data.put("description", food.getDescription());
        data.put("latitude", food.getLatitude());
        data.put("longitude", food.getLongitude());
        data.put("photo_url", food.getPhotoUrl());
        data.put("quantity", food.getQuantity());
        data.put("original_quantity", food.getOriginalQuantity());
        data.put("expired_at", food.getExpiredAt().toString());

        return data;
    }

    public List<Map<String, Object>> getAllFoods() {
        List<Food> foods = foodRepository.findByStatusIn(
                List.of("POSTED", "ON_THE_WAY"));

        DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

        return foods.stream()
                .filter(food -> food.getStatus() == null ||
                        food.getStatus().equals("POSTED") ||
                        food.getStatus().equals("ON_THE_WAY"))
                .map(food -> {
                    Map<String, Object> item = new HashMap<>();

                    item.put("id", food.getId());
                    item.put("food_name", food.getFoodName());
                    item.put("description", food.getDescription());
                    item.put("latitude", food.getLatitude());
                    item.put("longitude", food.getLongitude());
                    item.put("photo_url", food.getPhotoUrl());
                    item.put("quantity", food.getQuantity());
                    item.put("original_quantity", food.getOriginalQuantity() != null
                            ? food.getOriginalQuantity()
                            : food.getQuantity());
                    item.put("user_id", food.getUser().getId());
                    item.put("status", food.getStatus() == null ? "POSTED" : food.getStatus());
                    item.put("claimed_by", food.getClaimedBy());
                    item.put("claimed_quantity", food.getClaimedQuantity() != null
                            ? food.getClaimedQuantity()
                            : 0);
                    item.put("expired_at", food.getExpiredAt() != null
                            ? food.getExpiredAt().format(formatter)
                            : null);

                    return item;
                })
                .toList();
    }

    public void deleteFood(Long foodId, Long userId) {

        Food food = foodRepository.findById(foodId)
                .orElseThrow(() -> new RuntimeException("FOOD_NOT_FOUND"));

        if (!food.getUser().getId().equals(userId)) {
            throw new RuntimeException("FORBIDDEN");
        }

        food.setStatus("CANCELED");
        foodRepository.save(food);
    }

    public Map<String, Object> getHistory(Long userId) {

        List<Food> myDonation = foodRepository.findByUserIdOrderByIdDesc(userId);

        List<Food> myClaim = foodRepository.findByClaimedByOrderByIdDesc(userId);

        Map<String, Object> result = new HashMap<>();

        result.put(
                "myDonation",
                myDonation.stream().map(food -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", food.getId());
                    item.put("food_name", food.getFoodName());
                    item.put("quantity", food.getQuantity());
                    item.put("original_quantity", food.getOriginalQuantity() != null
                            ? food.getOriginalQuantity()
                            : food.getQuantity());
                    item.put("status", food.getStatus());
                    item.put("photo_url", food.getPhotoUrl());
                    return item;
                }).toList());

        result.put(
                "myClaim",
                myClaim.stream().map(food -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", food.getId());
                    item.put("food_name", food.getFoodName());
                    item.put("quantity", food.getQuantity());
                    item.put("claimed_quantity", food.getClaimedQuantity() != null
                            ? food.getClaimedQuantity()
                            : 0);
                    item.put("status", food.getStatus());
                    item.put("photo_url", food.getPhotoUrl());
                    return item;
                }).toList());

        return result;
    }

    /**
     * User mengklaim sejumlah makanan.
     * - Kurangi stok (quantity) sebesar claimQty.
     * - Jika stok habis, status menjadi ON_THE_WAY.
     * - Jika stok masih ada, status tetap POSTED (bisa diklaim orang lain).
     */
    public void pickFood(Long id, Long userId, Integer claimQty) {

        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("FOOD_NOT_FOUND"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));

        if (user.getTimeoutUntil() != null &&
                user.getTimeoutUntil().isAfter(LocalDateTime.now())) {

            throw new RuntimeException("ACCOUNT_TIMEOUT");
        }

        if (claimQty == null || claimQty < 1) {
            throw new RuntimeException("INVALID_QUANTITY");
        }

        if (claimQty > food.getQuantity()) {
            throw new RuntimeException("QUANTITY_EXCEEDS_STOCK");
        }

        // Kurangi stok
        int newQuantity = food.getQuantity() - claimQty;

        food.setQuantity(newQuantity);

        // Simpan siapa yang claim
        food.setClaimedBy(user.getId());

        // Simpan jumlah yang diambil
        food.setClaimedQuantity(claimQty);

        // Selalu set status menjadi ON_THE_WAY saat diklaim agar pengklaim dapat
        // melanjutkan pengambilan
        if (newQuantity == 0) {
            food.setStatus("ON_THE_WAY");
        } else {
            food.setStatus("POSTED");
        }

        foodRepository.save(food);
    }

    public void confirmPickup(Long id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("FOOD_NOT_FOUND"));

        if (food.getQuantity() == 0) {
            food.setStatus("PICKED_UP");
        } else {
            food.setStatus("POSTED");
        }

        foodRepository.save(food);
    }

    /**
     * User membatalkan klaim → kembalikan stok sejumlah claimedQuantity.
     */
    public void cancelPickup(Long id) {
        Food food = foodRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("FOOD_NOT_FOUND"));

        // Kembalikan stok
        int restored = food.getClaimedQuantity() != null ? food.getClaimedQuantity() : 0;
        food.setQuantity(food.getQuantity() + restored);

        food.setStatus("POSTED");
        food.setClaimedBy(null);
        food.setClaimedQuantity(0);

        foodRepository.save(food);
    }

    public void clearDonationHistory(Long userId) {

        List<Food> foods = foodRepository.findByUserIdOrderByIdDesc(userId);

        foodRepository.deleteAll(foods);
    }

    public void clearClaimHistory(Long userId) {

        List<Food> foods = foodRepository.findByClaimedByAndStatusOrderByIdDesc(
                userId,
                "PICKED_UP");

        for (Food food : foods) {

            food.setClaimedBy(null);
            food.setClaimedQuantity(0);

            if (!food.getStatus().equals("CANCELED")) {
                food.setStatus("POSTED");
            }
        }

        foodRepository.saveAll(foods);
    }

}