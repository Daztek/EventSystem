/*
    ScriptName: es_prv_sql.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[SQL]

    Description: An EventSystem Provider that manages SQL Database functionality
*/

#include "es_inc_core"
#include "nwnx_sql"

const string SQL_LOG_TAG                = "SQL";
const string SQL_SCRIPT_NAME            = "es_prv_sql";

const string SQL_DATABASE_TYPE          = "DatabaseType";
const string SQL_DATABASE_TYPE_MYSQL    = "MYSQL";
const string SQL_DATABASE_TYPE_SQLITE   = "SQLITE";

int SQL_GetTableExists(string sTable);
int SQL_GetLastInsertId();

// @Load
void SQL_Load(string sProviderScript)
{
    object oDataObject = ES_Util_GetDataObject(sProviderScript);
    string sDatabaseType = NWNX_SQL_GetDatabaseType();

    if (sDatabaseType == SQL_DATABASE_TYPE_MYSQL ||
        sDatabaseType == SQL_DATABASE_TYPE_SQLITE)
    {
        SetLocalString(oDataObject, SQL_DATABASE_TYPE, sDatabaseType);

        ES_Util_Log(SQL_LOG_TAG, "* Using Database Type: '" + sDatabaseType + "'");
    }
    else
    {
        SetLocalInt(ES_Core_GetSystemDataObject(sProviderScript), "Disabled", TRUE);

        ES_Util_Log(SQL_LOG_TAG, "* ERROR: Unsupported Database Type: '" + sDatabaseType + "', disabling...");
    }
}

int SQL_GetTableExists(string sTable)
{
    int bReturn = FALSE;
    string sDatabaseType = NWNX_SQL_GetDatabaseType(), sQuery;

    if (sDatabaseType == SQL_DATABASE_TYPE_MYSQL)
        sQuery = "SELECT * FROM information_schema WHERE TABLE_NAME=?;";
    else
    if (sDatabaseType == SQL_DATABASE_TYPE_SQLITE)
        sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;";

    NWNX_SQL_PreparedString(0, sTable);
    NWNX_SQL_ExecutePreparedQuery();

    bReturn = NWNX_SQL_ReadyToReadNextRow();

    return bReturn;
}

int SQL_GetLastInsertId()
{
    int nInsertId = -1;
    string sDatabaseType = NWNX_SQL_GetDatabaseType(), sQuery;

    if (sDatabaseType == SQL_DATABASE_TYPE_MYSQL)
        sQuery = "SELECT LAST_INSERT_ID();";
    else
    if (sDatabaseType == SQL_DATABASE_TYPE_SQLITE)
        sQuery = "SELECT last_insert_rowid();";

    NWNX_SQL_ExecuteQuery(sQuery);

    if (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        nInsertId = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
    }

    return nInsertId;
}

