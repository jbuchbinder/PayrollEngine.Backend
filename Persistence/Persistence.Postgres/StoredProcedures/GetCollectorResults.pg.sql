-- =============================================================================
-- GetCollectorResults
-- =============================================================================

CREATE OR REPLACE FUNCTION GetCollectorResults(
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
    "PayrollResultId" INT, "TenantId" INT, "EmployeeId" INT, "DivisionId" INT,
    "CollectorId" INT, "CollectorName" TEXT, "CollectorNameHash" INT,
    "CollectorNameLocalizations" TEXT, "CollectMode" INT, "Negated" BOOLEAN,
    "ValueType" INT, "Value" NUMERIC, "Culture" TEXT,
    "Start" TIMESTAMPTZ, "StartHash" INT, "End" TIMESTAMPTZ,
    "PayrunJobId" INT, "Forecast" TEXT, "ParentJobId" INT,
    "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    SELECT cr."Id", cr."Status", cr."Created", cr."Updated",
        cr."PayrollResultId", cr."TenantId", cr."EmployeeId", cr."DivisionId",
        cr."CollectorId", cr."CollectorName", cr."CollectorNameHash",
        cr."CollectorNameLocalizations", cr."CollectMode", cr."Negated",
        cr."ValueType", cr."Value", cr."Culture",
        cr."Start", cr."StartHash", cr."End",
        cr."PayrunJobId", cr."Forecast", cr."ParentJobId",
        cr."Tags", cr."Attributes"
    FROM "CollectorResult" cr
    WHERE cr."TenantId" = "tenantId"
      AND cr."EmployeeId" = "employeeId"
      AND ("divisionId" IS NULL OR cr."DivisionId" = "divisionId")
      AND ("payrunJobId" IS NULL OR cr."PayrunJobId" = "payrunJobId")
      AND ("parentPayrunJobId" IS NULL OR cr."ParentJobId" = "parentPayrunJobId")
      AND ("collectorNameHashes" IS NULL
           OR cr."CollectorNameHash" IN (
               SELECT CAST(jt.val AS INTEGER)
               FROM jsonb_array_elements_text("collectorNameHashes"::jsonb) AS jt(val)))
      AND ("periodStart" IS NULL OR cr."Start" BETWEEN "periodStart" AND "periodEnd")
      AND ("jobStatus" IS NULL OR cr."PayrunJobId" IN (
               SELECT pj."Id" FROM "PayrunJob" pj
               WHERE pj."Id" = cr."PayrunJobId"
                 AND (pj."JobStatus" & "jobStatus") = pj."JobStatus"))
      AND (cr."Forecast" IS NULL OR cr."Forecast" = "forecast")
      AND ("evaluationDate" IS NULL OR cr."Created" <= "evaluationDate")
    ORDER BY cr."Created";
$$;
