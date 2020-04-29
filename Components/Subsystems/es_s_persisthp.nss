/*
    ScriptName: es_s_persisthp.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Object]

    Description: An EventSystem Subsystem that saves a player's hitpoints to
                 their .bic file when they log out and sets their hitpoints
                 when they log back in.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_pos"

const string PERSISTENT_HITPOINTS_LOG_TAG       = "PersistentHitPoints";
const string PERSISTENT_HITPOINTS_SCRIPT_NAME   = "es_s_persisthp";

void PersistentHitPoints_SaveHitPoints(object oPlayer);
void PersistentHitPoints_RestoreHitPoints(object oPlayer);

// @Load
void PersistentHitPoints_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_CLIENT_DISCONNECT_BEFORE");
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
}

// @EventHandler
void PersistentHitPoints_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_CLIENT_DISCONNECT_BEFORE")
        PersistentHitPoints_SaveHitPoints(OBJECT_SELF);
    else
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER)
        PersistentHitPoints_RestoreHitPoints(GetEnteringObject());
}

void PersistentHitPoints_SaveHitPoints(object oPlayer)
{
    if (!GetIsObjectValid(oPlayer) || GetIsDM(oPlayer) || GetIsDMPossessed(oPlayer)) return;

    object oMaster = GetMaster(oPlayer);
    if (GetIsObjectValid(oMaster)) oPlayer = oMaster;

    POS_SetInt(oPlayer, PERSISTENT_HITPOINTS_SCRIPT_NAME + "_Dead", GetIsDead(oPlayer), TRUE);
    POS_SetInt(oPlayer, PERSISTENT_HITPOINTS_SCRIPT_NAME + "_HP", GetCurrentHitPoints(oPlayer), TRUE);
}

void PersistentHitPoints_RestoreHitPoints(object oPlayer)
{
    if (GetIsDM(oPlayer)) return;

    int bDead = POS_GetInt(oPlayer, PERSISTENT_HITPOINTS_SCRIPT_NAME + "_Dead");

    if (bDead)
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
    else
    {
        int nHitPoints = POS_GetInt(oPlayer, PERSISTENT_HITPOINTS_SCRIPT_NAME + "_HP");
        int nMaxHitPoints = GetMaxHitPoints(oPlayer);

        if (nHitPoints > 0 && nHitPoints < nMaxHitPoints)
           NWNX_Object_SetCurrentHitPoints(oPlayer, nHitPoints);
    }
}

