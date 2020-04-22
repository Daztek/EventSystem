/*
    ScriptName: es_prv_redis.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Redis]

    Description: An EventSystem Provider that manages Redis Database functionality
*/

#include "es_inc_core"

#include "nwnx_redis_short"

const string REDIS_LOG_TAG      = "Redis";
const string REDIS_SCRIPT_NAME  = "es_prv_redis";

// @Load
void Redis_Load(string sProviderScript)
{
    object oDataObject = ES_Util_GetDataObject(sProviderScript);
}

