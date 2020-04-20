/*
    ScriptName: es_srv_wtimer.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Service that exposes various world timer related events.
*/

//void main() {}

#include "es_inc_core"

const string WORLD_TIMER_LOG_TAG                = "WorldTimer";
const string WORLD_TIMER_SCRIPT_NAME            = "es_srv_wtimer";

const string WORLD_TIMER_EVENT_DAWN             = "WORLD_TIMER_EVENT_DAWN";
const string WORLD_TIMER_EVENT_DUSK             = "WORLD_TIMER_EVENT_DUSK";
const string WORLD_TIMER_EVENT_IN_GAME_HOUR     = "WORLD_TIMER_EVENT_IN_GAME_HOUR";

const string WORLD_TIMER_EVENT_1_MINUTE         = "WORLD_TIMER_EVENT_1_MINUTE";
const string WORLD_TIMER_EVENT_5_MINUTES        = "WORLD_TIMER_EVENT_5_MINUTES";
const string WORLD_TIMER_EVENT_10_MINUTES       = "WORLD_TIMER_EVENT_10_MINUTES";
const string WORLD_TIMER_EVENT_15_MINUTES       = "WORLD_TIMER_EVENT_15_MINUTES";
const string WORLD_TIMER_EVENT_30_MINUTES       = "WORLD_TIMER_EVENT_30_MINUTES";
const string WORLD_TIMER_EVENT_60_MINUTES       = "WORLD_TIMER_EVENT_60_MINUTES";

// Subscribe sEventHandlerScript to a WORLD_TIMER_EVENT_*
void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE);
// Get the current heartbeat count tick
int WorldTimer_GetHeartbeatCount();

// @Load
void WorldTimer_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    SetLocalInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR", NWNX_Util_GetMinutesPerHour());
    ES_Core_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_HEARTBEAT);
}

// @EventHandler
void WorldTimer_EventHandler(string sServiceScript, string sEvent)
{
    object oModule = OBJECT_SELF;
    object oDataObject = ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME);
    int nModuleMinutesPerHour = GetLocalInt(oDataObject, "WORLD_TIMER_MINUTES_PER_HOUR");
    int nHeartbeatCount = GetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT");

    // Every 1 minute
    if (!(nHeartbeatCount % 10) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_1_MINUTE))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_1_MINUTE, oModule);
    // Every 5 minutes
    if (!(nHeartbeatCount % (10 * 5)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_5_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_5_MINUTES, oModule);
    // Every 10 minutes
    if (!(nHeartbeatCount % (10 * 10)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_10_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_10_MINUTES, oModule);
    // Every 15 minutes
    if (!(nHeartbeatCount % (10 * 15)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_15_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_15_MINUTES, oModule);
    // Every 30 minutes
    if (!(nHeartbeatCount % (10 * 30)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_30_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_30_MINUTES, oModule);
    // Every 60 minutes
    if (!(nHeartbeatCount % (10 * 60)) && GetLocalInt(oDataObject, WORLD_TIMER_EVENT_60_MINUTES))
        NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_60_MINUTES, oModule);

    // Every ingame hour
    if (!(nHeartbeatCount % (10 * nModuleMinutesPerHour)))
    {
        if (GetLocalInt(oDataObject, WORLD_TIMER_EVENT_IN_GAME_HOUR))
            NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_IN_GAME_HOUR, oModule);

        if (GetIsDawn())
        {
            if (GetLocalInt(oDataObject, WORLD_TIMER_EVENT_DAWN))
                NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DAWN, oModule);
        }

        if (GetIsDusk())
        {
            if (GetLocalInt(oDataObject, WORLD_TIMER_EVENT_DUSK))
                NWNX_Events_SignalEvent(WORLD_TIMER_EVENT_DUSK, oModule);
        }
    }

    SetLocalInt(oDataObject, "WORLD_TIMER_HEARTBEAT_COUNT", ++nHeartbeatCount);
}

void WorldTimer_SubscribeEvent(string sSubsystemScript, string sWorldTimerEvent, int bDispatchListMode = FALSE)
{
    SetLocalInt(ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME), sWorldTimerEvent, TRUE);
    ES_Core_SubscribeEvent(sSubsystemScript, sWorldTimerEvent, bDispatchListMode);
}

int WorldTimer_GetHeartbeatCount()
{
    return GetLocalInt(ES_Util_GetDataObject(WORLD_TIMER_SCRIPT_NAME), "WORLD_TIMER_HEARTBEAT_COUNT");
}

