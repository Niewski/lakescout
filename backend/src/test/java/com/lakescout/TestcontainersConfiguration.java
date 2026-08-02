package com.lakescout;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Tests run against PostGIS rather than stock Postgres: every spatial migration,
 * the {@code <->} KNN lookups and the geography columns need the extension present,
 * so a plain postgres image would pass locally and fail on the first real query.
 */
@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {

	static final DockerImageName POSTGIS_IMAGE =
			DockerImageName.parse("postgis/postgis:16-3.4")
					.asCompatibleSubstituteFor("postgres");

	@Bean
	@ServiceConnection
	PostgreSQLContainer postgresContainer() {
		return new PostgreSQLContainer(POSTGIS_IMAGE);
	}

}
