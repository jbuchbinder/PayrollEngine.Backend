-- =============================================================================
-- GetConsolidatedWageTypeCustomResults
-- =============================================================================

CREATE OR REPLACE FUNCTION GetConsolidatedWageTypeCustomResults(
    IN "tenantId"           INTEGER,
    IN "employeeId"         INTEGER,
    IN "divisionId"         INTEGER,
    IN "wageTypeNumbers"    TEXT,
    IN "periodStartHashes"  TEXT,
    IN "jobStatus"          INTEGER,
    IN "forecast"           TEXT,
    IN "evaluationDate"     TIMESTAMP(6),
    IN "noRetro"            BOOLEAN,
    IN "excludeParentJobId" INTEGER
)
RETURNS TABLE(
    "Id" INT, "Status" INT, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ,
    "WageTypeResultId" INT, "TenantId" INT, "EmployeeId" INT, "DivisionId" INT,
    "WageTypeNumber" NUMERIC, "WageTypeName" TEXT, "WageTypeNameLocalizations" TEXT,
    "Source" TEXT, "ValueType" INT, "Value" NUMERIC, "Culture" TEXT,
    "Start" TIMESTAMPTZ, "StartHash" INT, "End" TIMESTAMPTZ,
    "PayrunJobId" INT, "Forecast" TEXT, "ParentJobId" INT,
    "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    WITH Winners AS (
        SELECT r."Id",
            ROW_NUMBER() OVER (
                PARTITION BY r."WageTypeNumber", r."Start"
                ORDER BY r."Created" DESC, r."Id" DESC
            ) AS "RowNumber"
        FROM "WageTypeCustomResult" r
        WHERE r."TenantId" = "tenantId"
          AND r."EmployeeId" = "employeeId"
          AND ("periodStartHashes" IS NULL
               OR "periodStartHashes" = ''
               OR r."StartHash" IN (
                   SELECT CAST(jt.val AS INTEGER)
                   FROM jsonb_array_elements_text("periodStartHashes"::jsonb) AS jt(val)))
          AND ("divisionId" IS NULL OR r."DivisionId" = "divisionId")
          AND ("wageTypeNumbers" IS NULL
               OR "wageTypeNumbers" = ''
               OR r."WageTypeNumber" IN (
                   SELECT CAST(jt.val AS DECIMAL(28,6))
                   FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val)))
          AND ("evaluationDate" IS NULL OR r."Created" <= "evaluationDate")
          AND ("jobStatus" IS NULL OR r."PayrunJobId" IN (
                   SELECT pj."Id" FROM "PayrunJob" pj
                   WHERE (pj."JobStatus" & "jobStatus") = pj."JobStatus"))
          AND (r."Forecast" IS NULL OR r."Forecast" = "forecast")
          AND ("noRetro" = false OR r."ParentJobId" IS NULL)
          AND ("excludeParentJobId" IS NULL OR r."ParentJobId" IS NULL
               OR r."ParentJobId" <> "excludeParentJobId")
    )
    SELECT r.*
    FROM "WageTypeCustomResult" r
    INNER JOIN Winners w ON w."Id" = r."Id"
    WHERE w."RowNumber" = 1;
$$;
