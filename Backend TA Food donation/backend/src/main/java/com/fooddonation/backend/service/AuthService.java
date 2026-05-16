package com.fooddonation.backend.service;

import com.fooddonation.backend.dto.LoginRequest;
import com.fooddonation.backend.dto.RegisterRequest;
import com.fooddonation.backend.dto.UpdateProfileRequest;
import com.fooddonation.backend.dto.VerifyRegisterRequest;
import com.fooddonation.backend.entity.User;
import com.fooddonation.backend.repository.UserRepository;
import com.fooddonation.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import com.fooddonation.backend.dto.LoginRequest;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

import org.springframework.web.multipart.MultipartFile;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JavaMailSender mailSender;

    public Map<String, Object> register(RegisterRequest request) {

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("EMAIL_ALREADY_EXISTS");
        }

        if (userRepository.existsByPhone(request.getPhone())) {
            throw new RuntimeException("PHONE_ALREADY_EXISTS");
        }

        String verificationCode = String.format("%04d", new Random().nextInt(10000));

        User user = User.builder()
                .fullName(request.getFullName())
                .phone(request.getPhone())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .isVerified(false)
                .verificationCode(verificationCode)
                .verificationExpiredAt(LocalDateTime.now().plusMinutes(5))
                .build();

        userRepository.save(user);

        SimpleMailMessage message = new SimpleMailMessage();

        message.setTo(user.getEmail());
        message.setSubject("Food Donation Verification");
        message.setText(
                "Kode verifikasi akun kamu adalah: "
                        + verificationCode +
                        "\n\nKode ini akan expired dalam 5 menit.");

        mailSender.send(message);

        Map<String, Object> response = new HashMap<>();

        response.put("user_id", user.getId());
        response.put("verification_token", user.getEmail());

        return response;

    }

    public Map<String, Object> verifyRegister(VerifyRegisterRequest request) {

        User user = userRepository.findByEmail(request.getVerificationToken())
                .orElseThrow(() -> new RuntimeException("INVALID_VERIFICATION_TOKEN"));

        if (Boolean.TRUE.equals(user.getIsVerified())) {
            throw new RuntimeException("ALREADY_VERIFIED");
        }

        if (user.getVerificationExpiredAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("VERIFICATION_CODE_EXPIRED");
        }

        if (!user.getVerificationCode().equals(request.getCode())) {
            throw new RuntimeException("INVALID_VERIFICATION_CODE");
        }

        user.setIsVerified(true);
        user.setVerificationCode(null);
        user.setVerificationExpiredAt(null);

        userRepository.save(user);

        Map<String, Object> response = new HashMap<>();

        response.put("success", true);
        response.put("email", user.getEmail());

        return response;
    }

    public Map<String, Object> login(LoginRequest request) {

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("INVALID_CREDENTIALS"));

        if (!Boolean.TRUE.equals(user.getIsVerified())) {
            throw new RuntimeException("ACCOUNT_NOT_VERIFIED");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("INVALID_CREDENTIALS");
        }

        String accessToken = jwtService.generateAccessToken(user.getId());
        String refreshToken = jwtService.generateRefreshToken(user.getId());

        Map<String, Object> response = new HashMap<>();

        Map<String, Object> userData = new HashMap<>();
        userData.put("id", user.getId());
        userData.put("full_name", user.getFullName());
        userData.put("email", user.getEmail());
        userData.put("phone", user.getPhone());
        userData.put("photo_url", user.getPhotoUrl());
        userData.put("role", user.getRole() != null ? user.getRole() : "ROLE_USER");

        response.put("user", userData);
        response.put("access_token", accessToken);
        response.put("refresh_token", refreshToken);

        return response;
    }

    public Map<String, Object> getMyProfile(String authValue) {

        User user;

        if (authValue.matches("\\d+")) {
            Long userId = Long.parseLong(authValue);

            user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        } else {
            user = userRepository.findByEmail(authValue)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        }

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("full_name", user.getFullName());
        data.put("email", user.getEmail());
        data.put("phone", user.getPhone());
        data.put("photo_url", user.getPhotoUrl());
        data.put("role", user.getRole() != null ? user.getRole() : "ROLE_USER");

        return data;
    }

    public Map<String, Object> updateProfile(String authValue, UpdateProfileRequest request) {

        User user;

        if (authValue.matches("\\d+")) {
            Long userId = Long.parseLong(authValue);

            user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        } else {
            user = userRepository.findByEmail(authValue)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        }

        if ((request.getFullName() == null || request.getFullName().isBlank()) &&
                (request.getPhone() == null || request.getPhone().isBlank()) &&
                (request.getEmail() == null || request.getEmail().isBlank())) {
            throw new RuntimeException("EMPTY_REQUEST");
        }

        if (request.getFullName() != null &&
                !request.getFullName().isBlank() &&
                request.getFullName().length() < 3) {
            throw new RuntimeException("INVALID_FULL_NAME");
        }

        if (request.getPhone() != null &&
                !request.getPhone().isBlank() &&
                !request.getPhone().matches("^[0-9]{10,15}$")) {
            throw new RuntimeException("INVALID_PHONE");
        }

        if (request.getPhone() != null &&
                !request.getPhone().isBlank() &&
                userRepository.existsByPhoneAndIdNot(request.getPhone(), user.getId())) {
            throw new RuntimeException("PHONE_ALREADY_EXISTS");
        }

        if (request.getEmail() != null && !request.getEmail().isBlank()) {

            if (!request.getEmail().matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                throw new RuntimeException("INVALID_EMAIL");
            }

            if (userRepository.existsByEmailAndIdNot(request.getEmail(), user.getId())) {
                throw new RuntimeException("EMAIL_ALREADY_EXISTS");
            }
        }

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            user.setFullName(request.getFullName());
        }

        if (request.getPhone() != null && !request.getPhone().isBlank()) {
            user.setPhone(request.getPhone());
        }

        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            user.setEmail(request.getEmail());
        }

        userRepository.save(user);

        String accessToken = jwtService.generateAccessToken(user.getId());
        String refreshToken = jwtService.generateRefreshToken(user.getId());

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("full_name", user.getFullName());
        data.put("email", user.getEmail());
        data.put("phone", user.getPhone());
        data.put("photo_url", user.getPhotoUrl());
        data.put("role", user.getRole() != null ? user.getRole() : "ROLE_USER");
        data.put("access_token", accessToken);
        data.put("refresh_token", refreshToken);

        return data;
    }

    public Map<String, Object> uploadProfilePhoto(String authValue, MultipartFile photo) throws Exception {

        User user;

        if (authValue.matches("\\d+")) {
            Long userId = Long.parseLong(authValue);

            user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        } else {
            user = userRepository.findByEmail(authValue)
                    .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));
        }

        String uploadDir = System.getProperty("user.dir") + "/uploads/profile/";
        File folder = new File(uploadDir);

        if (!folder.exists()) {
            folder.mkdirs();
        }

        String fileName = UUID.randomUUID() + "_" + photo.getOriginalFilename();

        File destination = new File(uploadDir + fileName);
        photo.transferTo(destination);

        String photoUrl = "http://localhost:8080/uploads/profile/" + fileName;

        user.setPhotoUrl(photoUrl);
        userRepository.save(user);

        Map<String, Object> data = new HashMap<>();
        data.put("photo_url", photoUrl);

        return data;
    }
}