-- =============================================================================
-- GetDerivedCollectors
-- Excludes Binary, Script, ScriptVersion (performance hint)
-- =============================================================================

CREATE OR REPLACE PROCEDURE GetDerivedCollectors(
    IN p_tenantId        INTEGER,
    IN p_payrollId       INTEGER,
    IN p_regulationDate  TIMESTAMP(6),
    IN p_createdBefore   TIMESTAMP(6),
    IN p_collectorNames  TEXT,
    IN p_includeClusters TEXT,
    IN p_excludeClusters TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
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
        co.Id, co.Status, co.Created, co.Updated, co.RegulationId,
        co.Name, co.NameLocalizations,
        co.CollectMode, co.Negated, co.OverrideType, co.ValueType,
        co.Culture, co.CollectorGroups,
        co.StartExpression, co.ApplyExpression, co.EndExpression,
        co.StartActions, co.ApplyActions, co.EndActions,
        co.Threshold, co.MinResult, co.MaxResult,
        co.ScriptHash, co.Attributes, co.Clusters
    FROM Collector co
    INNER JOIN Regulations reg ON co.RegulationId = reg.Id
    WHERE co.Status = 0
      AND co.Created <= p_createdBefore
      AND ((p_includeClusters IS NULL AND p_excludeClusters IS NULL)
           OR IsMatchingCluster(p_includeClusters, p_excludeClusters, co.Clusters) = 1)
      AND (p_collectorNames IS NULL
           OR LOWER(co.Name) IN (
               SELECT LOWER(jt.val)
               FROM jsonb_array_elements_text(p_collectorNames::jsonb) AS jt(val)))
    ORDER BY co.Name, reg.Level DESC, reg.Priority DESC;
END;
$$;
