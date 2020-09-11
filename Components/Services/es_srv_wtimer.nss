/*
    ScriptName: es_srv_wtimer.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Service that exposes various world timer related events.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"

const string WORLD_TIMER_LOG_TAG                = "WorldTimer";
const string WORLD_TIMER_SCRIPT_NAME            = "es_srv_wtimer";

const string WORLD_TIMER_EVENT_1_MINUTE         = "WORLD_TIMER_EVENT_1_MINUTE";
const string WORLD_TIMER_EVENT_5_MINUTES        = "WORLD_TIMER_EVENT_5_MINUTES";
const string WORLD_TIMER_EVENT_10_MINUTES       = "WORLD_TIMER_EVENT_10_MINUTES";
const string WORLD_TIMER_EVENT_15_MINUTES       = "WORLD_TIMER_EVENT_15_MINUTES";
const string WORLD_TIMER_EVENT_30_MINUTES       = "WORLD_TIMER_EVENT_30_MINUTES";
const string WORLD_TIMER_EVENT_60_MINUTES       = "WORLD_TIMER_EVENT_60_MINUTES";

// Subscribe sEventHandlerScript to a WORLD_TIMER_EVENT_*
void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE);
// Unsubscribe sEventHandlerScript from a WORLD_TIMER_EVENT_*
void WorldTimer_UnsubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bClearDispatchList = TRUE);
// Get the current heartbeat count tick
int WorldTimer_GetHeartbeatCount();

// @Load
void WorldTimer_Load(string sServiceScript)
{
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_HEARTBEAT);
}

// @EventHandler
void WorldTimer_EventHandler(string sServiceScript, string sEvent)
{
    object oModule = OBJECT_SELF;
    object oDataObject = ES_Util_GetDataObject(sServiceScript);
    int nHeartbeatCount = GetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT");

    // Every 1 minute
    if (!(nHeartbeatCount % 10) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_1_MINUTE))
        Events_SignalEvent(WORLD_TIMER_EVENT_1_MINUTE, oModule);
    // Every 5 minutes
    if (!(nHeartbeatCount % (10 * 5)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_5_MINUTES))
        Events_SignalEvent(WORLD_TIMER_EVENT_5_MINUTES, oModule);
    // Every 10 minutes
    if (!(nHeartbeatCount % (10 * 10)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_10_MINUTES))
        Events_SignalEvent(WORLD_TIMER_EVENT_10_MINUTES, oModule);
    // Every 15 minutes
    if (!(nHeartbeatCount % (10 * 15)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_15_MINUTES))
       Events_SignalEvent(WORLD_TIMER_EVENT_15_MINUTES, oModule);
    // Every 30 minutes
    if (!(nHeartbeatCount % (10 * 30)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_30_MINUTES))
        Events_SignalEvent(WORLD_TIMER_EVENT_30_MINUTES, oModule);
    // Every 60 minutes
    if (!(nHeartbeatCount % (10 * 60)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_60_MINUTES))
        Events_SignalEvent(WORLD_TIMER_EVENT_60_MINUTES, oModule);

    SetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT", ++nHeartbeatCount);
}

void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE)
{
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    int nCurrentSubscribed = GetLocalInt(oDataObject, sWorldTimerEvent);

    SetLocalInt(oDataObject, sWorldTimerEvent, ++nCurrentSubscribed);

    Events_SubscribeEvent(sSubsystemScript, sWorldTimerEvent, bDispatchListMode);
}

void WorldTimer_UnsubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bClearDispatchList = TRUE)
{
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    int nCurrentSubscribed = GetLocalInt(oDataObject, sWorldTimerEvent);

    SetLocalInt(oDataObject, sWorldTimerEvent, --nCurrentSubscribed);

    Events_UnsubscribeEvent(sSubsystemScript, sWorldTimerEvent, bClearDispatchList);
}

int WorldTimer_GetHeartbeatCount()
{
    return GetLocalInt(ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME), "WORLD_TIMER_HEARTBEAT_COUNT");
}

