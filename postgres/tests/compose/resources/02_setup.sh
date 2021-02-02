#!/bin/bash
set -e

# setup extensions & functions required for collection of statement metrics & samples
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" datadog_test <<-'EOSQL'
    CREATE EXTENSION pg_stat_statements SCHEMA public;
    GRANT SELECT ON pg_stat_statements TO datadog;

    CREATE SCHEMA datadog;
    GRANT USAGE ON SCHEMA datadog TO datadog;

    CREATE OR REPLACE FUNCTION datadog.explain_statement(l_query text, out explain JSON) RETURNS SETOF JSON AS
    $$
      BEGIN
          RETURN QUERY EXECUTE 'EXPLAIN (FORMAT JSON) ' || l_query;
      END;
    $$
    LANGUAGE 'plpgsql'
    VOLATILE
    RETURNS NULL ON NULL INPUT
    SECURITY DEFINER
    COST 100 ROWS 1000;

    ALTER FUNCTION datadog.explain_statement(l_query text, out explain json) OWNER TO postgres;

    CREATE OR REPLACE FUNCTION datadog.pg_stat_activity() RETURNS SETOF pg_stat_activity AS
    $$
      SELECT * FROM pg_catalog.pg_stat_activity;
    $$
    LANGUAGE sql
    VOLATILE
    SECURITY DEFINER;

    ALTER FUNCTION datadog.pg_stat_activity() owner to postgres;

EOSQL