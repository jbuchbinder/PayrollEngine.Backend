-- =============================================================================
-- GetDerivedReportTemplates
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedReportTemplates(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "p_reportNames" TEXT,
    IN "p_culture" TEXT
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
        rt.*
    FROM "ReportTemplate" rt
    INNER JOIN "Report" rp ON rt."ReportId" = rp."Id"
    INNER JOIN Regulations reg ON rp."RegulationId" = reg."Id"
    WHERE rt."Status" = 0
      AND rt."Created" <= "createdBefore"
      AND (p_reportNames IS NULL
           OR LOWER(rp."Name") IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text(p_reportNames::jsonb) AS jt(val)))
      AND (p_culture IS NULL OR rt."Culture" = p_culture)
    ORDER BY reg."Level" DESC, reg."Priority" DESC;
$$;
