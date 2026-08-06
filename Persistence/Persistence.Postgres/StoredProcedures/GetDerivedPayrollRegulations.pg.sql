-- =============================================================================
-- GetDerivedPayrollRegulations
-- Inlined CTE replaces GetDerivedRegulations helper.
-- IsolationLevel >= 3 (Write) required for shared regulations as payroll layers.
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedPayrollRegulations(
    IN p_tenantId       INTEGER,
    IN p_payrollId      INTEGER,
    IN p_regulationDate TIMESTAMP(6),
    IN p_createdBefore  TIMESTAMP(6)
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
          AND (
            r."TenantId" = p_tenantId
            OR (
              r."SharedRegulation" = true
              AND EXISTS (
                SELECT 1 FROM "RegulationShare" rs
                WHERE rs."ProviderRegulationId" = r."Id"
                  AND rs."ConsumerTenantId"     = p_tenantId
                  AND rs."IsolationLevel"       >= 3
              )
            )
          )
          AND r."Created" <= p_createdBefore
          AND (r."ValidFrom" IS NULL OR r."ValidFrom" <= p_regulationDate)
          AND pl."Status" = 0 AND pl."PayrollId" = p_payrollId
    ),
    Regulations AS (SELECT "Id", "Level", "Priority" FROM DerivedRegulations WHERE "RowNumber" = 1)
    SELECT r.*, reg."Level", reg."Priority"
    FROM "Regulation" r
    INNER JOIN Regulations reg ON r."Id" = reg."Id"
    ORDER BY reg."Level" DESC, reg."Priority" DESC;
$$;
