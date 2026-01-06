package com.success.k8;

import java.util.function.Function;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class GatewayServiceApplication {
  public static void main(String[] args) {
    SpringApplication.run(GatewayServiceApplication.class, args);
  }

  @Bean
  public Function<String, String> uppercase() {
    return String::toUpperCase;
  }

  @Bean
  public Function<String, String> concat() {
    return value -> value + " " + value + " - processed by Gateway Service";
  }
}