/*
    ScriptName: es_cc_sql.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[SQL]

    Description: An EventSystem Core Component that manages SQL Database functionality
*/

#include "es_inc_core"
#include "nwnx_sql"

const string SQL_LOG_TAG                = "SQL";
const string SQL_SCRIPT_NAME            = "es_cc_sql";

const string SQL_DATABASE_TYPE_MYSQL    = "MYSQL";
const string SQL_DATABASE_TYPE_SQLITE   = "SQLITE";

int SQL_GetTableExists(string sTable);
int SQL_GetLastInsertId();

// @Load
void SQL_Load(string sCoreComponentScript)
{
    object oDataObject = ES_Util_GetDataObject(sCoreComponentScript);
    string sDatabaseType = NWNX_SQL_GetDatabaseType();

    if (sDatabaseType == SQL_DATABASE_TYPE_MYSQL ||
        sDatabaseType == SQL_DATABASE_TYPE_SQLITE)
    {
        ES_Util_Log(SQL_LOG_TAG, "* Using Database Type: '" + sDatabaseType + "'");
    }
    else
    {
        ES_Core_DisableComponent(sCoreComponentScript);

        ES_Util_Log(SQL_LOG_TAG, "* ERROR: Unsupported Database Type: '" + sDatabaseType + "', disabling...");
    }
}

int SQL_GetTableExists(string sTable)
{
    string sDatabaseType = NWNX_SQL_GetDatabaseType(), sQuery;
    if (sDatabaseType == SQL_DATABASE_TYPE_MYSQL)
        sQuery = "SELECT * FROM information_schema WHERE TABLE_NAME=?;";
    else
    if (sDatabaseType == SQL_DATABASE_TYPE_SQLITE)
        sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=?;";

    NWNX_SQL_PreparedString(0, sTable);
    NWNX_SQL_ExecutePreparedQuery();

    int bTableExists = NWNX_SQL_ReadyToReadNextRow();

    return bTableExists;
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

    if (NWNX_SQL_ExecuteQuery(sQuery))
    {
        if (NWNX_SQL_ReadyToReadNextRow())
        {
            NWNX_SQL_ReadNextRow();

            nInsertId = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
        }
    }

    return nInsertId;
}

