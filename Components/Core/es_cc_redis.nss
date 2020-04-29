/*
    ScriptName: es_cc_redis.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Redis]

    Description: An EventSystem Core Component that manages Redis Database functionality
*/

#include "es_inc_core"
#include "nwnx_redis_short"

const string REDIS_LOG_TAG      = "Redis";
const string REDIS_SCRIPT_NAME  = "es_cc_redis";

string Redis_GetHash(object oPlayer, string sSystem);
void Redis_DeleteHash(string sHash);
int Redis_GetHashExists(string sHash);

void Redis_SetString(string sHash, string sVarName, string sValue);
string Redis_GetString(string sHash, string sVarName);
void Redis_DeleteString(string sHash, string sVarName);

void Redis_SetInt(string sHash, string sVarName, int nValue);
int Redis_GetInt(string sHash, string sVarName);
void Redis_DeleteInt(string sHash, string sVarName);

void Redis_SetFloat(string sHash, string sVarName, float fValue);
float Redis_GetFloat(string sHash, string sVarName);
void Redis_DeleteFloat(string sHash, string sVarName);

void Redis_SetLocation(string sHash, string sVarName, location locValue);
location Redis_GetLocation(string sHash, string sVarName);
void Redis_DeleteLocation(string sHash, string sVarName);

void Redis_SetVector(string sHash, string sVarName, vector vValue);
vector Redis_GetVector(string sHash, string sVarName);
void Redis_DeleteVector(string sHash, string sVarName);

string Redis_GetHash(object oPlayer, string sSystem)
{
    return GetModuleName() + ":" + sSystem + ":" + GetObjectUUID(oPlayer);
}

void Redis_DeleteHash(string sHash)
{
    DEL(sHash);
}

int Redis_GetHashExists(string sHash)
{
    return NWNX_Redis_GetResultAsInt(EXISTS(sHash));
}


void Redis_SetString(string sHash, string sVarName, string sValue)
{
    HSET(sHash, "S:" + sVarName, sValue);
}

string Redis_GetString(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsString(HGET(sHash, "S:" + sVarName));
}

void Redis_DeleteString(string sHash, string sVarName)
{
    HDEL(sHash, "S:" + sVarName);
}

void Redis_SetInt(string sHash, string sVarName, int nValue)
{
    HSET(sHash, "I:" + sVarName, IntToString(nValue));
}

int Redis_GetInt(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsInt(HGET(sHash, "I:" + sVarName));
}

void Redis_DeleteInt(string sHash, string sVarName)
{
    HDEL(sHash, "I:" + sVarName);
}

void Redis_SetFloat(string sHash, string sVarName, float fValue)
{
    HSET(sHash, "F:" + sVarName, FloatToString(fValue));
}

float Redis_GetFloat(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsFloat(HGET(sHash, "F:" + sVarName));
}

void Redis_DeleteFloat(string sHash, string sVarName)
{
    HDEL(sHash, "F:" + sVarName);
}

void Redis_SetLocation(string sHash, string sVarName, location locValue)
{
    HSET(sHash, "L:" + sVarName, ES_Util_LocationToString(locValue));
}

location Redis_GetLocation(string sHash, string sVarName)
{
    return ES_Util_StringToLocation(NWNX_Redis_GetResultAsString(HGET(sHash, "L:" + sVarName)));
}

void Redis_DeleteLocation(string sHash, string sVarName)
{
    HDEL(sHash, "L:" + sVarName);
}

void Redis_SetVector(string sHash, string sVarName, vector vValue)
{
    HSET(sHash, "V:" + sVarName, ES_Util_VectorToString(vValue));
}

vector Redis_GetVector(string sHash, string sVarName)
{
    return ES_Util_StringToVector(NWNX_Redis_GetResultAsString(HGET(sHash, "V:" + sVarName)));
}

void Redis_DeleteVector(string sHash, string sVarName)
{
    HDEL(sHash, "V:" + sVarName);
}

