using System;
using System.Data;
using Dapper;
using Npgsql;
using NpgsqlTypes;

namespace PayrollEngine.Persistence.Postgres;

/// <summary>
/// Maps <see cref="DateTime"/> values to PostgreSQL <c>timestamptz</c>.
/// Npgsql 9 defaults untyped <c>DateTime</c> parameters to <c>timestamp without
/// time zone</c> (and removed the legacy timestamp behavior switch), which rejects
/// UTC <c>DateTime</c> values and mismatches the schema's <c>TIMESTAMPTZ</c> columns.
/// This handler is registered by the PostgreSQL provider only (not in the shared
/// <see cref="DapperTypes"/>), keeping the shared persistence layer provider-agnostic.
/// </summary>
public sealed class DateTimeHandler : SqlMapper.TypeHandler<DateTime>
{
    /// <inheritdoc />
    public override void SetValue(IDbDataParameter parameter, DateTime value)
    {
        if (parameter is NpgsqlParameter npgsqlParameter)
        {
            npgsqlParameter.NpgsqlDbType = NpgsqlDbType.TimestampTz;
            npgsqlParameter.Value = value;
        }
        else
        {
            parameter.Value = value;
        }
    }

    /// <inheritdoc />
    public override DateTime Parse(object value)
    {
        if (value is DateTime dateTime)
        {
            return dateTime;
        }
        if (value is DateTimeOffset dateTimeOffset)
        {
            return dateTimeOffset.UtcDateTime;
        }
        return Convert.ToDateTime(value);
    }
}
