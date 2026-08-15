-- =============================================================================
-- GetGlobalCaseValues
-- Pivot function: creates a temp table filtered by tenant, then executes the
-- caller's query against it.
-- =============================================================================

DROP FUNCTION IF EXISTS GetGlobalCaseValues;
DROP PROCEDURE IF EXISTS GetGlobalCaseValues;

CREATE OR REPLACE FUNCTION GetGlobalCaseValues(
    IN "parentId"   INTEGER,
    IN "employeeId" INTEGER,
    IN "divisionId" INTEGER,
    IN "sql"        TEXT,
    IN "attributes" TEXT,
    IN "culture"    TEXT
)
RETURNS SETOF "GlobalCaseValue"
LANGUAGE plpgsql
AS $$
DECLARE
    v_attrSql  TEXT;
    v_pivotSql TEXT;
BEGIN
    v_attrSql := BuildAttributeQuery('"GlobalCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##GlobalCaseValuePivot" AS SELECT "GlobalCaseValue".*'
        || v_attrSql
        || ' FROM "GlobalCaseValue" WHERE "GlobalCaseValue"."TenantId" = '
        || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##GlobalCaseValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##GlobalCaseValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##GlobalCaseValuePivot";
    RAISE;
END;
$$;
