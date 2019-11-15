/*
    ScriptName: es_s_worldtimer.nss
    Created by: Daz

    Description: A subsystem that exposes various world timer related events.
*/

//void main() {}

#include "es_inc_core"

const string WORLD_TIMER_EVENT_DAWN             = "WORLD_TIMER_EVENT_DAWN";
const string WORLD_TIMER_EVENT_DUSK             = "WORLD_TIMER_EVENT_DUSK";
const string WORLD_TIMER_EVENT_IN_GAME_HOUR     = "WORLD_TIMER_EVENT_IN_GAME_HOUR";

const string WORLD_TIMER_EVENT_1_MINUTE         = "WORLD_TIMER_EVENT_1_MINUTE";
const string WORLD_TIMER_EVENT_5_MINUTES        = "WORLD_TIMER_EVENT_5_MINUTES";
const string WORLD_TIMER_EVENT_10_MINUTES       = "WORLD_TIMER_EVENT_10_MINUTES";
const string WORLD_TIMER_EVENT_15_MINUTES       = "WORLD_TIMER_EVENT_15_MINUTES";
const string WORLD_TIMER_EVENT_30_MINUTES       = "WORLD_TIMER_EVENT_30_MINUTES";
const string WORLD_TIMER_EVENT_60_MINUTES       = "WORLD_TIMER_EVENT_60_MINUTES";

// @EventSystem_Init
void InitWorldTimer(string sEventHandlerScript);
// @EventSystem_EventHandler
void WorldTimerEventHandler(string sEventHandlerScript, string sEvent);

// Subscribe sEventHandlerScript to a WORLD_TIMER_EVENT_*
void SubscribeToWorldTimerEvent(string sEventHandlerScript, string sWorldTimerEvent, int bDispatchListMode = FALSE);

void InitWorldTimer(string sEventHandlerScript)
{
    object oDataObject = ES_Util_GetDataObject(sEventHandlerScript);
    SetLocalInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR", NWNX_Util_GetMinutesPerHour());
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_HEARTBEAT);
}

void WorldTimerEventHandler(string sEventHandlerScript, string sEvent)
{
    object oDataObject = ES_Util_GetDataObject(sEventHandlerScript);
    int nModuleMinutesPerHour = GetLocalInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR");
    int nHeartbeatCount = GetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT");

    // Every 1 minute
    if (!(nHeartbeatCount % 10))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_1_MINUTE, OBJECT_SELF);
    // Every 5 minutes
    if (!(nHeartbeatCount % (10 * 5)))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_5_MINUTES, OBJECT_SELF);
    // Every 10 minutes
    if (!(nHeartbeatCount % (10 * 10)))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_10_MINUTES, OBJECT_SELF);
    // Every 15 minutes
    if (!(nHeartbeatCount % (10 * 15)))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_15_MINUTES, OBJECT_SELF);
    // Every 30 minutes
    if (!(nHeartbeatCount % (10 * 30)))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_30_MINUTES, OBJECT_SELF);
    // Every 60 minutes
    if (!(nHeartbeatCount % (10 * 60)))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_60_MINUTES, OBJECT_SELF);

    // Every ingame hour
    if (!(nHeartbeatCount % (10 * nModuleMinutesPerHour)))
    {
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_IN_GAME_HOUR, OBJECT_SELF);

        if (GetIsDawn() && !GetLocalInt(oDataObject, WORLD_TIMER_EVENT_DAWN))
        {
            NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DAWN, OBJECT_SELF);

            SetLocalInt(oDataObject, WORLD_TIMER_EVENT_DAWN, TRUE);
            SetLocalInt(oDataObject, WORLD_TIMER_EVENT_DUSK, FALSE);
        }

        if (GetIsDusk() && !GetLocalInt(oDataObject, WORLD_TIMER_EVENT_DUSK))
        {
            NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DUSK, OBJECT_SELF);

            SetLocalInt(oDataObject, WORLD_TIMER_EVENT_DUSK, TRUE);
            SetLocalInt(oDataObject, WORLD_TIMER_EVENT_DAWN, FALSE);
        }
    }

    SetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT", ++nHeartbeatCount);
}

void SubscribeToWorldTimerEvent(string sEventHandlerScript, string sWorldTimerEvent, int bDispatchListMode = FALSE)
{
    NWNX_Events_SubscribeEvent(sWorldTimerEvent, sEventHandlerScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sWorldTimerEvent, sEventHandlerScript, bDispatchListMode);
}

