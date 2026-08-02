package com.lakescout;

import org.springframework.boot.SpringApplication;

public class TestLakescoutBackendApplication {

	public static void main(String[] args) {
		SpringApplication.from(LakescoutBackendApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
