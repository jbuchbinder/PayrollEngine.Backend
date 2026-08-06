#!/usr/bin/perl -pi
# Quote PascalCase column references in PG SQL files
# alias.ColumnName -> alias."ColumnName"
s/(\w+)\.([A-Z][a-zA-Z0-9]*)\b(?!")/\1."\2"/g;
# Clean up double-double quotes
s/""([^"]+)""/"$1"/g;
