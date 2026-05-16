package com.fooddonation.backend.controller;

import com.fooddonation.backend.dto.LoginRequest;
import com.fooddonation.backend.dto.RegisterRequest;
import com.fooddonation.backend.dto.VerifyRegisterRequest;
import com.fooddonation.backend.response.ApiResponse;
import com.fooddonation.backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import org.springframework.http.MediaType;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import com.fooddonation.backend.dto.LoginRequest;
import com.fooddonation.backend.dto.UpdateProfileRequest;
import org.springframework.security.core.Authentication;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@CrossOrigin(origins = {
                "http://localhost:51335",
                "http://localhost:3000",
                "http://localhost:8080"
})
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

        private final AuthService authService;

        @PostMapping("/register")
        public ResponseEntity<ApiResponse<Map<String, Object>>> register(
                        @Valid @RequestBody RegisterRequest request) {

                Map<String, Object> data = authService.register(request);

                return ResponseEntity.status(HttpStatus.CREATED)
                                .body(ApiResponse.<Map<String, Object>>builder()
                                                .success(true)
                                                .message("Verification code sent")
                                                .data(data)
                                                .build());
        }

        @PostMapping("/verify-register")
        public ResponseEntity<ApiResponse<Map<String, Object>>> verifyRegister(
                        @Valid @RequestBody VerifyRegisterRequest request) {

                Map<String, Object> data = authService.verifyRegister(request);

                return ResponseEntity.ok(
                                ApiResponse.<Map<String, Object>>builder()
                                                .success(true)
                                                .message("Account verified")
                                                .data(data)
                                                .build());
        }

        @PostMapping("/login")
        public ResponseEntity<ApiResponse<Map<String, Object>>> login(
                        @Valid @RequestBody LoginRequest request) {

                Map<String, Object> data = authService.login(request);

                return ResponseEntity.ok(
                                ApiResponse.<Map<String, Object>>builder()
                                                .success(true)
                                                .message("Login successful")
                                                .data(data)
                                                .build());
        }

        @GetMapping("/me")
        public ResponseEntity<?> me(Authentication authentication) {

                Map<String, Object> data = authService.getMyProfile(authentication.getName());

                return ResponseEntity.ok(
                                ApiResponse.builder()
                                                .success(true)
                                                .message("Profile loaded")
                                                .data(data)
                                                .build());
        }

        @PutMapping("/me")
        public ResponseEntity<?> updateProfile(
                        Authentication authentication,
                        @RequestBody UpdateProfileRequest request) {

                Map<String, Object> data = authService.updateProfile(
                                authentication.getName(),
                                request);

                return ResponseEntity.ok(
                                ApiResponse.builder()
                                                .success(true)
                                                .message("Profile updated successfully")
                                                .data(data)
                                                .build());
        }

        @PostMapping("/me/photo")
        public ResponseEntity<?> uploadPhoto(
                        Authentication authentication,
                        @RequestParam("photo") MultipartFile photo) throws Exception {

                Map<String, Object> data = authService.uploadProfilePhoto(authentication.getName(), photo);

                return ResponseEntity.ok(
                                ApiResponse.builder()
                                                .success(true)
                                                .message("Photo updated")
                                                .data(data)
                                                .build());
        }
}