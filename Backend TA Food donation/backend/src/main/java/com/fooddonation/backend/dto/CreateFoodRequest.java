package com.fooddonation.backend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateFoodRequest {
    private String foodName;
    private String description;
    private Integer quantity;
    private Double latitude;
    private Double longitude;
    private String address;
    private String expiredAt;
}