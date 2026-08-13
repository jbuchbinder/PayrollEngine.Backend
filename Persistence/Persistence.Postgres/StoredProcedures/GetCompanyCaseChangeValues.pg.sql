-- =============================================================================
-- GetCompanyCaseChangeValues
-- Pivot function: builds a change-history temp table filtered by tenant, then
-- executes the caller's query against it.
-- =============================================================================

CREATE OR REPLACE FUNCTION GetCompanyCaseChangeValues(
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
        v_caseName      := '"CompanyCaseValue"."CaseName"::text';
        v_caseFieldName := '"CompanyCaseValue"."CaseFieldName"::text';
        v_caseSlot      := '"CompanyCaseValue"."CaseSlot"::text';
    ELSE
        v_caseName      := 'GetLocalizedValue("CompanyCaseValue"."CaseNameLocalizations", ''' || "culture" || ''', "CompanyCaseValue"."CaseName")';
        v_caseFieldName := 'GetLocalizedValue("CompanyCaseValue"."CaseFieldNameLocalizations", ''' || "culture" || ''', "CompanyCaseValue"."CaseFieldName")';
        v_caseSlot      := 'GetLocalizedValue("CompanyCaseValue"."CaseSlotLocalizations", ''' || "culture" || ''', "CompanyCaseValue"."CaseSlot")';
    END IF;

    v_attrSql := BuildAttributeQuery('"CompanyCaseValue"."Attributes"', "attributes");
    v_pivotSql := 'CREATE TEMP TABLE "##CompanyCaseChangeValuePivot" AS SELECT'
        || ' "CompanyCaseChange"."TenantId",'
        || ' "CompanyCaseChange"."Id" AS "CaseChangeId",'
        || ' "CompanyCaseChange"."Created" AS "CaseChangeCreated",'
        || ' "CompanyCaseChange"."Reason",'
        || ' "CompanyCaseChange"."ValidationCaseName"::text,'
        || ' "CompanyCaseChange"."CancellationType",'
        || ' "CompanyCaseChange"."CancellationId",'
        || ' "CompanyCaseChange"."CancellationDate",'
        || ' NULL::INTEGER AS "EmployeeId",'
        || ' "CompanyCaseChange"."UserId",'
        || ' "User"."Identifier"::text AS "UserIdentifier",'
        || ' "CompanyCaseChange"."DivisionId",'
        || ' "CompanyCaseValue"."Id",'
        || ' "CompanyCaseValue"."Created",'
        || ' "CompanyCaseValue"."Updated",'
        || ' "CompanyCaseValue"."Status",'
        || ' ' || v_caseName      || ' AS "CaseName",'
        || ' ' || v_caseFieldName || ' AS "CaseFieldName",'
        || ' ' || v_caseSlot      || ' AS "CaseSlot",'
        || ' "CompanyCaseValue"."CaseRelation",'
        || ' "CompanyCaseValue"."ValueType",'
        || ' "CompanyCaseValue"."Value",'
        || ' "CompanyCaseValue"."NumericValue",'
        || ' "CompanyCaseValue"."Culture"::text,'
        || ' "CompanyCaseValue"."Start",'
        || ' "CompanyCaseValue"."End",'
        || ' "CompanyCaseValue"."Forecast"::text,'
        || ' "CompanyCaseValue"."Tags",'
        || ' "CompanyCaseValue"."Attributes",'
        || ' (SELECT COUNT(*) FROM "CompanyCaseDocument" WHERE "CaseValueId" = "CompanyCaseValue"."Id") AS "Documents"'
        || v_attrSql
        || ' FROM "CompanyCaseValue"'
        || ' LEFT JOIN "CompanyCaseValueChange" ON "CompanyCaseValue"."Id" = "CompanyCaseValueChange"."CaseValueId"'
        || ' LEFT JOIN "CompanyCaseChange" ON "CompanyCaseValueChange"."CaseChangeId" = "CompanyCaseChange"."Id"'
        || ' LEFT JOIN "User" ON "User"."Id" = "CompanyCaseChange"."UserId"'
        || ' WHERE "CompanyCaseChange"."TenantId" = ' || "parentId"::TEXT;

    DROP TABLE IF EXISTS "##CompanyCaseChangeValuePivot";
    EXECUTE v_pivotSql;
    RETURN QUERY EXECUTE "sql";
    DROP TABLE IF EXISTS "##CompanyCaseChangeValuePivot";
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS "##CompanyCaseChangeValuePivot";
    RAISE;
END;
$$;
