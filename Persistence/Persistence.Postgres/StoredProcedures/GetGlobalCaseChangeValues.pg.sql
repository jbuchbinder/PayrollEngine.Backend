-- =============================================================================
-- GetGlobalCaseChangeValues
-- Pivot function: builds a change-history temp table filtered by tenant, then
-- executes the caller's query against it.
-- =============================================================================

CREATE OR REPLACE FUNCTION GetGlobalCaseChangeValues(
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
        v_caseName      := '"GlobalCaseValue"."CaseName"::text';
        v_caseFieldName := '"GlobalCaseValue"."CaseFieldName"::text';
        v_caseSlot      := '"GlobalCaseValue"."CaseSlot"::text';
    ELSE
        v_caseName      := 'GetLocalizedValue("GlobalCaseValue"."CaseNameLocalizations", ''' || "culture" || ''', "GlobalCaseValue"."CaseName")';
        v_caseFieldName := 'GetLocalizedValue("GlobalCaseValue"."CaseFieldNameLocalizations", ''' || "culture" || ''', "GlobalCaseValue"."CaseFieldName")';
        v_caseSlot      := 'GetLocalizedValue("GlobalCaseValue"."CaseSlotLocalizations", ''' || "culture" || ''', "GlobalCaseValue"."CaseSlot")';
    END IF;

    v_attrSql := BuildAttributeQuery('"GlobalCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##GlobalCaseChangeValuePivot" AS SELECT'
        || ' "GlobalCaseChange"."TenantId",'
        || ' "GlobalCaseChange"."Id" AS "CaseChangeId",'
        || ' "GlobalCaseChange"."Created" AS "CaseChangeCreated",'
        || ' "GlobalCaseChange"."Reason",'
        || ' "GlobalCaseChange"."ValidationCaseName"::text,'
        || ' "GlobalCaseChange"."CancellationType",'
        || ' "GlobalCaseChange"."CancellationId",'
        || ' "GlobalCaseChange"."CancellationDate",'
        || ' NULL::INTEGER AS "EmployeeId",'
        || ' "GlobalCaseChange"."UserId",'
        || ' "User"."Identifier"::text AS "UserIdentifier",'
        || ' "GlobalCaseChange"."DivisionId",'
        || ' "GlobalCaseValue"."Id",'
        || ' "GlobalCaseValue"."Created",'
        || ' "GlobalCaseValue"."Updated",'
        || ' "GlobalCaseValue"."Status",'
        || ' ' || v_caseName      || ' AS "CaseName",'
        || ' ' || v_caseFieldName || ' AS "CaseFieldName",'
        || ' ' || v_caseSlot      || ' AS "CaseSlot",'
        || ' "GlobalCaseValue"."CaseRelation",'
        || ' "GlobalCaseValue"."ValueType",'
        || ' "GlobalCaseValue"."Value",'
        || ' "GlobalCaseValue"."NumericValue",'
        || ' "GlobalCaseValue"."Culture"::text,'
        || ' "GlobalCaseValue"."Start",'
        || ' "GlobalCaseValue"."End",'
        || ' "GlobalCaseValue"."Forecast"::text,'
        || ' "GlobalCaseValue"."Tags",'
        || ' "GlobalCaseValue"."Attributes",'
        || ' (SELECT COUNT(*) FROM "GlobalCaseDocument" WHERE "CaseValueId" = "GlobalCaseValue"."Id") AS "Documents"'
        || v_attrSql
        || ' FROM "GlobalCaseValue"'
        || ' LEFT JOIN "GlobalCaseValueChange" ON "GlobalCaseValue"."Id" = "GlobalCaseValueChange"."CaseValueId"'
        || ' LEFT JOIN "GlobalCaseChange" ON "GlobalCaseValueChange"."CaseChangeId" = "GlobalCaseChange"."Id"'
        || ' LEFT JOIN "User" ON "User"."Id" = "GlobalCaseChange"."UserId"'
        || ' WHERE "GlobalCaseChange"."TenantId" = ' || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##GlobalCaseChangeValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##GlobalCaseChangeValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##GlobalCaseChangeValuePivot";
    RAISE;
END;
$$;
