/*
    ScriptName: es_s_playerdb.nss
    Created by: Daz

    Description: A simple persistent world player database subsystem using Redis
*/

//void main() {}

#include "es_s_worldtimer"
#include "es_inc_redis"
#include "es_s_elc"
#include "nwnx_player"

const string PLAYERDB_SYSTEM_TAG                = "PlayerDatabase";

void PlayerDB_ClientEnter(object oPlayer);
void PlayerDB_ClientExit(object oPlayer);
void PlayerDB_LoadPersistentLocation(object oPlayer);
void PlayerDB_SaveCharacters();
void PlayerDB_ModuleShutdown();

// @EventSystem_Init
void PlayerDB_Init(string sEventHandlerScript)
{
    NWNX_ELC_EnableCustomELCCheck(TRUE);

    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER, ES_CORE_EVENT_FLAG_BEFORE);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT, ES_CORE_EVENT_FLAG_AFTER);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN, ES_CORE_EVENT_FLAG_AFTER);

    WorldTimer_SubscribeEvent(sEventHandlerScript, WORLD_TIMER_EVENT_5_MINUTES);
    ELC_SubscribeEvent(sEventHandlerScript);
}

// @EventSystem_EventHandler
void PlayerDB_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == WORLD_TIMER_EVENT_5_MINUTES)
    {
        PlayerDB_SaveCharacters();
    }
    else
    if (sEvent == ELC_EVENT)
    {
        PlayerDB_LoadPersistentLocation(OBJECT_SELF);
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
            {
                PlayerDB_ClientEnter(GetEnteringObject());
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                PlayerDB_ClientExit(GetExitingObject());
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN:
            {
                PlayerDB_ModuleShutdown();
                break;
            }
        }
    }
}

void PlayerDB_ClientEnter(object oPlayer)
{
    string sPlayerHash = ES_Redis_GetHash(oPlayer, PLAYERDB_SYSTEM_TAG);

    if (!ES_Redis_GetHashExists(sPlayerHash))
    {
        string sUUID = GetObjectUUID(oPlayer);

        SetTag(oPlayer, sUUID);

        ES_Redis_SetString(sPlayerHash, "UUID", sUUID);
        ES_Redis_SetString(sPlayerHash, "CharacterName", GetName(oPlayer));
        ES_Redis_SetString(sPlayerHash, "PlayerName", GetPCPlayerName(oPlayer));
        ES_Redis_SetString(sPlayerHash, "CDKey", GetPCPublicCDKey(oPlayer));
        ES_Redis_SetString(sPlayerHash, "BicFileName", NWNX_Player_GetBicFileName(oPlayer));
        ES_Redis_SetLocation(sPlayerHash, "Location", GetStartingLocation());

        SetLocalInt(ES_Util_GetDataObject(PLAYERDB_SYSTEM_TAG + "_PersistentLocations"), sPlayerHash, TRUE);
    }
    else
    {
        if (ES_Redis_GetInt(sPlayerHash, "Dead"))
        {
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
        }
    }
}

void PlayerDB_ClientExit(object oPlayer)
{
    string sPlayerHash = ES_Redis_GetHash(oPlayer, PLAYERDB_SYSTEM_TAG);

    ES_Redis_SetLocation(sPlayerHash, "Location", GetLocation(oPlayer));
    ES_Redis_SetInt(sPlayerHash, "Dead", GetIsDead(oPlayer));
}

void PlayerDB_LoadPersistentLocation(object oPlayer)
{
    if (NWNX_ELC_GetValidationFailureType() == NWNX_ELC_VALIDATION_FAILURE_TYPE_CUSTOM)
    {
        string sPlayerHash = ES_Redis_GetHash(oPlayer, PLAYERDB_SYSTEM_TAG);

        if (ES_Redis_GetHashExists(sPlayerHash))
        {
            object oDataObject = ES_Util_GetDataObject(PLAYERDB_SYSTEM_TAG + "_PersistentLocations");

            if (!GetLocalInt(oDataObject, sPlayerHash))
            {
                location locLocation = ES_Redis_GetLocation(sPlayerHash, "Location");

                object oWaypoint = CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation);

                if (GetIsObjectValid(GetArea(oWaypoint)))
                {
                    NWNX_Player_SetPersistentLocation(GetPCPublicCDKey(oPlayer), NWNX_Player_GetBicFileName(oPlayer), oWaypoint);
                }

                SetLocalInt(oDataObject, sPlayerHash, TRUE);
            }
        }

        NWNX_ELC_SkipValidationFailure();
    }
}

void PlayerDB_SaveCharacters()
{
    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        if (GetIsDM(oPlayer))
            continue;

        SendMessageToPC(oPlayer, "Saving your character...");

        ExportSingleCharacter(oPlayer);

        oPlayer = GetNextPC();
    }
}

void PlayerDB_ModuleShutdown()
{
    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        PlayerDB_ClientExit(oPlayer);

        oPlayer = GetNextPC();
    }
}

