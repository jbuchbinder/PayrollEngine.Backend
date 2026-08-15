-- =============================================================================
-- GetWageTypeResults
-- =============================================================================

DROP FUNCTION IF EXISTS GetWageTypeResults;
DROP PROCEDURE IF EXISTS GetWageTypeResults;

CREATE OR REPLACE FUNCTION GetWageTypeResults(
    IN "tenantId"          INTEGER,
    IN "employeeId"        INTEGER,
    IN "divisionId"        INTEGER,
    IN "payrunJobId"       INTEGER,
    IN "parentPayrunJobId" INTEGER,
    IN "wageTypeNumbers"   TEXT,
    IN "periodStart"       TIMESTAMP(6),
    IN "periodEnd"         TIMESTAMP(6),
    IN "forecast"          TEXT,
    IN "jobStatus"         INTEGER,
    IN "evaluationDate"    TIMESTAMP(6)
)
RETURNS TABLE(
    "Id" INT, "Status" INT, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ,
    "PayrollResultId" INT, "TenantId" INT, "EmployeeId" INT, "DivisionId" INT,
    "WageTypeId" INT, "WageTypeNumber" NUMERIC, "WageTypeName" TEXT,
    "WageTypeNameLocalizations" TEXT, "ValueType" INT, "Value" NUMERIC,
    "Culture" TEXT, "Start" TIMESTAMPTZ, "StartHash" INT, "End" TIMESTAMPTZ,
    "PayrunJobId" INT, "Forecast" TEXT, "ParentJobId" INT,
    "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    SELECT wtr."Id", wtr."Status", wtr."Created", wtr."Updated",
        wtr."PayrollResultId", wtr."TenantId", wtr."EmployeeId", wtr."DivisionId",
        wtr."WageTypeId", wtr."WageTypeNumber", wtr."WageTypeName",
        wtr."WageTypeNameLocalizations", wtr."ValueType", wtr."Value",
        wtr."Culture", wtr."Start", wtr."StartHash", wtr."End",
        wtr."PayrunJobId", wtr."Forecast", wtr."ParentJobId",
        wtr."Tags", wtr."Attributes"
    FROM "WageTypeResult" wtr
    WHERE wtr."TenantId" = "tenantId"
      AND wtr."EmployeeId" = "employeeId"
      AND ("divisionId" IS NULL OR wtr."DivisionId" = "divisionId")
      AND ("payrunJobId" IS NULL OR wtr."PayrunJobId" = "payrunJobId")
      AND ("parentPayrunJobId" IS NULL OR wtr."ParentJobId" = "parentPayrunJobId")
      AND ("wageTypeNumbers" IS NULL
           OR wtr."WageTypeNumber" IN (
               SELECT CAST(jt.val AS DECIMAL(28,6))
               FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val)))
      AND ("periodStart" IS NULL OR wtr."Start" BETWEEN "periodStart" AND "periodEnd")
      AND ("jobStatus" IS NULL OR wtr."PayrunJobId" IN (
               SELECT pj."Id" FROM "PayrunJob" pj
               WHERE pj."Id" = wtr."PayrunJobId"
                 AND (pj."JobStatus" & "jobStatus") = pj."JobStatus"))
      AND (wtr."Forecast" IS NULL OR wtr."Forecast" = "forecast")
      AND ("evaluationDate" IS NULL OR wtr."Created" <= "evaluationDate")
    ORDER BY wtr."Created";
$$;
