-- =============================================================================
-- GetDerivedWageTypes
-- Excludes Binary, Script, ScriptVersion (performance hint identical to T-SQL)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedWageTypes(
    IN p_tenantId        INTEGER,
    IN p_payrollId       INTEGER,
    IN p_regulationDate  TIMESTAMP(6),
    IN p_createdBefore   TIMESTAMP(6),
    IN p_wageTypeNumbers TEXT,
    IN p_includeClusters TEXT,
    IN p_excludeClusters TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH DerivedRegulations AS (
        SELECT r.Id, pl.Level, pl.Priority,
            ROW_NUMBER() OVER (
                PARTITION BY pl.Id, r.Name
                ORDER BY r.ValidFrom DESC, r.Created DESC
            ) AS RowNumber
        FROM PayrollLayer pl
        INNER JOIN Regulation r ON pl.RegulationName = r.Name
        WHERE r.Status = 0
          AND (r.TenantId = p_tenantId OR r.SharedRegulation = 1)
          AND r.Created <= p_createdBefore
          AND (r.ValidFrom IS NULL OR r.ValidFrom <= p_regulationDate)
          AND pl.Status = 0 AND pl.PayrollId = p_payrollId
    ),
    Regulations AS (SELECT Id, Level, Priority FROM DerivedRegulations WHERE RowNumber = 1)
    SELECT
        reg.Id AS RegulationId, reg.Level, reg.Priority,
        wt.Id, wt.Status, wt.Created, wt.Updated, wt.RegulationId,
        wt.Name, wt.NameLocalizations, wt.WageTypeNumber,
        wt.Description, wt.DescriptionLocalizations,
        wt.OverrideType, wt.ValueType, wt.Calendar, wt.Culture,
        wt.Collectors, wt.CollectorGroups,
        wt.ValueExpression, wt.ResultExpression,
        wt.ValueActions, wt.ResultActions,
        wt.ScriptHash, wt.Attributes, wt.Clusters
    FROM WageType wt
    INNER JOIN Regulations reg ON wt.RegulationId = reg.Id
    WHERE wt.Status = 0
      AND wt.Created <= p_createdBefore
      AND ((p_includeClusters IS NULL AND p_excludeClusters IS NULL)
           OR IsMatchingCluster(p_includeClusters, p_excludeClusters, wt.Clusters) = 1)
      AND (p_wageTypeNumbers IS NULL
           OR wt.WageTypeNumber IN (
               SELECT CAST(jt.val AS DECIMAL(28,6))
               FROM jsonb_array_elements_text(p_wageTypeNumbers::jsonb) AS jt(val)))
    ORDER BY wt.WageTypeNumber, reg.Level DESC, reg.Priority DESC;
END;
$$;
