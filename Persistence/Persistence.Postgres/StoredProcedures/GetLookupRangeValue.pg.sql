-- =============================================================================
-- GetLookupRangeValue
-- =============================================================================

CREATE OR REPLACE FUNCTION GetLookupRangeValue(
    IN "lookupId"   INTEGER,
    IN "rangeValue" NUMERIC,
    IN "keyHash"    INTEGER
)
RETURNS TABLE(
    "Id" INT, "Status" INT, "Created" TIMESTAMPTZ, "Updated" TIMESTAMPTZ,
    "LookupId" INT, "Key" TEXT, "KeyHash" INT, "RangeValue" NUMERIC,
    "Value" TEXT, "ValueLocalizations" TEXT, "OverrideType" INT, "LookupHash" INT
)
LANGUAGE sql STABLE AS $$
    SELECT lv.*
    FROM "LookupValue" lv
    WHERE lv."LookupId" = "lookupId"
      AND lv."RangeValue" <= "rangeValue"
      AND ("keyHash" IS NULL OR lv."KeyHash" = "keyHash")
      AND "rangeValue" <= (SELECT MAX(lv2."RangeValue") FROM "LookupValue" lv2 WHERE lv2."LookupId" = "lookupId")
                         + COALESCE((SELECT lk."RangeSize" FROM "Lookup" lk WHERE lk."Id" = "lookupId"), 0.0)
    ORDER BY lv."RangeValue" DESC
    LIMIT 1;
$$;
