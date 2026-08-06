-- =============================================================================
-- GetDerivedCaseFieldsOfCase
-- Filtered by case names (not field names).
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedCaseFieldsOfCase(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "caseNames" TEXT,
    IN "includeClusters" TEXT,
    IN "excludeClusters" TEXT
)
LANGUAGE sql
AS $$
        WITH DerivedRegulations AS (
        SELECT r."Id", pl."Level", pl."Priority",
            ROW_NUMBER() OVER (
                PARTITION BY pl."Id", r."Name"
                ORDER BY r."ValidFrom" DESC, r."Created" DESC
            ) AS "RowNumber"
        FROM "PayrollLayer" pl
        INNER JOIN "Regulation" r ON pl."RegulationName" = r."Name"
        WHERE r."Status" = 0
          AND (r."TenantId" = "tenantId" OR r."SharedRegulation" = true)
          AND r."Created" <= "createdBefore"
          AND (r."ValidFrom" IS NULL OR r."ValidFrom" <= "regulationDate")
          AND pl."Status" = 0 AND pl."PayrollId" = "payrollId"
    ),
    Regulations AS (SELECT "Id", "Level", "Priority" FROM DerivedRegulations WHERE "RowNumber" = 1)
    SELECT
        reg."Id" AS RegulationId, reg."Level", reg."Priority",
        c."Id" AS CaseId, c."CaseType",
        cf.*
    FROM "CaseField" cf
    INNER JOIN "Case" c ON cf."CaseId" = c."Id"
    INNER JOIN Regulations reg ON c."RegulationId" = reg."Id"
    WHERE cf."Status" = 0
      AND cf."Created" <= "createdBefore"
      AND (("includeClusters" IS NULL AND "excludeClusters" IS NULL)
           OR IsMatchingCluster("includeClusters", "excludeClusters", cf."Clusters") = 1)
      AND ("caseNames" IS NULL
           OR LOWER(c."Name") IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text("caseNames"::jsonb) AS jt(val)))
    ORDER BY reg."Level" DESC, reg."Priority" DESC;
$$;
