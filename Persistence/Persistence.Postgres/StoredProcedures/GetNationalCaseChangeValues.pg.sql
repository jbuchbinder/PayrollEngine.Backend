-- =============================================================================
-- GetNationalCaseChangeValues
-- Pivot function: builds a change-history temp table filtered by tenant, then
-- executes the caller's query against it.
-- =============================================================================

DROP FUNCTION IF EXISTS GetNationalCaseChangeValues;
DROP PROCEDURE IF EXISTS GetNationalCaseChangeValues;

CREATE OR REPLACE FUNCTION GetNationalCaseChangeValues(
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
        v_caseName      := '"NationalCaseValue"."CaseName"::text';
        v_caseFieldName := '"NationalCaseValue"."CaseFieldName"::text';
        v_caseSlot      := '"NationalCaseValue"."CaseSlot"::text';
    ELSE
        v_caseName      := 'GetLocalizedValue("NationalCaseValue"."CaseNameLocalizations", ''' || "culture" || ''', "NationalCaseValue"."CaseName")';
        v_caseFieldName := 'GetLocalizedValue("NationalCaseValue"."CaseFieldNameLocalizations", ''' || "culture" || ''', "NationalCaseValue"."CaseFieldName")';
        v_caseSlot      := 'GetLocalizedValue("NationalCaseValue"."CaseSlotLocalizations", ''' || "culture" || ''', "NationalCaseValue"."CaseSlot")';
    END IF;

    v_attrSql := BuildAttributeQuery('"NationalCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##NationalCaseChangeValuePivot" AS SELECT'
        || ' "NationalCaseChange"."TenantId",'
        || ' "NationalCaseChange"."Id" AS "CaseChangeId",'
        || ' "NationalCaseChange"."Created" AS "CaseChangeCreated",'
        || ' "NationalCaseChange"."Reason",'
        || ' "NationalCaseChange"."ValidationCaseName"::text,'
        || ' "NationalCaseChange"."CancellationType",'
        || ' "NationalCaseChange"."CancellationId",'
        || ' "NationalCaseChange"."CancellationDate",'
        || ' NULL::INTEGER AS "EmployeeId",'
        || ' "NationalCaseChange"."UserId",'
        || ' "User"."Identifier"::text AS "UserIdentifier",'
        || ' "NationalCaseChange"."DivisionId",'
        || ' "NationalCaseValue"."Id",'
        || ' "NationalCaseValue"."Created",'
        || ' "NationalCaseValue"."Updated",'
        || ' "NationalCaseValue"."Status",'
        || ' ' || v_caseName      || ' AS "CaseName",'
        || ' ' || v_caseFieldName || ' AS "CaseFieldName",'
        || ' ' || v_caseSlot      || ' AS "CaseSlot",'
        || ' "NationalCaseValue"."CaseRelation",'
        || ' "NationalCaseValue"."ValueType",'
        || ' "NationalCaseValue"."Value",'
        || ' "NationalCaseValue"."NumericValue",'
        || ' "NationalCaseValue"."Culture"::text,'
        || ' "NationalCaseValue"."Start",'
        || ' "NationalCaseValue"."End",'
        || ' "NationalCaseValue"."Forecast"::text,'
        || ' "NationalCaseValue"."Tags",'
        || ' "NationalCaseValue"."Attributes",'
        || ' (SELECT COUNT(*) FROM "NationalCaseDocument" WHERE "CaseValueId" = "NationalCaseValue"."Id") AS "Documents"'
        || v_attrSql
        || ' FROM "NationalCaseValue"'
        || ' LEFT JOIN "NationalCaseValueChange" ON "NationalCaseValue"."Id" = "NationalCaseValueChange"."CaseValueId"'
        || ' LEFT JOIN "NationalCaseChange" ON "NationalCaseValueChange"."CaseChangeId" = "NationalCaseChange"."Id"'
        || ' LEFT JOIN "User" ON "User"."Id" = "NationalCaseChange"."UserId"'
        || ' WHERE "NationalCaseChange"."TenantId" = ' || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##NationalCaseChangeValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##NationalCaseChangeValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##NationalCaseChangeValuePivot";
    RAISE;
END;
$$;
