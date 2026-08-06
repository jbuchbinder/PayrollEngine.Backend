-- =============================================================================
-- GetWageTypeResults
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetWageTypeResults(
    IN "tenantId" INTEGER,
    IN "employeeId" INTEGER,
    IN "p_divisionId" INTEGER,
    IN "payrunJobId" INTEGER,
    IN "p_parentPayrunJobId" INTEGER,
    IN "wageTypeNumbers" TEXT,
    IN "p_periodStart" TIMESTAMP(6),
    IN "p_periodEnd" TIMESTAMP(6),
    IN "p_jobStatus" INTEGER,
    IN "p_forecast" TEXT,
    IN "p_evaluationDate" TIMESTAMP(6)
)
LANGUAGE sql
AS $$
DECLARE
    v_wageTypeNumber DECIMAL(28,6);
    v_wageTypeCount  INTEGER;
    v_wageTypeCount := CASE WHEN "wageTypeNumbers" IS NULL THEN 0
                            ELSE jsonb_array_length("wageTypeNumbers"::jsonb) END;

    IF v_wageTypeCount = 1 THEN
        SELECT CAST(jt.val AS DECIMAL(28,6)) INTO v_wageTypeNumber
        FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val)
        LIMIT 1;
    END IF;

        SELECT wtr.*
    FROM "WageTypeResult" wtr
    WHERE wtr."TenantId" = "tenantId"
      AND wtr."EmployeeId" = "employeeId"
      AND (p_divisionId IS NULL        OR wtr."DivisionId" = p_divisionId)
      AND ("payrunJobId" IS NULL       OR wtr."PayrunJobId" = "payrunJobId")
      AND (p_parentPayrunJobId IS NULL OR wtr."ParentJobId" = p_parentPayrunJobId)
      AND ("wageTypeNumbers" IS NULL OR v_wageTypeCount = 0
           OR (v_wageTypeCount = 1 AND wtr."WageTypeNumber" = v_wageTypeNumber)
           OR (v_wageTypeCount > 1 AND wtr."WageTypeNumber" IN (
               SELECT CAST(jt.val AS DECIMAL(28,6))
               FROM jsonb_array_elements_text("wageTypeNumbers"::jsonb) AS jt(val))))
      AND (p_periodStart IS NULL OR wtr."Start" BETWEEN p_periodStart AND p_periodEnd)
      AND (p_jobStatus IS NULL OR wtr."PayrunJobId" IN (
               SELECT pj."Id" FROM "PayrunJob" pj
               WHERE pj."Id" = wtr."PayrunJobId"
                 AND (pj."JobStatus" & p_jobStatus) = pj."JobStatus"))
      AND (wtr."Forecast" IS NULL OR wtr."Forecast" = p_forecast)
      AND (p_evaluationDate IS NULL OR wtr."Created" <= p_evaluationDate)
    ORDER BY wtr."Created";
$$;
