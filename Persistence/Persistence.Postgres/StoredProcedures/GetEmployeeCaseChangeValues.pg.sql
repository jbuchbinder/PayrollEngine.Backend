-- =============================================================================
-- GetEmployeeCaseChangeValues
-- Pivot function: builds a change-history temp table filtered by employee
-- (parentId = employee id), then executes the caller's query against it.
-- TenantId is sourced from the Employee join (EmployeeCaseChange has no tenant).
-- =============================================================================

CREATE OR REPLACE FUNCTION GetEmployeeCaseChangeValues(
    IN "parentId"   INTEGER,
    IN "employeeId" INTEGER,
    IN "divisionId" INTEGER,
    IN "sql"        TEXT,
    IN "attributes" TEXT,
    IN "culture"    TEXT
)
RETURNS TABLE(
    "TenantId" INTEGER, "CaseChangeId" INTEGER, "CaseChangeCreated" TIMESTAMPTZ,
    "Reason" TEXT, "ValidationCaseName" TEXT, "CancellationType" INTEGER,
    "CancellationId" INTEGER, "CancellationDate" TIMESTAMPTZ, "EmployeeId" INTEGER,
    "UserId" INTEGER, "UserIdentifier" TEXT, "DivisionId" INTEGER,
    "Id" INTEGER, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ, "Status" INTEGER,
    "CaseName" TEXT, "CaseFieldName" TEXT, "CaseSlot" TEXT,
    "CaseRelation" TEXT, "ValueType" INTEGER, "Value" TEXT, "NumericValue" NUMERIC,
    "Culture" TEXT, "Start" TIMESTAMPTZ, "End" TIMESTAMPTZ, "Forecast" TEXT,
    "Tags" TEXT, "Attributes" TEXT, "Documents" BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_attrSql       TEXT;
    v_pivotSql      TEXT;
    v_caseName      TEXT;
    v_caseFieldName TEXT;
    v_caseSlot      TEXT;
BEGIN
    IF "culture" IS NULL THEN
        v_caseName      := '"EmployeeCaseValue"."CaseName"::text';
        v_caseFieldName := '"EmployeeCaseValue"."CaseFieldName"::text';
        v_caseSlot      := '"EmployeeCaseValue"."CaseSlot"::text';
    ELSE
        v_caseName      := 'GetLocalizedValue("EmployeeCaseValue"."CaseNameLocalizations", ''' || "culture" || ''', "EmployeeCaseValue"."CaseName")';
        v_caseFieldName := 'GetLocalizedValue("EmployeeCaseValue"."CaseFieldNameLocalizations", ''' || "culture" || ''', "EmployeeCaseValue"."CaseFieldName")';
        v_caseSlot      := 'GetLocalizedValue("EmployeeCaseValue"."CaseSlotLocalizations", ''' || "culture" || ''', "EmployeeCaseValue"."CaseSlot")';
    END IF;

    v_attrSql := BuildAttributeQuery('"EmployeeCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##EmployeeCaseChangeValuePivot" AS SELECT'
        || ' "Employee"."TenantId",'
        || ' "EmployeeCaseChange"."Id" AS "CaseChangeId",'
        || ' "EmployeeCaseChange"."Created" AS "CaseChangeCreated",'
        || ' "EmployeeCaseChange"."Reason",'
        || ' "EmployeeCaseChange"."ValidationCaseName"::text,'
        || ' "EmployeeCaseChange"."CancellationType",'
        || ' "EmployeeCaseChange"."CancellationId",'
        || ' "EmployeeCaseChange"."CancellationDate",'
        || ' "EmployeeCaseChange"."EmployeeId",'
        || ' "EmployeeCaseChange"."UserId",'
        || ' "User"."Identifier"::text AS "UserIdentifier",'
        || ' "EmployeeCaseChange"."DivisionId",'
        || ' "EmployeeCaseValue"."Id",'
        || ' "EmployeeCaseValue"."Created",'
        || ' "EmployeeCaseValue"."Updated",'
        || ' "EmployeeCaseValue"."Status",'
        || ' ' || v_caseName      || ' AS "CaseName",'
        || ' ' || v_caseFieldName || ' AS "CaseFieldName",'
        || ' ' || v_caseSlot      || ' AS "CaseSlot",'
        || ' "EmployeeCaseValue"."CaseRelation",'
        || ' "EmployeeCaseValue"."ValueType",'
        || ' "EmployeeCaseValue"."Value",'
        || ' "EmployeeCaseValue"."NumericValue",'
        || ' "EmployeeCaseValue"."Culture"::text,'
        || ' "EmployeeCaseValue"."Start",'
        || ' "EmployeeCaseValue"."End",'
        || ' "EmployeeCaseValue"."Forecast"::text,'
        || ' "EmployeeCaseValue"."Tags",'
        || ' "EmployeeCaseValue"."Attributes",'
        || ' (SELECT COUNT(*) FROM "EmployeeCaseDocument" WHERE "CaseValueId" = "EmployeeCaseValue"."Id") AS "Documents"'
        || v_attrSql
        || ' FROM "EmployeeCaseValue"'
        || ' LEFT JOIN "EmployeeCaseValueChange" ON "EmployeeCaseValue"."Id" = "EmployeeCaseValueChange"."CaseValueId"'
        || ' LEFT JOIN "EmployeeCaseChange" ON "EmployeeCaseValueChange"."CaseChangeId" = "EmployeeCaseChange"."Id"'
        || ' LEFT JOIN "User" ON "User"."Id" = "EmployeeCaseChange"."UserId"'
        || ' LEFT JOIN "Employee" ON "Employee"."Id" = "EmployeeCaseChange"."EmployeeId"'
        || ' WHERE "EmployeeCaseChange"."EmployeeId" = ' || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##EmployeeCaseChangeValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##EmployeeCaseChangeValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##EmployeeCaseChangeValuePivot";
    RAISE;
END;
$$;
