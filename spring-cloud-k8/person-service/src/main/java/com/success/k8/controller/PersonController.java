package com.success.k8.controller;

import com.success.k8.client.AddressServiceClient;
import java.time.Instant;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

@Slf4j
@RestController
public class PersonController {

  private final DiscoveryClient discoveryClient;
  private final AddressServiceClient addressServiceClient;
  private final RestClient restClient = RestClient.create();

  // works within the same namespace
  private static final String K8_INTERNAL_SHORT_URL = "http://address-service:8080";

  // fully qualified domain name within the cluster (across namespaces)
  private static final String K8_INTERNAL_FULL_URL =
      "http://address-service.default.svc.cluster.local:8080";

  public PersonController(
      DiscoveryClient discoveryClient, AddressServiceClient addressServiceClient) {
    this.discoveryClient = discoveryClient;
    this.addressServiceClient = addressServiceClient;
  }

  @GetMapping("/health")
  public String healthCheck() {
    return "Person Service is up and running! " + Instant.now() + " Id : " + this.toString();
  }

  @GetMapping("/services")
  public List<String> getServices() {
    this.discoveryClient
        .getServices()
        .forEach(
            service -> {
              log.info("Discovered service: {}", service);
            });

    // list all instances
    this.discoveryClient
        .getServices()
        .forEach(
            serviceId -> {
              this.discoveryClient
                  .getInstances(serviceId)
                  .forEach(
                      instance -> {
                        log.info(
                            "Instance for service {}: {}:{} (metadata: {})",
                            serviceId,
                            instance.getHost(),
                            instance.getPort(),
                            instance.getMetadata());
                      });
            });

    return this.discoveryClient.getServices();
  }

  // call address-service health endpoint
  @GetMapping("/address-service")
  public String getAddressServiceInstances() {
    List<String> services = this.discoveryClient.getServices();
    log.info("Services available: {}", services);

    List<org.springframework.cloud.client.ServiceInstance> instances =
        this.discoveryClient.getInstances("address-service");
    if (instances.isEmpty()) {
      log.warn("No instances found for address-service");
      return "No instances found for address-service";
    }

    org.springframework.cloud.client.ServiceInstance instance = instances.get(0);
    String url = "http://" + instance.getHost() + ":" + instance.getPort() + "/health";
    log.info("Calling address-service at URL: {}", url);

    String response = this.restClient.get().uri(url).retrieve().body(String.class);

    log.info("Response from address-service: {}", response);
    return "invoked using RestClient using the address (first instance URL) found using DiscoveryClient: "+response;
  }

  // call using internal k8 dns - short url
  @Profile("kubernetes")
  @GetMapping("/address-service/k8/internal/short")
  public String getAddressServiceK8InternalShort() {
    String url = K8_INTERNAL_SHORT_URL + "/health";
    log.info("Calling address-service at URL: {}", url);

    String response = this.restClient.get().uri(url).retrieve().body(String.class);

    log.info("Response from address-service: {}", response);
    return "invoked using RestClient using K8 short url: "+response;
  }

  // call using internal k8 dns - full url
  @Profile("kubernetes")
  @GetMapping("/address-service/k8/internal/full")
  public String getAddressServiceK8InternalFull() {
    String url = K8_INTERNAL_FULL_URL + "/health";
    log.info("Calling address-service at URL: {}", url);
    String response = this.restClient.get().uri(url).retrieve().body(String.class);
    log.info("Response from address-service: {}", response);
    return "invoked using RestClient using K8 Full url: "+response;
  }

  @GetMapping("/address-service/feign")
  public String addressHealthByFeign() {
    return "routed using feign: "+addressServiceClient.health();
  }
}
