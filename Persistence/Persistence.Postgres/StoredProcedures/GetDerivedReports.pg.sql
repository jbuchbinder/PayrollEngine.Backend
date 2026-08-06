-- =============================================================================
-- GetDerivedReports
-- Excludes Binary, "Script", ScriptVersion (performance hint)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedReports(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "p_userType" INTEGER,
    IN "p_reportNames" TEXT,
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
        rp."Id", rp."Status", rp."Created", rp."Updated", rp."RegulationId",
        rp."Name", rp."NameLocalizations",
        rp."Description", rp."DescriptionLocalizations",
        rp."Category", rp."Queries", rp."Relations",
        rp."AttributeMode", rp."UserType", rp."ReportIsolation",
        rp."BuildExpression", rp."StartExpression", rp."EndExpression",
        rp."ScriptHash", rp."Attributes", rp."Clusters"
    FROM "Report" rp
    INNER JOIN Regulations reg ON rp."RegulationId" = reg."Id"
    WHERE rp."Status" = 0
      AND rp."Created" <= "createdBefore"
      AND (p_userType IS NULL OR rp."UserType" <= p_userType)
      AND (("includeClusters" IS NULL AND "excludeClusters" IS NULL)
           OR IsMatchingCluster("includeClusters", "excludeClusters", rp."Clusters") = 1)
      AND (p_reportNames IS NULL
           OR LOWER(rp."Name") IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text(p_reportNames::jsonb) AS jt(val)))
    ORDER BY reg."Level" DESC, reg."Priority" DESC;
$$;
