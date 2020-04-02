/*
    ScriptName: es_s_persistloc.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player]

    Description: An EventSystem Subsystem that saves a player's location to
                 their .bic file when they log out and respawns them there
                 when the server is restarted.
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_elc"
#include "nwnx_player"

const string PERSISTENT_LOCATION_LOG_TAG        = "PersistentLocation";
const string PERSISTENT_LOCATION_SCRIPT_NAME    = "es_s_persistloc";

void PersistentLocation_SaveLocation(object oPlayer);
void PersistentLocation_LoadLocation(object oPlayer);

// @Load
void PersistentLocation_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_CLIENT_DISCONNECT_BEFORE");

    NWNX_ELC_EnableCustomELCCheck(TRUE);
    ELC_SubscribeEvent(sSubsystemScript);
}

// @EventHandler
void PersistentLocation_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_CLIENT_DISCONNECT_BEFORE")
        PersistentLocation_SaveLocation(OBJECT_SELF);
    else
    if (sEvent == ELC_EVENT)
        PersistentLocation_LoadLocation(OBJECT_SELF);
}

void PersistentLocation_SaveLocation(object oPlayer)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer) || GetIsDMPossessed(oPlayer)) return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;

    ES_Util_SetLocation(oPlayer, PERSISTENT_LOCATION_SCRIPT_NAME + "_Location", GetLocation(oPlayer), TRUE);
}

void PersistentLocation_LoadLocation(object oPlayer)
{
    if (NWNX_ELC_GetValidationFailureType() == NWNX_ELC_VALIDATION_FAILURE_TYPE_CUSTOM)
    {
        string sUUID = GetObjectUUID(oPlayer);
        object oDataObject = ES_Util_GetDataObject(PERSISTENT_LOCATION_SCRIPT_NAME);

        if (!ES_Util_GetInt(oDataObject, sUUID))
        {
            location locLocation = ES_Util_GetLocation(oPlayer, PERSISTENT_LOCATION_SCRIPT_NAME + "_Location");
            object oWaypoint = ES_Util_CreateWaypoint(locLocation, PERSISTENT_LOCATION_SCRIPT_NAME + sUUID);

            NWNX_Player_SetPersistentLocation(GetPCPublicCDKey(oPlayer), NWNX_Player_GetBicFileName(oPlayer), oWaypoint);

            ES_Util_SetInt(oDataObject, sUUID, TRUE);
        }

        NWNX_ELC_SkipValidationFailure();
    }
}


