package com.fooddonation.backend.exception;

import com.fooddonation.backend.response.ErrorResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {

        Map<String, String> errors = new HashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error ->
                errors.put(error.getField(), error.getDefaultMessage())
        );

        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ErrorResponse.builder()
                        .success(false)
                        .message("Validation failed")
                        .errors(errors)
                        .build());
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ErrorResponse> handleRuntime(RuntimeException ex) {

        Map<String, String> errors = new HashMap<>();

        if (ex.getMessage().equals("EMAIL_ALREADY_EXISTS")) {
            errors.put("email", "Email already registered");

            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ErrorResponse.builder()
                            .success(false)
                            .message("Email already registered")
                            .errors(errors)
                            .build());
        }

        if (ex.getMessage().equals("PHONE_ALREADY_EXISTS")) {
            errors.put("phone", "Phone already registered");

            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ErrorResponse.builder()
                            .success(false)
                            .message("Phone already registered")
                            .errors(errors)
                            .build());
        }

        if (ex.getMessage().equals("INVALID_CREDENTIALS")) {
            errors.put("email", "Email or password is incorrect");

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ErrorResponse.builder()
                            .success(false)
                            .message("Invalid email or password")
                            .errors(errors)
                            .build());
        }

        if (ex.getMessage().equals("ACCOUNT_NOT_VERIFIED")) {
            errors.put("email", "Please verify your account before login");

            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ErrorResponse.builder()
                            .success(false)
                            .message("Account is not verified")
                            .errors(errors)
                            .build());
        }

        errors.put("error", ex.getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ErrorResponse.builder()
                        .success(false)
                        .message("Error")
                        .errors(errors)
                        .build());
    }
}