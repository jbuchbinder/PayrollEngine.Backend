-- =============================================================================
-- GetCollectorCustomResults
-- =============================================================================

DROP FUNCTION IF EXISTS GetCollectorCustomResults;
DROP PROCEDURE IF EXISTS GetCollectorCustomResults;

CREATE OR REPLACE FUNCTION GetCollectorCustomResults(
    IN "tenantId"            INTEGER,
    IN "employeeId"          INTEGER,
    IN "divisionId"          INTEGER,
    IN "payrunJobId"         INTEGER,
    IN "parentPayrunJobId"   INTEGER,
    IN "collectorNameHashes" TEXT,
    IN "periodStart"         TIMESTAMP(6),
    IN "periodEnd"           TIMESTAMP(6),
    IN "forecast"            TEXT,
    IN "jobStatus"           INTEGER,
    IN "evaluationDate"      TIMESTAMP(6)
)
RETURNS TABLE(
    "Id" INT, "Status" INT, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ,
    "CollectorResultId" INT, "TenantId" INT, "EmployeeId" INT, "DivisionId" INT,
    "CollectorName" TEXT, "CollectorNameHash" INT, "CollectorNameLocalizations" TEXT,
    "Source" TEXT, "ValueType" INT, "Value" NUMERIC,
    "Culture" TEXT, "Start" TIMESTAMPTZ, "StartHash" INT, "End" TIMESTAMPTZ,
    "PayrunJobId" INT, "Forecast" TEXT, "ParentJobId" INT,
    "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    SELECT ccr."Id", ccr."Status", ccr."Created", ccr."Updated",
        ccr."CollectorResultId", ccr."TenantId", ccr."EmployeeId", ccr."DivisionId",
        ccr."CollectorName", ccr."CollectorNameHash", ccr."CollectorNameLocalizations",
        ccr."Source", ccr."ValueType", ccr."Value",
        ccr."Culture", ccr."Start", ccr."StartHash", ccr."End",
        ccr."PayrunJobId", ccr."Forecast", ccr."ParentJobId",
        ccr."Tags", ccr."Attributes"
    FROM "CollectorCustomResult" ccr
    WHERE ccr."TenantId" = "tenantId"
      AND ccr."EmployeeId" = "employeeId"
      AND ("divisionId" IS NULL OR ccr."DivisionId" = "divisionId")
      AND ("payrunJobId" IS NULL OR ccr."PayrunJobId" = "payrunJobId")
      AND ("parentPayrunJobId" IS NULL OR ccr."ParentJobId" = "parentPayrunJobId")
      AND ("collectorNameHashes" IS NULL
           OR ccr."CollectorNameHash" IN (
               SELECT CAST(jt.val AS INTEGER)
               FROM jsonb_array_elements_text("collectorNameHashes"::jsonb) AS jt(val)))
      AND ("periodStart" IS NULL OR ccr."Start" BETWEEN "periodStart" AND "periodEnd")
      AND ("jobStatus" IS NULL OR ccr."PayrunJobId" IN (
               SELECT pj."Id" FROM "PayrunJob" pj
               WHERE pj."Id" = ccr."PayrunJobId"
                 AND (pj."JobStatus" & "jobStatus") = pj."JobStatus"))
      AND (ccr."Forecast" IS NULL OR ccr."Forecast" = "forecast")
      AND ("evaluationDate" IS NULL OR ccr."Created" <= "evaluationDate")
    ORDER BY ccr."Created";
$$;
