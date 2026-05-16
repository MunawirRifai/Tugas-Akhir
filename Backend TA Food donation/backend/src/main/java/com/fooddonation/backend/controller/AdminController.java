package com.fooddonation.backend.controller;

import com.fooddonation.backend.dto.TimeoutRequest;
import com.fooddonation.backend.dto.UserAdminDTO;
import com.fooddonation.backend.response.ApiResponse;
import com.fooddonation.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserAdminDTO>>> getAllUsers() {
        List<UserAdminDTO> users = adminService.getAllUsersWithStats();
        
        return ResponseEntity.ok(
                ApiResponse.<List<UserAdminDTO>>builder()
                        .success(true)
                        .message("Users loaded successfully")
                        .data(users)
                        .build()
        );
    }

    @PostMapping("/users/{id}/ban")
    public ResponseEntity<ApiResponse<String>> banUser(@PathVariable Long id) {
        adminService.banUser(id);
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("User ban status updated")
                        .data(null)
                        .build()
        );
    }

    @PostMapping("/users/{id}/timeout")
    public ResponseEntity<ApiResponse<String>> timeoutUser(
            @PathVariable Long id,
            @RequestBody TimeoutRequest request) {
        
        adminService.timeoutUser(id, request.getHours());
        
        return ResponseEntity.ok(
                ApiResponse.<String>builder()
                        .success(true)
                        .message("User timeout status updated")
                        .data(null)
                        .build()
        );
    }
}
