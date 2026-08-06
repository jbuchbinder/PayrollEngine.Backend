-- =============================================================================
-- DeleteTenant
-- PostgreSQL: DELETE FROM t USING ... (all joins in USING clause)
-- =============================================================================

CREATE OR REPLACE PROCEDURE DeleteTenant(
    IN "tenantId" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM "PayrunResult" pr
    USING "PayrollResult" prl
    WHERE pr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId";

    DELETE FROM "WageTypeCustomResult" wtcr
    USING "WageTypeResult" wtr, "PayrollResult" prl
    WHERE wtcr."WageTypeResultId" = wtr."Id"
      AND wtr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId";

    DELETE FROM "WageTypeResult" wtr
    USING "PayrollResult" prl
    WHERE wtr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId";

    DELETE FROM "CollectorCustomResult" ccr
    USING "CollectorResult" cr, "PayrollResult" prl
    WHERE ccr."CollectorResultId" = cr."Id"
      AND cr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId";

    DELETE FROM "CollectorResult" cr
    USING "PayrollResult" prl
    WHERE cr."PayrollResultId" = prl."Id"
      AND prl."TenantId" = "tenantId";

    DELETE FROM "PayrollResult" WHERE TenantId = "tenantId";

    DELETE FROM "PayrunJobEmployee" pje
    USING "PayrunJob" pj
    WHERE pje."PayrunJobId" = pj."Id"
      AND pj."TenantId" = "tenantId";

    DELETE FROM "PayrunJob" WHERE TenantId = "tenantId";

    DELETE FROM "PayrunParameter" pp
    USING "Payrun" pay
    WHERE pp."PayrunId" = pay."Id"
      AND pay."TenantId" = "tenantId";

    DELETE FROM "Payrun" WHERE TenantId = "tenantId";

    DELETE FROM "PayrollLayer" pl
    USING "Payroll" pay
    WHERE pl."PayrollId" = pay."Id"
      AND pay."TenantId" = "tenantId";

    DELETE FROM "Payroll" WHERE TenantId = "tenantId";

    DELETE FROM "RegulationShare" WHERE ProviderTenantId = "tenantId" OR ConsumerTenantId = "tenantId";

    DELETE FROM "ReportTemplateAudit" rta
    USING "ReportTemplate" rt, "Report" rp, "Regulation" r
    WHERE rta."ReportTemplateId" = rt."Id"
      AND rt."ReportId" = rp."Id"
      AND rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "ReportTemplate" rt
    USING "Report" rp, "Regulation" r
    WHERE rt."ReportId" = rp."Id"
      AND rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "ReportParameterAudit" rpa
    USING "ReportParameter" rpar, "Report" rp, "Regulation" r
    WHERE rpa."ReportParameterId" = rpar."Id"
      AND rpar."ReportId" = rp."Id"
      AND rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "ReportParameter" rpar
    USING "Report" rp, "Regulation" r
    WHERE rpar."ReportId" = rp."Id"
      AND rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "ReportAudit" ra
    USING "Report" rp, "Regulation" r
    WHERE ra."ReportId" = rp."Id"
      AND rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Report" rp
    USING "Regulation" r
    WHERE rp."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "ScriptAudit" sa
    USING "Script" s, "Regulation" r
    WHERE sa."ScriptId" = s."Id"
      AND s."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Script" s
    USING "Regulation" r
    WHERE s."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "LookupValueAudit" lva
    USING "LookupValue" lv, "Lookup" lk, "Regulation" r
    WHERE lva."LookupValueId" = lv."Id"
      AND lv."LookupId" = lk."Id"
      AND lk."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "LookupValue" lv
    USING "Lookup" lk, "Regulation" r
    WHERE lv."LookupId" = lk."Id"
      AND lk."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "LookupAudit" la
    USING "Lookup" lk, "Regulation" r
    WHERE la."LookupId" = lk."Id"
      AND lk."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Lookup" lk
    USING "Regulation" r
    WHERE lk."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CollectorAudit" coa
    USING "Collector" co, "Regulation" r
    WHERE coa."CollectorId" = co."Id"
      AND co."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Collector" co
    USING "Regulation" r
    WHERE co."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "WageTypeAudit" wta
    USING "WageType" wt, "Regulation" r
    WHERE wta."WageTypeId" = wt."Id"
      AND wt."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "WageType" wt
    USING "Regulation" r
    WHERE wt."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CaseRelationAudit" cra
    USING "CaseRelation" cr, "Regulation" r
    WHERE cra."CaseRelationId" = cr."Id"
      AND cr."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CaseRelation" cr
    USING "Regulation" r
    WHERE cr."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CaseFieldAudit" cfa
    USING "CaseField" cf, "Case" c, "Regulation" r
    WHERE cfa."CaseFieldId" = cf."Id"
      AND cf."CaseId" = c."Id"
      AND c."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CaseField" cf
    USING "Case" c, "Regulation" r
    WHERE cf."CaseId" = c."Id"
      AND c."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "CaseAudit" ca
    USING "Case" c, "Regulation" r
    WHERE ca."CaseId" = c."Id"
      AND c."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Case" c
    USING "Regulation" r
    WHERE c."RegulationId" = r."Id"
      AND r."TenantId" = "tenantId";

    DELETE FROM "Regulation" WHERE TenantId = "tenantId";

    DELETE FROM "EmployeeCaseValueChange" ecvc
    USING "EmployeeCaseChange" ecc, "Employee" e
    WHERE ecvc."CaseChangeId" = ecc."Id"
      AND ecc."EmployeeId" = e."Id"
      AND e."TenantId" = "tenantId";

    DELETE FROM "EmployeeCaseChange" ecc
    USING "Employee" e
    WHERE ecc."EmployeeId" = e."Id"
      AND e."TenantId" = "tenantId";

    DELETE FROM "EmployeeCaseDocument" ecd
    USING "EmployeeCaseValue" ecv, "Employee" e
    WHERE ecd."CaseValueId" = ecv."Id"
      AND ecv."EmployeeId" = e."Id"
      AND e."TenantId" = "tenantId";

    DELETE FROM "EmployeeCaseValue" ecv
    USING "Employee" e
    WHERE ecv."EmployeeId" = e."Id"
      AND e."TenantId" = "tenantId";

    DELETE FROM "EmployeeDivision" ed
    USING "Employee" e
    WHERE ed."EmployeeId" = e."Id"
      AND e."TenantId" = "tenantId";

    DELETE FROM "Employee" WHERE TenantId = "tenantId";

    DELETE FROM "CompanyCaseValueChange" ccvc
    USING "CompanyCaseChange" ccc
    WHERE ccvc."CaseChangeId" = ccc."Id"
      AND ccc."TenantId" = "tenantId";

    DELETE FROM "CompanyCaseChange" WHERE TenantId = "tenantId";

    DELETE FROM "CompanyCaseDocument" ccd
    USING "CompanyCaseValue" ccv
    WHERE ccd."CaseValueId" = ccv."Id"
      AND ccv."TenantId" = "tenantId";

    DELETE FROM "CompanyCaseValue" WHERE TenantId = "tenantId";

    DELETE FROM "NationalCaseValueChange" ncvc
    USING "NationalCaseChange" ncc
    WHERE ncvc."CaseChangeId" = ncc."Id"
      AND ncc."TenantId" = "tenantId";

    DELETE FROM "NationalCaseChange" WHERE TenantId = "tenantId";

    DELETE FROM "NationalCaseDocument" ncd
    USING "NationalCaseValue" ncv
    WHERE ncd."CaseValueId" = ncv."Id"
      AND ncv."TenantId" = "tenantId";

    DELETE FROM "NationalCaseValue" WHERE TenantId = "tenantId";

    DELETE FROM "GlobalCaseValueChange" gcvc
    USING "GlobalCaseChange" gcc
    WHERE gcvc."CaseChangeId" = gcc."Id"
      AND gcc."TenantId" = "tenantId";

    DELETE FROM "GlobalCaseChange" WHERE TenantId = "tenantId";

    DELETE FROM "GlobalCaseDocument" gcd
    USING "GlobalCaseValue" gcv
    WHERE gcd."CaseValueId" = gcv."Id"
      AND gcv."TenantId" = "tenantId";

    DELETE FROM "GlobalCaseValue" WHERE TenantId = "tenantId";

    DELETE FROM "WebhookMessage" wm
    USING "Webhook" wh
    WHERE wm."WebhookId" = wh."Id"
      AND wh."TenantId" = "tenantId";

    DELETE FROM "Webhook" WHERE TenantId = "tenantId";
    DELETE FROM "Task" WHERE TenantId = "tenantId";
    DELETE FROM "Log" WHERE TenantId = "tenantId";
    DELETE FROM "ReportLog" WHERE TenantId = "tenantId";
    DELETE FROM "User" WHERE TenantId = "tenantId";
    DELETE FROM "Division" WHERE TenantId = "tenantId";
    DELETE FROM "Calendar" WHERE TenantId = "tenantId";
    DELETE FROM "Tenant" WHERE Id = "tenantId";
END;
$$;
