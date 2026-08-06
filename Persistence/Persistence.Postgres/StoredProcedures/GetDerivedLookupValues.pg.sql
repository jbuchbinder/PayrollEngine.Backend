-- =============================================================================
-- GetDerivedLookupValues
-- lv."Key" double-quoted (reserved keyword in PG)
-- "Case"-sensitive key filter (no LOWER(), identical to T-SQL)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedLookupValues(
    IN "tenantId" INTEGER,
    IN "payrollId" INTEGER,
    IN "regulationDate" TIMESTAMP(6),
    IN "createdBefore" TIMESTAMP(6),
    IN "p_lookupNames" TEXT,
    IN "p_lookupKeys" TEXT
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
        lv.*
    FROM "LookupValue" lv
    INNER JOIN "Lookup" lk ON lv."LookupId" = lk."Id"
    INNER JOIN Regulations reg ON lk."RegulationId" = reg."Id"
    WHERE lv."Status" = 0
      AND lv."Created" <= "createdBefore"
      AND (p_lookupNames IS NULL
           OR LOWER(lk."Name") IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text(p_lookupNames::jsonb) AS jt(val)))
      AND (p_lookupKeys IS NULL
           OR lv."Key" IN (
               SELECT jt.val
               FROM jsonb_array_elements_text(p_lookupKeys::jsonb) AS jt(val)))
    ORDER BY reg."Level" DESC, reg."Priority" DESC;
$$;
