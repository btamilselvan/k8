package com.success.k8.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Feign client to communicate with Address Service.
 *
 * <p>if url is not provided, it uses service discovery to find the service instances. And,
 * spring-cloud-starter-loadbalancer is required for load balancing.
 */
@FeignClient(name = "address-service")
public interface AddressServiceClient {
  @GetMapping("/health")
  public String health();
}
