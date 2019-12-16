/*
    ScriptName: es_inc_sql.nss
    Created by: Daz

    Description: Event System - SQL Wrapper Include
*/

#include "nwnx_sql"

int SQLite_GetTableExists(string sTable);

int SQLite_GetTableExists(string sTable)
{
    int bReturn = FALSE;

    string sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;";

    if (NWNX_SQL_PrepareQuery(sQuery))
    {
        NWNX_SQL_PreparedString(0, sTable);
        NWNX_SQL_ExecutePreparedQuery();

        bReturn = NWNX_SQL_ReadyToReadNextRow();
    }

    return bReturn;
}
