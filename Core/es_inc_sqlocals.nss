/*
    ScriptName: es_inc_sqlocals.nss
    Created by: Daz

    Description: Event System Utility Include for SQLite-based Local Variables on the Module
*/

const string SQLOCALS_TABLE_NAME    = "sqlocals_table";

const int SQLOCALS_TYPE_ALL         = 0;
const int SQLOCALS_TYPE_INT         = 1;
const int SQLOCALS_TYPE_FLOAT       = 2;
const int SQLOCALS_TYPE_STRING      = 4;
const int SQLOCALS_TYPE_OBJECT      = 8;
const int SQLOCALS_TYPE_VECTOR      = 16;

// Get oObject's SQLocal integer variable sVarName
int SQLocals_GetInt(object oObject, string sVarName);
// Set oObject's SQLocal integer variable sVarName to nValue
void SQLocals_SetInt(object oObject, string sVarName, int nValue);
// Delete oObject's SQLocal integer variable sVarName
void SQLocals_DeleteInt(object oObject, string sVarName);

// Get oObject's SQLocal float variable sVarName
float SQLocals_GetFloat(object oObject, string sVarName);
// Set oObject's SQLocal float variable sVarName to fValue
void SQLocals_SetFloat(object oObject, string sVarName, float fValue);
// Delete oObject's SQLocal float variable sVarName
void SQLocals_DeleteFloat(object oObject, string sVarName);

// Get oObject's SQLocal string variable sVarName
string SQLocals_GetString(object oObject, string sVarName);
// Set oObject's SQLocal string variable sVarName to sValue
void SQLocals_SetString(object oObject, string sVarName, string sValue);
// Delete oObject's SQLocal string variable sVarName
void SQLocals_DeleteString(object oObject, string sVarName);

// Get oObject's SQLocal object variable sVarName
object SQLocals_GetObject(object oObject, string sVarName);
// Set oObject's SQLocal object variable sVarName to oValue
void SQLocals_SetObject(object oObject, string sVarName, object oValue);
// Delete oObject's SQLocal object variable sVarName
void SQLocals_DeleteObject(object oObject, string sVarName);

// Get oObject's SQLocal vector variable sVarName
vector SQLocals_GetVector(object oObject, string sVarName);
// Set oObject's SQLocal vector variable sVarName to vValue
void SQLocals_SetVector(object oObject, string sVarName, vector vValue);
// Delete oObject's SQLocal vector variable sVarName
void SQLocals_DeleteVector(object oObject, string sVarName);

void SQLocals_Delete(object oObject, int nType = SQLOCALS_TYPE_ALL, string sLike = "", string sEscape = "");
int SQLocals_Count(object oObject, int nType = SQLOCALS_TYPE_ALL, string sLike = "", string sEscape = "");
int SQLocals_IsSet(object oObject, string sVarName, int nType);
int SQLocals_GetLastUpdated_UnixEpoch(object oObject, string sVarName, int nType);
string SQLocals_GetLastUpdated_UTC(object oObject, string sVarName, int nType);

/* INTERNAL */
void SQLocals_CreateTable()
{
    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "CREATE TABLE IF NOT EXISTS " + SQLOCALS_TABLE_NAME + " (" +
        "object TEXT, " +
        "type INTEGER, " +
        "varname TEXT, " +
        "value TEXT, " +
        "timestamp INTEGER, " +
        "PRIMARY KEY(object, type, varname));");
    SqlStep(sql);
}

sqlquery SQLocals_PrepareSelect(object oObject, int nType, string sVarName)
{
    SQLocals_CreateTable();

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "SELECT value FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object AND type = @type AND varname = @varname;");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    return sql;
}

sqlquery SQLocals_PrepareInsert(object oObject, int nType, string sVarName)
{
    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "INSERT INTO " + SQLOCALS_TABLE_NAME + " " +
        "(object, type, varname, value, timestamp) VALUES (@object, @type, @varname, @value, strftime('%s','now')) " +
        "ON CONFLICT (object, type, varname) DO UPDATE SET value = @value, timestamp = strftime('%s','now');");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    return sql;
}

sqlquery SQLocals_PrepareDelete(object oObject, int nType, string sVarName)
{
    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "DELETE FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object AND type = @type AND varname = @varname;");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    return sql;
}

/* INT */
int SQLocals_GetInt(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return 0;

    sqlquery sql = SQLocals_PrepareSelect(oObject, SQLOCALS_TYPE_INT, sVarName);

    if (SqlStep(sql))
        return SqlGetInt(sql, 0);
    else
        return 0;
}

void SQLocals_SetInt(object oObject, string sVarName, int nValue)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareInsert(oObject, SQLOCALS_TYPE_INT, sVarName);
    SqlBindInt(sql, "@value", nValue);
    SqlStep(sql);
}

void SQLocals_DeleteInt(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareDelete(oObject, SQLOCALS_TYPE_INT, sVarName);
    SqlStep(sql);
}

/* FLOAT */
float SQLocals_GetFloat(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return 0.0f;

    sqlquery sql = SQLocals_PrepareSelect(oObject, SQLOCALS_TYPE_FLOAT, sVarName);

    if (SqlStep(sql))
        return SqlGetFloat(sql, 0);
    else
        return 0.0f;
}

void SQLocals_SetFloat(object oObject, string sVarName, float fValue)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareInsert(oObject, SQLOCALS_TYPE_FLOAT, sVarName);
    SqlBindFloat(sql, "@value", fValue);
    SqlStep(sql);
}

void SQLocals_DeleteFloat(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareDelete(oObject, SQLOCALS_TYPE_FLOAT, sVarName);
    SqlStep(sql);
}

/* STRING */
string SQLocals_GetString(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return "";

    sqlquery sql = SQLocals_PrepareSelect(oObject, SQLOCALS_TYPE_STRING, sVarName);

    if (SqlStep(sql))
        return SqlGetString(sql, 0);
    else
        return "";
}

void SQLocals_SetString(object oObject, string sVarName, string sValue)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareInsert(oObject, SQLOCALS_TYPE_STRING, sVarName);
    SqlBindString(sql, "@value", sValue);
    SqlStep(sql);
}

void SQLocals_DeleteString(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareDelete(oObject, SQLOCALS_TYPE_STRING, sVarName);
    SqlStep(sql);
}

/* OBJECT */
object SQLocals_GetObject(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return OBJECT_INVALID;

    sqlquery sql = SQLocals_PrepareSelect(oObject, SQLOCALS_TYPE_OBJECT, sVarName);

    if (SqlStep(sql))
        return StringToObject(SqlGetString(sql, 0));
    else
        return OBJECT_INVALID;
}

void SQLocals_SetObject(object oObject, string sVarName, object oValue)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareInsert(oObject, SQLOCALS_TYPE_OBJECT, sVarName);
    SqlBindString(sql, "@value", ObjectToString(oValue));
    SqlStep(sql);
}

void SQLocals_DeleteObject(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareDelete(oObject, SQLOCALS_TYPE_OBJECT, sVarName);
    SqlStep(sql);
}

/* VECTOR */
vector SQLocals_GetVector(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return [0.0f, 0.0f, 0.0f];

    sqlquery sql = SQLocals_PrepareSelect(oObject, SQLOCALS_TYPE_VECTOR, sVarName);

    if (SqlStep(sql))
        return SqlGetVector(sql, 0);
    else
        return [0.0f, 0.0f, 0.0f];
}

void SQLocals_SetVector(object oObject, string sVarName, vector vValue)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareInsert(oObject, SQLOCALS_TYPE_VECTOR, sVarName);
    SqlBindVector(sql, "@value", vValue);
    SqlStep(sql);
}

void SQLocals_DeleteVector(object oObject, string sVarName)
{
    if (oObject == OBJECT_INVALID || sVarName == "") return;

    sqlquery sql = SQLocals_PrepareDelete(oObject, SQLOCALS_TYPE_VECTOR, sVarName);
    SqlStep(sql);
}

/* UTILITY */
void SQLocals_Delete(object oObject, int nType = SQLOCALS_TYPE_ALL, string sLike = "", string sEscape = "")
{
    if (oObject == OBJECT_INVALID || nType < 0) return;

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "DELETE FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object " +
        (nType != SQLOCALS_TYPE_ALL ? "AND type & @type " : " ") +
        (sLike != "" ? "AND varname LIKE @like " + (sEscape != "" ? "ESCAPE @escape" : "") : "") +
        ";");

    SqlBindString(sql, "@object", ObjectToString(oObject));

    if (nType != SQLOCALS_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    if (sLike != "")
    {
        SqlBindString(sql, "@like", sLike);

        if (sEscape != "")
            SqlBindString(sql, "@escape", sEscape);
    }

    SqlStep(sql);
}

int SQLocals_Count(object oObject, int nType = SQLOCALS_TYPE_ALL, string sLike = "", string sEscape = "")
{
    if (oObject == OBJECT_INVALID || nType < 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "SELECT COUNT(*) FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object " +
        (nType != SQLOCALS_TYPE_ALL ? "AND type & @type " : " ") +
        (sLike != "" ? "AND varname LIKE @like " + (sEscape != "" ? "ESCAPE @escape" : "") : "") +
        ";");

    SqlBindString(sql, "@object", ObjectToString(oObject));

    if (nType != SQLOCALS_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    if (sLike != "")
    {
        SqlBindString(sql, "@like", sLike);

        if (sEscape != "")
            SqlBindString(sql, "@escape", sEscape);
    }

    if (SqlStep(sql))
        return SqlGetInt(sql, 0);
    else
        return 0;
}

int SQLocals_IsSet(object oObject, string sVarName, int nType)
{
    if (oObject == OBJECT_INVALID || nType < 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "SELECT * FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object " +
        (nType != SQLOCALS_TYPE_ALL ? "AND type & @type " : " ") +
        "AND varname = @varname;");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    if (nType != SQLOCALS_TYPE_ALL)
        SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    return SqlStep(sql);
}

int SQLocals_GetLastUpdated_UnixEpoch(object oObject, string sVarName, int nType)
{
    if (oObject == OBJECT_INVALID || nType <= 0) return 0;

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "SELECT timestamp FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object " +
        "AND type = @type " +
        "AND varname = @varname;");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    if (SqlStep(sql))
        return SqlGetInt(sql, 0);
    else
        return 0;
}

string SQLocals_GetLastUpdated_UTC(object oObject, string sVarName, int nType)
{
    if (oObject == OBJECT_INVALID || nType <= 0) return "";

    sqlquery sql = SqlPrepareQueryObject(GetModule(),
        "SELECT datetime(timestamp, 'unixepoch') FROM " + SQLOCALS_TABLE_NAME + " " +
        "WHERE object = @object " +
        "AND type = @type " +
        "AND varname = @varname;");

    SqlBindString(sql, "@object", ObjectToString(oObject));
    SqlBindInt(sql, "@type", nType);
    SqlBindString(sql, "@varname", sVarName);

    if (SqlStep(sql))
        return SqlGetString(sql, 0);
    else
        return "";
}

