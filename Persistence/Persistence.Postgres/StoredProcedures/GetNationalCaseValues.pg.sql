-- =============================================================================
-- GetNationalCaseValues
-- Pivot function: creates a temp table filtered by tenant, then executes the
-- caller's query against it.
-- =============================================================================

DROP FUNCTION IF EXISTS GetNationalCaseValues;
DROP PROCEDURE IF EXISTS GetNationalCaseValues;

CREATE OR REPLACE FUNCTION GetNationalCaseValues(
    IN "parentId"   INTEGER,
    IN "employeeId" INTEGER,
    IN "divisionId" INTEGER,
    IN "sql"        TEXT,
    IN "attributes" TEXT,
    IN "culture"    TEXT
)
RETURNS SETOF "NationalCaseValue"
LANGUAGE plpgsql
AS $$
DECLARE
    v_attrSql  TEXT;
    v_pivotSql TEXT;
BEGIN
    v_attrSql := BuildAttributeQuery('"NationalCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##NationalCaseValuePivot" AS SELECT "NationalCaseValue".*'
        || v_attrSql
        || ' FROM "NationalCaseValue" WHERE "NationalCaseValue"."TenantId" = '
        || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##NationalCaseValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##NationalCaseValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##NationalCaseValuePivot";
    RAISE;
END;
$$;
