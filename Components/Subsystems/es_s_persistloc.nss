/*
    ScriptName: es_s_persistloc.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[ELC Player]

    Description: An EventSystem Subsystem that saves a player's location to
                 their .bic file when they log out and respawns them there
                 when the server is restarted.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_pos"
#include "nwnx_player"

const string PERSISTENT_LOCATION_LOG_TAG        = "PersistentLocation";
const string PERSISTENT_LOCATION_SCRIPT_NAME    = "es_s_persistloc";

void PersistentLocation_SaveLocation(object oPlayer);
void PersistentLocation_LoadLocation(object oPlayer);

// @Load
void PersistentLocation_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_CLIENT_DISCONNECT_BEFORE");
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_ELC_VALIDATE_CHARACTER_AFTER");
}

// @EventHandler
void PersistentLocation_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_CLIENT_DISCONNECT_BEFORE")
        PersistentLocation_SaveLocation(OBJECT_SELF);
    else
    if (sEvent == "NWNX_ON_ELC_VALIDATE_CHARACTER_AFTER")
        PersistentLocation_LoadLocation(OBJECT_SELF);
}

void PersistentLocation_SaveLocation(object oPlayer)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer) || GetIsDMPossessed(oPlayer)) return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;

    POS_SetLocation(oPlayer, PERSISTENT_LOCATION_SCRIPT_NAME + "_Location", GetLocation(oPlayer), TRUE);
}

void PersistentLocation_LoadLocation(object oPlayer)
{
    string sUUID = GetObjectUUID(oPlayer);
    object oDataObject = ES_Util_GetDataObject(PERSISTENT_LOCATION_SCRIPT_NAME);

    if (!GetLocalInt(oDataObject, sUUID))
    {
        location locLocation = POS_GetLocation(oPlayer, PERSISTENT_LOCATION_SCRIPT_NAME + "_Location");
        //object oWaypoint = ES_Util_CreateWaypoint(locLocation, PERSISTENT_LOCATION_SCRIPT_NAME + sUUID);

        //NWNX_Player_SetPersistentLocation(GetPCPublicCDKey(oPlayer), NWNX_Player_GetBicFileName(oPlayer), oWaypoint);
        NWNX_Player_SetSpawnLocation(oPlayer, locLocation);

        SetLocalInt(oDataObject, sUUID, TRUE);
    }
}


