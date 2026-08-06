-- =============================================================================
-- GetDerivedWageTypes
-- Excludes Binary, "Script", ScriptVersion (performance hint identical to T-SQL)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedWageTypes(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "wageTypeNumbers" TEXT,
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
        wt."Id", wt."Status", wt."Created", wt."Updated", wt."RegulationId",
        wt."Name", wt."NameLocalizations", wt."WageTypeNumber",
        wt."Description", wt."DescriptionLocalizations",
        wt."OverrideType", wt."ValueType", wt."Calendar", wt."Culture",
        wt."Collectors", wt."CollectorGroups",
        wt."ValueExpression", wt."ResultExpression",
        wt."ValueActions", wt."ResultActions",
        wt."ScriptHash", wt."Attributes", wt."Clusters"
    FROM "WageType" wt
    INNER JOIN Regulations reg ON wt."RegulationId" = reg."Id"
    WHERE wt."Status" = 0
      AND wt."Created" <= "createdBefore"
      AND (("includeClusters" IS NULL AND "excludeClusters" IS NULL)
           OR IsMatchingCluster("includeClusters", "excludeClusters", wt."Clusters") = 1)
      AND ("wageTypeNumbers" IS NULL
           OR wt."WageTypeNumber" IN (
               SELECT CAST(jt.val AS DECIMAL(28,6))
               FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val)))
    ORDER BY wt."WageTypeNumber", reg."Level" DESC, reg."Priority" DESC;
$$;
