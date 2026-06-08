package com.care.boot;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 웹에서 /uploads/** 로 요청이 들어오면 
        // 실제 컴퓨터의 D:/Program Files/cording/workspace/IssuePlanet/uploads/ 경로를 찾음
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:///D:/uploads/");
    }
}