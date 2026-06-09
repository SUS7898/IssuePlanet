package com.care.boot;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 클라이언트 접근 URL 패턴과 실제 리눅스 물리적 경로 매칭
        registry.addResourceHandler("/upload/**")
                .addResourceLocations("file:///opt/tomcat/tomcat-10/webapps/uploads/");
    }
}