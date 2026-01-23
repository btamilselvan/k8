package com.success.k8.controller;

import java.time.Instant;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
public class GatewayController {

  private final DiscoveryClient discoveryClient;

  public GatewayController(@Autowired DiscoveryClient discoveryClient) {
    this.discoveryClient = discoveryClient;
  }

  @GetMapping("/health")
  public String healthCheck() {
    log.info("health check endpoint called");
    return "Gateway Service is up and running! Current Time is "
        + Instant.now()
        + " Id : "
        + this.toString();
  }

  @GetMapping("/ucase")
  public String uppercase() {
    log.info("uppercase endpoint called");
    return "Gateway Service is up and running! Current Time is " + Instant.now();
  }

  @GetMapping("/debug-instances/{serviceId}")
  public List<ServiceInstance> getInstances(@PathVariable String serviceId) {
    // This is exactly what the LoadBalancer calls internally
    return discoveryClient.getInstances(serviceId);
  }
}
