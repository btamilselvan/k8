package com.success.k8.controller;

import java.time.Instant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.slf4j.Slf4j;

@RestController
@Slf4j
public class AddressController {

    @Value("${hello.message: default message}")
    private String helloMessage;

    @Value("${trocks.apiKey}")
    private String apiKey;

    @GetMapping("/health")
    public String healthCheck(){
        return "Address Service is healthy. Now is " + Instant.now() + " Id : " + this.toString();
    }

    @GetMapping("/config")
    public String getConfig(){
        log.info("apiKey {}", apiKey);
        return "config "+helloMessage + " secret "+ apiKey;
    }
}
