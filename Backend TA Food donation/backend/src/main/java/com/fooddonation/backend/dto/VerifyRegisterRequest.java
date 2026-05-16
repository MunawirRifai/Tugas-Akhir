package com.fooddonation.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class VerifyRegisterRequest {

    @NotBlank(message = "Verification token is required")
    private String verificationToken;

    @NotBlank(message = "Code is required")
    @Pattern(regexp = "^[0-9]{4}$", message = "Code must be 4 digits")
    private String code;
}