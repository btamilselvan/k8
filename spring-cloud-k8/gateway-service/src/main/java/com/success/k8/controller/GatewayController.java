package com.success.k8.controller;

import java.time.Instant;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
public class GatewayController {

  @GetMapping("/health")
  public String healthCheck() {
    log.info("health check endpoint called");
    return "Gateway Service is up and running! Current Time is " + Instant.now();
  }

  @GetMapping("/ucase")
  public String uppercase() {
    log.info("uppercase endpoint called");
    return "Gateway Service is up and running! Current Time is " + Instant.now();
  }
}
