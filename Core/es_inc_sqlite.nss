/*
    ScriptName: es_inc_sqlite.nss
    Created by: Daz

    Description: Event System SQLite Utility Include
*/

// Returns TRUE if sTableName exists in sDatabase.
int SqlGetTableExistsCampaign(string sDatabase, string sTableName);
// Returns TRUE if sTableName exists on oObject.
int SqlGetTableExistsObject(object oObject, string sTableName);
// Returns the last insert id for sDatabase, -1 on error.
int SqlGetLastInsertIdCampaign(string sDatabase);
// Returns the last insert id for oObject, -1 on error.
int SqlGetLastInsertIdObject(object oObject);
// Returns the number of affected rows by the most recent INSERT, UPDATE or DELETE query for sDatabase, -1 on error.
int SqlGetAffectedRowsCampaign(string sDatabase);
// Returns the number of affected rows by the most recent INSERT, UPDATE or DELETE query for oObject, -1 on error.
int SqlGetAffectedRowsObject(object oObject);
// Prepare a query, if bUseModule is TRUE, the module will be used to hold the database.
sqlquery SqlPrepareQuery(string sDatabase, string sQuery, int bUseModule);

int SqlGetTableExistsCampaign(string sDatabase, string sTableName)
{
    string sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=@tableName;";
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, sQuery);
    SqlBindString(sql, "@tableName", sTableName);

    return SqlStep(sql);
}

int SqlGetTableExistsObject(object oObject, string sTableName)
{
    string sQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name=@tableName;";
    sqlquery sql = SqlPrepareQueryObject(oObject, sQuery);
    SqlBindString(sql, "@tableName", sTableName);

    return SqlStep(sql);
}

int SqlGetLastInsertIdCampaign(string sDatabase)
{
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, "SELECT last_insert_rowid();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetLastInsertIdObject(object oObject)
{
    sqlquery sql = SqlPrepareQueryObject(oObject, "SELECT last_insert_rowid();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetAffectedRowsCampaign(string sDatabase)
{
    sqlquery sql = SqlPrepareQueryCampaign(sDatabase, "SELECT changes();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

int SqlGetAffectedRowsObject(object oObject)
{
    sqlquery sql = SqlPrepareQueryObject(oObject, "SELECT changes();");

    return SqlStep(sql) ? SqlGetInt(sql, 0) : -1;
}

sqlquery SqlPrepareQuery(string sDatabase, string sQuery, int bUseModule)
{
    if (bUseModule)
        return SqlPrepareQueryObject(GetModule(), sQuery);
    else
        return SqlPrepareQueryCampaign(sDatabase, sQuery);
}

