package com.fooddonation.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {

        registry.addResourceHandler("/uploads/profile/**")
                .addResourceLocations("file:" + System.getProperty("user.dir") + "/uploads/profile/");

        registry.addResourceHandler("/uploads/foods/**")
                .addResourceLocations("file:" + System.getProperty("user.dir") + "/uploads/foods/");
    }
}