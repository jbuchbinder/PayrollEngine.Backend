-- =============================================================================
-- GetCompanyCaseValues
-- Pivot function: creates a temp table filtered by tenant, then executes the
-- caller's query against it. PostgreSQL procedures cannot return result sets,
-- so this is a FUNCTION + RETURNS TABLE with RETURN QUERY EXECUTE.
-- =============================================================================

DROP FUNCTION IF EXISTS GetCompanyCaseValues;
DROP PROCEDURE IF EXISTS GetCompanyCaseValues;

CREATE OR REPLACE FUNCTION GetCompanyCaseValues(
    IN "parentId"   INTEGER,
    IN "employeeId" INTEGER,
    IN "divisionId" INTEGER,
    IN "sql"        TEXT,
    IN "attributes" TEXT,
    IN "culture"    TEXT
)
RETURNS SETOF "CompanyCaseValue"
LANGUAGE plpgsql
AS $$
DECLARE
    v_attrSql  TEXT;
    v_pivotSql TEXT;
BEGIN
    v_attrSql := BuildAttributeQuery('"CompanyCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##CompanyCaseValuePivot" AS SELECT "CompanyCaseValue".*'
        || v_attrSql
        || ' FROM "CompanyCaseValue" WHERE "CompanyCaseValue"."TenantId" = '
        || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##CompanyCaseValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##CompanyCaseValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##CompanyCaseValuePivot";
    RAISE;
END;
$$;
