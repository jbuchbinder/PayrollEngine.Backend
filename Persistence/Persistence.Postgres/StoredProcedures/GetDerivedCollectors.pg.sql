-- =============================================================================
-- GetDerivedCollectors
-- Excludes Binary, "Script", ScriptVersion (performance hint)
-- Parameter order matches C# PayrollRepositoryCollectorCommand call
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedCollectors(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "includeClusters" TEXT,
    IN "excludeClusters" TEXT,
    IN "collectorNames" TEXT
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
        co."Id", co."Status", co."Created", co."Updated", co."RegulationId",
        co."Name", co."NameLocalizations",
        co."CollectMode", co."Negated", co."OverrideType", co."ValueType",
        co."Culture", co."CollectorGroups",
        co."StartExpression", co."ApplyExpression", co."EndExpression",
        co."StartActions", co."ApplyActions", co."EndActions",
        co."Threshold", co."MinResult", co."MaxResult",
        co."ScriptHash", co."Attributes", co."Clusters"
    FROM "Collector" co
    INNER JOIN Regulations reg ON co."RegulationId" = reg."Id"
    WHERE co."Status" = 0
      AND co."Created" <= "createdBefore"
      AND (("includeClusters" IS NULL AND "excludeClusters" IS NULL)
           OR IsMatchingCluster("includeClusters", "excludeClusters", co."Clusters") = 1)
      AND ("collectorNames" IS NULL
           OR LOWER(co."Name") IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text("collectorNames"::jsonb) AS jt(val)))
    ORDER BY co."Name", reg."Level" DESC, reg."Priority" DESC;
$$;
