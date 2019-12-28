/*
    ScriptName: es_s_persisthp.nss
    Created by: Daz

    Description: A subsystem that saves a player's hitpoints to their .bic file when
                 they log out and sets their hitpoints when they log back in.
*/

//void main() {}

#include "es_inc_core"

const string PERSISTENT_HITPOINTS_SYSTEM_TAG = "PersistentHitpoints";

void PersistentHitpoints_SaveHitpoints(object oPlayer);
void PersistentHitpoints_RestoreHitpoints(object oPlayer);

// @EventSystem_Init
void PersistentHitpoints_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_NWNX(sEventHandlerScript, "NWNX_ON_CLIENT_DISCONNECT_BEFORE");
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
}

// @EventSystem_EventHandler
void PersistentHitpoints_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == "NWNX_ON_CLIENT_DISCONNECT_BEFORE")
        PersistentHitpoints_SaveHitpoints(OBJECT_SELF);
    else
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER)
        PersistentHitpoints_RestoreHitpoints(GetEnteringObject());
}

void PersistentHitpoints_SaveHitpoints(object oPlayer)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer)) return;

    NWNX_Object_SetPersistentInt(oPlayer, PERSISTENT_HITPOINTS_SYSTEM_TAG, GetCurrentHitPoints(oPlayer));
}

void PersistentHitpoints_RestoreHitpoints(object oPlayer)
{
    if (GetIsDM(oPlayer)) return;

    int nSavedHitpoints = NWNX_Object_GetPersistentInt(oPlayer, PERSISTENT_HITPOINTS_SYSTEM_TAG);

    if (nSavedHitpoints > 0)
       NWNX_Object_SetCurrentHitPoints(oPlayer, nSavedHitpoints);
    else
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
}

