package com.lakescout;

import static org.assertj.core.api.Assertions.assertThat;

import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Guards the two things week 1 has to get right before anything else can be built:
 * Flyway actually ran, and PostGIS is actually usable.
 *
 * <p>A plain "context loads" test passes against a database with no extension, and the
 * failure only shows up much later at the first spatial query. This fails immediately.
 */
@Import(TestcontainersConfiguration.class)
@SpringBootTest
class SchemaBootstrapTest {

	@Autowired
	private DataSource dataSource;

	@Test
	void flywayAppliedTheBaselineMigration() {
		JdbcTemplate jdbc = new JdbcTemplate(dataSource);

		Integer applied = jdbc.queryForObject(
				"SELECT count(*) FROM flyway_schema_history WHERE success = true", Integer.class);

		assertThat(applied).isPositive();
	}

	@Test
	void postgisIsInstalledAndGeographyMathWorks() {
		JdbcTemplate jdbc = new JdbcTemplate(dataSource);

		assertThat(jdbc.queryForObject(
				"SELECT count(*) FROM pg_extension WHERE extname = 'postgis'", Integer.class))
				.isEqualTo(1);

		// Holland, MI -> Torch Lake, MI. Roughly 250 km great-circle; assert a wide band
		// so the test checks that geography distance works, not that PostGIS is precise.
		Double metres = jdbc.queryForObject("""
				SELECT ST_Distance(
				         ST_MakePoint(-86.1089, 42.7875)::geography,
				         ST_MakePoint(-85.3000, 44.9800)::geography)
				""", Double.class);

		assertThat(metres).isBetween(200_000.0, 300_000.0);
	}
}
