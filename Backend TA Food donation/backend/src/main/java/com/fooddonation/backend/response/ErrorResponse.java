package com.fooddonation.backend.response;

import lombok.*;

import java.util.Map;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ErrorResponse {

    private boolean success;
    private String message;
    private Map<String, String> errors;
}