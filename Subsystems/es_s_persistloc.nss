/*
    ScriptName: es_s_persistloc.nss
    Created by: Daz

    Description: A subsystem that saves a player's location to their .bic file when
                 they log out and respawns them there when the server is restarted.
*/

//void main() {}

#include "es_s_elc"
#include "nwnx_player"

const string PERSISTENT_LOCATION_SYSTEM_TAG = "PersistentLocation";

void PersistentLocation_SaveLocation(object oPlayer);
void PersistentLocation_LoadLocation(object oPlayer);

// @EventSystem_Init
void PersistentLocation_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_NWNX(sEventHandlerScript, "NWNX_ON_CLIENT_DISCONNECT_BEFORE");

    NWNX_ELC_EnableCustomELCCheck(TRUE);
    ELC_SubscribeEvent(sEventHandlerScript);
}

// @EventSystem_EventHandler
void PersistentLocation_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == "NWNX_ON_CLIENT_DISCONNECT_BEFORE")
        PersistentLocation_SaveLocation(OBJECT_SELF);
    else
    if (sEvent == ELC_EVENT)
        PersistentLocation_LoadLocation(OBJECT_SELF);
}

void PersistentLocation_SaveLocation(object oPlayer)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer)) return;

    string sLocation = ES_Util_LocationToString(GetLocation(oPlayer));

    NWNX_Object_SetPersistentString(oPlayer, PERSISTENT_LOCATION_SYSTEM_TAG, sLocation);
}

void PersistentLocation_LoadLocation(object oPlayer)
{
    if (NWNX_ELC_GetValidationFailureType() == NWNX_ELC_VALIDATION_FAILURE_TYPE_CUSTOM)
    {
        string sUUID = GetObjectUUID(oPlayer);
        object oDataObject = ES_Util_GetDataObject(PERSISTENT_LOCATION_SYSTEM_TAG);

        if (!GetLocalInt(oDataObject, sUUID))
        {
            location locLocation = ES_Util_StringToLocation(NWNX_Object_GetPersistentString(oPlayer, PERSISTENT_LOCATION_SYSTEM_TAG));
            object oWaypoint = ES_Util_CreateWaypoint(locLocation, PERSISTENT_LOCATION_SYSTEM_TAG + sUUID);

            if (GetIsObjectValid(GetArea(oWaypoint)))
            {
                NWNX_Player_SetPersistentLocation(GetPCPublicCDKey(oPlayer), NWNX_Player_GetBicFileName(oPlayer), oWaypoint);
            }

            SetLocalInt(oDataObject, sUUID, TRUE);
        }

        NWNX_ELC_SkipValidationFailure();
    }
}

