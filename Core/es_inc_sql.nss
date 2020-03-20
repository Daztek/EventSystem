/*
    ScriptName: es_inc_sql.nss
    Created by: Daz

    Description: Event System - SQL Wrapper Include
*/

#include "nwnx_sql"

int SQL_GetTableExists(string sTable);
int SQL_GetLastInsertId();

int SQL_GetTableExists(string sTable)
{
    int bReturn = FALSE;
    string sDatabaseType = NWNX_SQL_GetDatabaseType(), sQuery;

    if (sDatabaseType == "SQLITE")
        sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;";
    else
    if (sDatabaseType == "MYSQL")
        sQuery = "SELECT * FROM information_schema WHERE TABLE_NAME=?;"

    NWNX_SQL_PreparedString(0, sTable);
    NWNX_SQL_ExecutePreparedQuery();

    bReturn = NWNX_SQL_ReadyToReadNextRow();

    return bReturn;
}

int SQL_GetLastInsertId()
{
    int nInsertId = -1;
   	string sDatabaseType = NWNX_SQL_GetDatabaseType(), sGetLastInsertId;

    if (sDatabaseType == "SQLITE")
        sGetLastInsertId = "SELECT last_insert_rowid();"
    else
    if (sDatabaseType == "MYSQL")
        sGetLastInsertId = "SELECT LAST_INSERT_ID();";

    NWNX_SQL_ExecuteQuery(sGetLastInsertId);

    if( NWNX_SQL_ReadyToReadNextRow() )
    {
        NWNX_SQL_ReadNextRow();

        nInsertId = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
    }

    return nInsertId;
}

