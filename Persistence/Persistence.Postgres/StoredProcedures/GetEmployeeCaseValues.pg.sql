-- =============================================================================
-- GetEmployeeCaseValues
-- Pivot function: creates a temp table filtered by employee (parentId = employee
-- id), then executes the caller's query against it.
-- =============================================================================

DROP FUNCTION IF EXISTS GetEmployeeCaseValues;
DROP PROCEDURE IF EXISTS GetEmployeeCaseValues;

CREATE OR REPLACE FUNCTION GetEmployeeCaseValues(
    IN "parentId"   INTEGER,
    IN "employeeId" INTEGER,
    IN "divisionId" INTEGER,
    IN "sql"        TEXT,
    IN "attributes" TEXT,
    IN "culture"    TEXT
)
RETURNS SETOF "EmployeeCaseValue"
LANGUAGE plpgsql
AS $$
DECLARE
    v_attrSql  TEXT;
    v_pivotSql TEXT;
BEGIN
    v_attrSql := BuildAttributeQuery('"EmployeeCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##EmployeeCaseValuePivot" AS SELECT "EmployeeCaseValue".*'
        || v_attrSql
        || ' FROM "EmployeeCaseValue" WHERE "EmployeeCaseValue"."EmployeeId" = '
        || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##EmployeeCaseValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##EmployeeCaseValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##EmployeeCaseValuePivot";
    RAISE;
END;
$$;
