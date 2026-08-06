-- =============================================================================
-- DeletePayrunJob
-- =============================================================================

CREATE OR REPLACE PROCEDURE DeletePayrunJob(
    IN "tenantId" INTEGER,
    IN "payrunJobId" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "PayrunResult" pr
    USING "PayrollResult" prl
    WHERE pr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId" AND prl."PayrunJobId" = "payrunJobId";

    DELETE FROM "WageTypeCustomResult" wtcr
    USING "WageTypeResult" wtr, "PayrollResult" prl
    WHERE wtcr."WageTypeResultId" = wtr."Id"
      AND wtr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId" AND prl."PayrunJobId" = "payrunJobId";

    DELETE FROM "WageTypeResult" wtr
    USING "PayrollResult" prl
    WHERE wtr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId" AND prl."PayrunJobId" = "payrunJobId";

    DELETE FROM "CollectorCustomResult" ccr
    USING "CollectorResult" cr, "PayrollResult" prl
    WHERE ccr."CollectorResultId" = cr."Id"
      AND cr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId" AND prl."PayrunJobId" = "payrunJobId";

    DELETE FROM "CollectorResult" cr
    USING "PayrollResult" prl
    WHERE cr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId" AND prl."PayrunJobId" = "payrunJobId";

    DELETE FROM "PayrollResult" WHERE "TenantId" = "tenantId" AND "PayrunJobId" = "payrunJobId";

    DELETE FROM "PayrunJobEmployee" WHERE "PayrunJobId" = "payrunJobId";

    DELETE FROM "PayrunJob" WHERE "TenantId" = "tenantId" AND "Id" = "payrunJobId";
END;
$$;
