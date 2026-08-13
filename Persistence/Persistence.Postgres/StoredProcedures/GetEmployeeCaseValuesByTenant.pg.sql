-- =============================================================================
-- GetEmployeeCaseValuesByTenant
-- Direct JOIN query -- no pivot, no temp table needed.
-- =============================================================================

CREATE OR REPLACE FUNCTION GetEmployeeCaseValuesByTenant(
    IN "tenantId"       INTEGER,
    IN "valueDate"      TIMESTAMP(6),
    IN "evaluationDate" TIMESTAMP(6),
    IN "fieldNames"     TEXT,
    IN "forecast"       TEXT
)
RETURNS TABLE(
    "Id" INT, "Status" INT, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ,
    "EmployeeId" INT, "DivisionId" INT,
    "CaseName" TEXT, "CaseNameLocalizations" TEXT,
    "CaseFieldName" TEXT, "CaseFieldNameLocalizations" TEXT,
    "CaseSlot" TEXT, "CaseSlotLocalizations" TEXT,
    "ValueType" INT, "Value" TEXT, "NumericValue" NUMERIC, "Culture" TEXT,
    "CaseRelation" TEXT, "CancellationDate" TIMESTAMPTZ, "Start" TIMESTAMPTZ, "End" TIMESTAMPTZ,
    "Forecast" TEXT, "Tags" TEXT, "Attributes" TEXT
)
LANGUAGE sql STABLE AS $$
    SELECT
        ecv."Id", ecv."Status", ecv."Created", ecv."Updated",
        ecv."EmployeeId", ecv."DivisionId",
        ecv."CaseName", ecv."CaseNameLocalizations",
        ecv."CaseFieldName", ecv."CaseFieldNameLocalizations",
        ecv."CaseSlot", ecv."CaseSlotLocalizations",
        ecv."ValueType", ecv."Value", ecv."NumericValue", ecv."Culture",
        ecv."CaseRelation", ecv."CancellationDate", ecv."Start", ecv."End",
        ecv."Forecast", ecv."Tags", ecv."Attributes"
    FROM "EmployeeCaseValue" ecv
    INNER JOIN "Employee" e ON e."Id" = ecv."EmployeeId"
    WHERE e."TenantId" = "tenantId"
      AND e."Status" = 0
      AND ecv."CancellationDate" IS NULL
      AND ("evaluationDate" IS NULL OR ecv."Created" <= "evaluationDate")
      AND ("valueDate" IS NULL OR ecv."Start" IS NULL OR ecv."Start" <= "valueDate")
      AND ("valueDate" IS NULL OR ecv."End"   IS NULL OR ecv."End"   >  "valueDate")
      AND (
          ("forecast" IS NULL     AND ecv."Forecast" IS NULL)
          OR ("forecast" IS NOT NULL AND (ecv."Forecast" IS NULL OR ecv."Forecast" = "forecast"))
      )
      AND (
          "fieldNames" IS NULL
          OR ecv."CaseFieldName" IN (
              SELECT jt.val
              FROM jsonb_array_elements_text("fieldNames"::jsonb) AS jt(val)
          )
      )
    ORDER BY ecv."EmployeeId" ASC, ecv."CaseFieldName" ASC, ecv."Created" DESC;
$$;
