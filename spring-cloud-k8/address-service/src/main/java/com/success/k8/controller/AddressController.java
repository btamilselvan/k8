package com.success.k8.controller;

import java.time.Instant;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AddressController {

    @GetMapping("/health")
    public String healthCheck(){
        return "Address Service is healthy. Now is " + Instant.now() + " Id : " + this.toString();
    }
}
