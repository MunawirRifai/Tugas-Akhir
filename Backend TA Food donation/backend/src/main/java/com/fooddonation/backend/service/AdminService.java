package com.fooddonation.backend.service;

import com.fooddonation.backend.dto.UserAdminDTO;
import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.repository.FoodRepository;
import com.fooddonation.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final FoodRepository foodRepository;

    public List<UserAdminDTO> getAllUsersWithStats() {
        List<User> users = userRepository.findAll();

        return users.stream().map(user -> {
            long totalDonations = foodRepository.countByUserId(user.getId());
            long totalClaims = foodRepository.countByClaimedByAndStatus(user.getId(), "PICKED_UP");

            return UserAdminDTO.builder()
                    .id(user.getId())
                    .fullName(user.getFullName())
                    .email(user.getEmail())
                    .phone(user.getPhone())
                    .photoUrl(user.getPhotoUrl())
                    .role(user.getRole())
                    .isBanned(user.getIsBanned())
                    .timeoutUntil(user.getTimeoutUntil())
                    .totalDonations(totalDonations)
                    .totalClaims(totalClaims)
                    .build();
        }).collect(Collectors.toList());
    }

    public void banUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Toggle ban status
        boolean currentStatus = user.getIsBanned() != null ? user.getIsBanned() : false;
        user.setIsBanned(!currentStatus);
        
        userRepository.save(user);
    }

    public void timeoutUser(Long userId, int hours) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (hours <= 0) {
            // Remove timeout
            user.setTimeoutUntil(null);
        } else {
            user.setTimeoutUntil(LocalDateTime.now().plusHours(hours));
        }

        userRepository.save(user);
    }
}
