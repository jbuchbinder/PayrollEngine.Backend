-- =============================================================================
-- GetDerivedCaseRelations
-- cr."Order" double-quoted (reserved keyword in PG)
-- Excludes Binary, "Script", ScriptVersion (performance hint)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedCaseRelations(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "p_sourceCaseName" TEXT,
    IN "p_targetCaseName" TEXT,
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
        cr."Id", cr."Status", cr."Created", cr."Updated", cr."RegulationId",
        cr."SourceCaseName", cr."SourceCaseNameLocalizations",
        cr."SourceCaseSlot", cr."SourceCaseSlotLocalizations",
        cr."TargetCaseName", cr."TargetCaseNameLocalizations",
        cr."TargetCaseSlot", cr."TargetCaseSlotLocalizations",
        cr."RelationHash", cr."BuildExpression", cr."ValidateExpression",
        cr."OverrideType", cr."Order",
        cr."ScriptHash", cr."Attributes", cr."Clusters",
        cr."BuildActions", cr."ValidateActions"
    FROM "CaseRelation" cr
    INNER JOIN Regulations reg ON cr."RegulationId" = reg."Id"
    WHERE cr."Status" = 0
      AND cr."Created" <= "createdBefore"
      AND (p_sourceCaseName IS NULL
           OR LOWER(cr."SourceCaseName") = LOWER(p_sourceCaseName))
      AND (p_targetCaseName IS NULL
           OR LOWER(cr."TargetCaseName") = LOWER(p_targetCaseName))
      AND (("includeClusters" IS NULL AND "excludeClusters" IS NULL)
           OR IsMatchingCluster("includeClusters", "excludeClusters", cr."Clusters") = 1)
    ORDER BY cr."SourceCaseName", cr."TargetCaseName", reg."Level" DESC, reg."Priority" DESC;
$$;
