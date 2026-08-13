using System;
using System.Data;
using Dapper;

namespace PayrollEngine.Persistence;

/// <summary>
/// Maps <see cref="DateTimeOffset"/> to <c>timestamptz</c> under Npgsql.
/// Dapper has no default mapping for DateTimeOffset, so persisting payrun
/// results (whose Start/End are DateTimeOffset) failed with
/// "Unsupported database type DateTimeOffset". Registering this handler fixes it.
/// </summary>
public class DateTimeOffsetTypeHandler : SqlMapper.TypeHandler<DateTimeOffset>
{
    public override void SetValue(IDbDataParameter parameter, DateTimeOffset value)
    {
        // Npgsql maps DbType.DateTimeOffset -> timestamptz (see DbParameterCollection).
        parameter.DbType = DbType.DateTimeOffset;
        parameter.Value = value;
    }

    public override DateTimeOffset Parse(object value)
    {
        return value switch
        {
            DateTimeOffset dto => dto,
            DateTime dt => new DateTimeOffset(DateTime.SpecifyKind(dt, DateTimeKind.Utc)),
            _ => DateTimeOffset.Parse(value?.ToString() ?? string.Empty)
        };
    }
}
