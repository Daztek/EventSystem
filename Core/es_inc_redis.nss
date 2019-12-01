/*
    ScriptName: es_inc_redis.nss
    Created by: Daz

    Description: Event System - Redis Wrapper Include
*/

#include "es_inc_util"
#include "nwnx_redis_short"

string ES_Redis_GetHash(object oPlayer, string sSystem);
void ES_Redis_DeleteHash(string sHash);
int ES_Redis_GetHashExists(string sHash);

void ES_Redis_SetString(string sHash, string sVarName, string sValue);
string ES_Redis_GetString(string sHash, string sVarName);
void ES_Redis_DeleteString(string sHash, string sVarName);
void ES_Redis_SetInt(string sHash, string sVarName, int nValue);
int ES_Redis_GetInt(string sHash, string sVarName);
void ES_Redis_DeleteInt(string sHash, string sVarName);
void ES_Redis_SetFloat(string sHash, string sVarName, float fValue);
float ES_Redis_GetFloat(string sHash, string sVarName);
void ES_Redis_DeleteFloat(string sHash, string sVarName);
void ES_Redis_SetLocation(string sHash, string sVarName, location locValue);
location ES_Redis_GetLocation(string sHash, string sVarName);
void ES_Redis_DeleteLocation(string sHash, string sVarName);

string ES_Redis_GetHash(object oPlayer, string sSystem)
{
    return GetModuleName() + ":" + sSystem + ":" + GetObjectUUID(oPlayer);
}

void ES_Redis_DeleteHash(string sHash)
{
    DEL(sHash);
}

int ES_Redis_GetHashExists(string sHash)
{
    return NWNX_Redis_GetResultAsInt(EXISTS(sHash));
}


void ES_Redis_SetString(string sHash, string sVarName, string sValue)
{
    HSET(sHash, "S:" + sVarName, sValue);
}

string ES_Redis_GetString(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsString(HGET(sHash, "S:" + sVarName));
}

void ES_Redis_DeleteString(string sHash, string sVarName)
{
    HDEL(sHash, "S:" + sVarName);
}

void ES_Redis_SetInt(string sHash, string sVarName, int nValue)
{
    HSET(sHash, "I:" + sVarName, IntToString(nValue));
}

int ES_Redis_GetInt(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsInt(HGET(sHash, "I:" + sVarName));
}

void ES_Redis_DeleteInt(string sHash, string sVarName)
{
    HDEL(sHash, "I:" + sVarName);
}

void ES_Redis_SetFloat(string sHash, string sVarName, float fValue)
{
    HSET(sHash, "F:" + sVarName, FloatToString(fValue));
}

float ES_Redis_GetFloat(string sHash, string sVarName)
{
    return NWNX_Redis_GetResultAsFloat(HGET(sHash, "F:" + sVarName));
}

void ES_Redis_DeleteFloat(string sHash, string sVarName)
{
    HDEL(sHash, "F:" + sVarName);
}

void ES_Redis_SetLocation(string sHash, string sVarName, location locValue)
{
    HSET(sHash, "L:" + sVarName, ES_Util_LocationToString(locValue));
}

location ES_Redis_GetLocation(string sHash, string sVarName)
{
    return ES_Util_StringToLocation(NWNX_Redis_GetResultAsString(HGET(sHash, "L:" + sVarName)));
}

void ES_Redis_DeleteLocation(string sHash, string sVarName)
{
    HDEL(sHash, "L:" + sVarName);
}

