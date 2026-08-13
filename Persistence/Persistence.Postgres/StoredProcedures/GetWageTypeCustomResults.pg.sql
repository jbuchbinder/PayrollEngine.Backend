-- =============================================================================
-- GetWageTypeCustomResults
-- =============================================================================

CREATE OR REPLACE FUNCTION GetWageTypeCustomResults(
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
    "WageTypeResultId" INT, "TenantId" INT, "EmployeeId" INT, "DivisionId" INT,
    "WageTypeNumber" NUMERIC, "WageTypeName" TEXT, "WageTypeNameLocalizations" TEXT,
    "Source" TEXT, "ValueType" INT, "Value" NUMERIC,
    "Culture" TEXT, "Start" TIMESTAMPTZ, "StartHash" INT, "End" TIMESTAMPTZ,
    "PayrunJobId" INT, "Forecast" TEXT, "ParentJobId" INT,
    "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    SELECT wtcr."Id", wtcr."Status", wtcr."Created", wtcr."Updated",
        wtcr."WageTypeResultId", wtcr."TenantId", wtcr."EmployeeId", wtcr."DivisionId",
        wtcr."WageTypeNumber", wtcr."WageTypeName", wtcr."WageTypeNameLocalizations",
        wtcr."Source", wtcr."ValueType", wtcr."Value",
        wtcr."Culture", wtcr."Start", wtcr."StartHash", wtcr."End",
        wtcr."PayrunJobId", wtcr."Forecast", wtcr."ParentJobId",
        wtcr."Tags", wtcr."Attributes"
    FROM "WageTypeCustomResult" wtcr
    WHERE wtcr."TenantId" = "tenantId"
      AND wtcr."EmployeeId" = "employeeId"
      AND ("divisionId" IS NULL OR wtcr."DivisionId" = "divisionId")
      AND ("payrunJobId" IS NULL OR wtcr."PayrunJobId" = "payrunJobId")
      AND ("parentPayrunJobId" IS NULL OR wtcr."ParentJobId" = "parentPayrunJobId")
      AND ("wageTypeNumbers" IS NULL
           OR wtcr."WageTypeNumber" IN (
               SELECT CAST(jt.val AS DECIMAL(28,6))
               FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val)))
      AND ("periodStart" IS NULL OR wtcr."Start" BETWEEN "periodStart" AND "periodEnd")
      AND ("jobStatus" IS NULL OR wtcr."PayrunJobId" IN (
               SELECT pj."Id" FROM "PayrunJob" pj
               WHERE pj."Id" = wtcr."PayrunJobId"
                 AND (pj."JobStatus" & "jobStatus") = pj."JobStatus"))
      AND (wtcr."Forecast" IS NULL OR wtcr."Forecast" = "forecast")
      AND ("evaluationDate" IS NULL OR wtcr."Created" <= "evaluationDate")
    ORDER BY wtcr."Created";
$$;
