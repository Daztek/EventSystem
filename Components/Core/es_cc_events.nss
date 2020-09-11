/*
    ScriptName: es_cc_events.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Events Object]

    Description: An EventSystem Core Component that allows Services
                 and Subsystems to subscribe to events
*/

#include "es_inc_core"
#include "es_cc_profiler"
#include "nwnx_events"
#include "nwnx_object"

//void main(){}

const string EVENTS_LOG_TAG                         = "Events";
const string EVENTS_SCRIPT_NAME                     = "es_cc_events";

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN    = 3019;
const string EVENTS_SCRIPT_PREFIX                   = "es_obj_e_";

const int EVENTS_EVENT_TYPE_CUSTOM                  = 0;
const int EVENTS_EVENT_TYPE_OBJECT                  = 1;
const int EVENTS_EVENT_TYPE_NWNX                    = 2;

const int EVENTS_EVENT_FLAG_BEFORE                  = 1;
const int EVENTS_EVENT_FLAG_DEFAULT                 = 2;
const int EVENTS_EVENT_FLAG_AFTER                   = 4;

// INTERNAL FUNCTION
void Events_CheckObjectEventScripts(int nStart, int nEnd);
// INTERNAL FUNCTION: Subscribe sScript to sEvent.
// You probably want one of these instead:
//  - Events_SubscribeEvent_Object()
//  - Events_SubscribeEvent_NWNX();
void Events_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode, int nEventType = EVENTS_EVENT_TYPE_CUSTOM, int nFlag = 0);

// Set oObject's nEvent script to the EventSystem's event script
//
// nEvent: An EVENT_SCRIPT_* constant
// bStoreOldEvent: If TRUE, the existing script will be stored and called before the _DEFAULT event.
void Events_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
// Wrapper for Events_SetObjectEventScript() to set all event scripts for an area
void Events_SetAreaEventScripts(object oArea, int bStoreOldEvent = TRUE);
// Wrapper for Events_SetObjectEventScript() to set all event scripts for a creature
void Events_SetCreatureEventScripts(object oCreature, int bStoreOldEvent = TRUE);
// Set all event scripts of oCreature to ""
void Events_ClearCreatureEventScripts(object oCreature);
// Get an ES_CORE_EVENT_FLAG_* from an object event
int Events_GetEventFlagFromEvent(string sEvent);
// Convenience function to construct an object event
//
// If nEvent = EVENT_SCRIPT_MODULE_ON_MODULE_LOAD and nEventFlag = EVENTS_EVENT_FLAG_AFTER -> Return = 3002_OBJEVT_4
string Events_GetEventName_Object(int nEvent, int nEventFlag = EVENTS_EVENT_FLAG_DEFAULT);
// Skips execution of the currently executing event.
void Events_SkipEvent();
// Subscribe to an object event, generally called in a component's load function.
//
// sComponentScript:
// nEvent: An EVENT_SCRIPT_* constant
// nEventFlags: One or more EVENTS_EVENT_FLAG_* constants
//              For example, to subscribe to both the _BEFORE and _AFTER event you'd do the following:
//              Events_SubscribeEvent_Object(sEventHandlerScript, nEvent, EVENTS_EVENT_FLAG_BEFORE | EVENTS_EVENT_FLAG_AFTER);
// bDispatchListMode: Convenience option to toggle DispatchListMode for the event
void Events_SubscribeEvent_Object(string sComponentScript, int nEvent, int nEventFlags = EVENTS_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE);
// Convenience function to subscribe to a NWNX event
void Events_SubscribeEvent_NWNX(string sComponentScript, string sNWNXEvent, int bDispatchListMode = FALSE);
// Unsubscribe sComponentScript from sEvent
void Events_UnsubscribeEvent(string sComponentScript, string sEvent, int bClearDispatchList = FALSE);
// Unsubscribe sComponentScript from all its subscribed events
void Events_UnsubscribeAllEvents(string sComponentScript, int bClearDispatchLists = FALSE);
// Wrapper for NWNX_Events_PushEventData()
void Events_PushEventData(string sTag, string sData);
// Wrapper for NWNX_Events_SignalEvent()
int Events_SignalEvent(string sEvent, object oTarget);
// Add oObject to sComponentScript's dispatch list for sEvent
void Events_AddObjectToDispatchList(string sComponentScript, string sEvent, object oObject);
// Remove oObject from sComponentScript's dispatch list for sEvent
void Events_RemoveObjectFromDispatchList(string sComponentScript, string sEvent, object oObject);
// Add oObject to the dispatch lists of all dispatchmode events sComponentScript is subscribed to
void Events_AddObjectToAllDispatchLists(string sComponentScript, object oObject);
// Remove oObject from the dispatch lists of all dispatchmode events sComponentScript is subscribed to
void Events_RemoveObjectFromAllDispatchLists(string sComponentScript, object oObject);

// NWNX_Events_GetEventData() string data wrapper
string Events_GetEventData_NWNX_String(string sTag);
// NWNX_Events_GetEventData() int data wrapper
int Events_GetEventData_NWNX_Int(string sTag);
// NWNX_Events_GetEventData() float data wrapper
float Events_GetEventData_NWNX_Float(string sTag);
// NWNX_Events_GetEventData() object data wrapper
object Events_GetEventData_NWNX_Object(string sTag);
// NWNX_Events_GetEventData() vector data wrapper
vector Events_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ);
// NWNX_Events_GetEventData() location data wrapper
location Events_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ);

// Wrapper function for EnterTargetingMode()
// Make oPlayer enter a targeting mode named sTargetingMode
void Events_EnterTargetingMode(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC);
// Get the current targeting mode of oPlayer
string Events_GetCurrentTargetingMode(object oPlayer);

// @Load
void Events_Load(string sCoreComponentScript)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + EVENTS_SCRIPT_NAME + " (" +
                    "component TEXT NOT NULL, " +
                    "event TEXT NOT NULL, " +
                    "flag INTEGER NOT NULL, " +
                    "type INTEGER NOT NULL, " +
                    "dispatchmode INTEGER NOT NULL, " +
                    "PRIMARY KEY(component, event));";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlStep(sql);

    ES_Util_Log(EVENTS_LOG_TAG, "* Checking Object Event Scripts");

    // Check if all the object event script exist and (re)compile them if needed
    Events_CheckObjectEventScripts(EVENT_SCRIPT_MODULE_ON_HEARTBEAT, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENT_SCRIPT_AREA_ON_EXIT);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, EVENT_SCRIPT_TRIGGER_ON_CLICKED);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_PLACEABLE_ON_CLOSED, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_DOOR_ON_OPEN, EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER, EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT);
    Events_CheckObjectEventScripts(EVENT_SCRIPT_STORE_ON_OPEN, EVENT_SCRIPT_STORE_ON_CLOSE);

    ES_Util_Log(EVENTS_LOG_TAG, "* Hooking Module Event Scripts");
    // Set all module event script to the EventSystem event scripts
    object oModule = GetModule();
    int nEvent;
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET; nEvent++)
    {
        Events_SetObjectEventScript(oModule, nEvent);
    }

    ES_Util_Log(EVENTS_LOG_TAG, "* Hooking Area Event Scripts");
    // Set all area event script to the EventSystem event scripts
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        Events_SetAreaEventScripts(oArea);

        oArea = GetNextArea();
    }
}

// @Test
void Events_Test(string sCoreComponentScript)
{
    string sShutdownScriptName = EVENTS_SCRIPT_PREFIX + IntToString(EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN);
    int bTest = NWNX_Util_GetEnvironmentVariable("NWNX_CORE_SHUTDOWN_SCRIPT") == sShutdownScriptName;
    Test_Warn("NWNX environment variable 'NWNX_CORE_SHUTDOWN_SCRIPT' is set to: " + sShutdownScriptName, bTest);
}

// *** INTERNAL FUNCTIONS
void Events_CheckObjectEventScripts(int nStart, int nEnd)
{
    int bHashChanged = ES_Core_GetComponentHashChanged(EVENTS_SCRIPT_NAME), nEvent;

    for (nEvent = nStart; nEvent <= nEnd; nEvent++)
    {
        string sScriptName = EVENTS_SCRIPT_PREFIX + IntToString(nEvent);
        int bObjectEventScriptExists = NWNX_Util_IsValidResRef(sScriptName, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bHashChanged || !bObjectEventScriptExists)
        {
            ES_Util_AddScript(sScriptName, EVENTS_SCRIPT_NAME, nssFunction("Events_SignalObjectEvent", IntToString(nEvent)));
        }
    }
}

void Events_SignalObjectEvent(int nEvent, object oTarget = OBJECT_SELF)
{
    string sEventID = IntToString(nEvent);
    string sEvent = sEventID + "_OBJEVT_";
    string sQuery = "SELECT " +
                        "SUM(CASE WHEN flag=" + IntToString(EVENTS_EVENT_FLAG_BEFORE) + " THEN 1 ELSE 0 END), " +
                        "SUM(CASE WHEN flag=" + IntToString(EVENTS_EVENT_FLAG_DEFAULT) + " THEN 1 ELSE 0 END), " +
                        "SUM(CASE WHEN flag=" + IntToString(EVENTS_EVENT_FLAG_AFTER) + " THEN 1 ELSE 0 END) " +
                    "FROM " + EVENTS_SCRIPT_NAME + " WHERE event LIKE @like;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@like", sEvent + "%");
    int bResult = SqlStep(sql);

    if (bResult && SqlGetInt(sql, 0))
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_BEFORE), oTarget);

    // Run any stored event scripts
    string sScript = GetLocalString(oTarget, EVENTS_SCRIPT_NAME + "_OldEventScript!" + sEventID);
    if (sScript != "") ExecuteScript(sScript, oTarget);

    if (bResult && SqlGetInt(sql, 1))
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_DEFAULT), oTarget);

    if (bResult && SqlGetInt(sql, 2))
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_AFTER), oTarget);
}

void Events_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode, int nEventType = EVENTS_EVENT_TYPE_CUSTOM, int nFlag = 0)
{
    string sQuery = "REPLACE INTO " + EVENTS_SCRIPT_NAME + "(component, event, flag, type, dispatchmode) VALUES(@component, @event, @flag, @type, @dispatchmode);";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sScript);
    SqlBindString(sql, "@event", sEvent);
    SqlBindInt(sql, "@flag", nFlag);
    SqlBindInt(sql, "@type", nEventType);
    SqlBindInt(sql, "@dispatchmode", bDispatchListMode);
    SqlStep(sql);

    NWNX_Events_SubscribeEvent(sEvent, sScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sEvent, sScript, bDispatchListMode);
}

// *** PUBLIC FUNCTIONS
void Events_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sNewScript = "es_obj_e_" + sEvent;

    int bSet = SetEventScript(oObject, nEvent, sNewScript);

    if (!bSet)
        ES_Util_Log(EVENTS_LOG_TAG, "WARNING: Failed to SetObjectEventScript: " + GetName(oObject) + "(" + IntToString(nEvent) + ")");
    else
    if (bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        SetLocalString(oObject, EVENTS_SCRIPT_NAME + "_OldEventScript!" + sEvent, sOldScript);
}

void Events_SetAreaEventScripts(object oArea, int bStoreOldEvent = TRUE)
{
    int nEvent;
    for (nEvent = EVENT_SCRIPT_AREA_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_AREA_ON_EXIT; nEvent++)
    {
        Events_SetObjectEventScript(oArea, nEvent, bStoreOldEvent);
    }
}

void Events_SetCreatureEventScripts(object oCreature, int bStoreOldEvent = TRUE)
{
    int nEvent;
    for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
    {
        Events_SetObjectEventScript(oCreature, nEvent, bStoreOldEvent);
    }
}

void Events_ClearCreatureEventScripts(object oCreature)
{
    int nEvent;
    for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
    {
        SetEventScript(oCreature, nEvent, "");
    }
}

int Events_GetEventFlagFromEvent(string sEvent)
{
    return StringToInt(GetStringRight(sEvent, 1));
}

string Events_GetEventName_Object(int nEvent, int nEventFlag = EVENTS_EVENT_FLAG_DEFAULT)
{
    return IntToString(nEvent) + "_OBJEVT_" + IntToString(nEventFlag);
}

void Events_SkipEvent()
{
    NWNX_Events_SkipEvent();
}

void Events_SubscribeEvent_Object(string sComponentScript, int nEvent, int nEventFlags = EVENTS_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE)
{
    if (nEventFlags & EVENTS_EVENT_FLAG_BEFORE)
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_BEFORE), bDispatchListMode, EVENTS_EVENT_TYPE_OBJECT, EVENTS_EVENT_FLAG_BEFORE);

    if (nEventFlags & EVENTS_EVENT_FLAG_DEFAULT)
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_DEFAULT), bDispatchListMode, EVENTS_EVENT_TYPE_OBJECT, EVENTS_EVENT_FLAG_DEFAULT);

    if (nEventFlags & EVENTS_EVENT_FLAG_AFTER)
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_AFTER), bDispatchListMode, EVENTS_EVENT_TYPE_OBJECT, EVENTS_EVENT_FLAG_AFTER);
}

void Events_SubscribeEvent_NWNX(string sComponentScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    Events_SubscribeEvent(sComponentScript, sNWNXEvent, bDispatchListMode, EVENTS_EVENT_TYPE_NWNX);
}

void Events_UnsubscribeEvent(string sComponentScript, string sEvent, int bClearDispatchList = FALSE)
{
    string sQuery = "DELETE FROM " + EVENTS_SCRIPT_NAME + " WHERE component=@component AND event=@event;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sComponentScript);
    SqlBindString(sql, "@event", sEvent);
    SqlStep(sql);

    NWNX_Events_UnsubscribeEvent(sEvent, sComponentScript);

    if (bClearDispatchList)
        NWNX_Events_ToggleDispatchListMode(sEvent, sComponentScript, FALSE);
}

void Events_UnsubscribeAllEvents(string sComponentScript, int bClearDispatchLists = FALSE)
{
    string sQuery = "SELECT event FROM " + EVENTS_SCRIPT_NAME + " WHERE component=@component;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sComponentScript);

    while (SqlStep(sql))
    {
        string sEvent = SqlGetString(sql, 0);

        NWNX_Events_UnsubscribeEvent(sEvent, sComponentScript);

        if (bClearDispatchLists)
            NWNX_Events_ToggleDispatchListMode(sEvent, sComponentScript, FALSE);
    }

    sQuery = "DELETE FROM " + EVENTS_SCRIPT_NAME + " WHERE component=@component";
    sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sComponentScript);
    SqlStep(sql);
}

void Events_PushEventData(string sTag, string sData)
{
    NWNX_Events_PushEventData(sTag, sData);
}

int Events_SignalEvent(string sEvent, object oTarget)
{
    return NWNX_Events_SignalEvent(sEvent, oTarget);
}

void Events_AddObjectToDispatchList(string sComponentScript, string sEvent, object oObject)
{
    NWNX_Events_AddObjectToDispatchList(sEvent, sComponentScript, oObject);
}

void Events_RemoveObjectFromDispatchList(string sComponentScript, string sEvent, object oObject)
{
    NWNX_Events_RemoveObjectFromDispatchList(sEvent, sComponentScript, oObject);
}

void Events_AddObjectToAllDispatchLists(string sComponentScript, object oObject)
{
    string sQuery = "SELECT event FROM " + EVENTS_SCRIPT_NAME + " WHERE " + "component=@component AND dispatchmode=@dispatchmode;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sComponentScript);
    SqlBindInt(sql, "@dispatchmode", TRUE);

    while (SqlStep(sql))
    {
        string sEvent = SqlGetString(sql, 0);
        Events_AddObjectToDispatchList(sComponentScript, sEvent, oObject);
    }
}

void Events_RemoveObjectFromAllDispatchLists(string sComponentScript, object oObject)
{
    string sQuery = "SELECT event FROM " + EVENTS_SCRIPT_NAME + " WHERE " + "component=@component AND dispatchmode=@dispatchmode;";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlBindString(sql, "@component", sComponentScript);
    SqlBindInt(sql, "@dispatchmode", TRUE);

    while (SqlStep(sql))
    {
        string sEvent = SqlGetString(sql, 0);
        Events_RemoveObjectFromDispatchList(sComponentScript, sEvent, oObject);
    }
}

string Events_GetEventData_NWNX_String(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int Events_GetEventData_NWNX_Int(string sTag)
{
    return StringToInt(Events_GetEventData_NWNX_String(sTag));
}

float Events_GetEventData_NWNX_Float(string sTag)
{
    return StringToFloat(Events_GetEventData_NWNX_String(sTag));
}

object Events_GetEventData_NWNX_Object(string sTag)
{
    return StringToObject(Events_GetEventData_NWNX_String(sTag));
}

vector Events_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(Events_GetEventData_NWNX_Float(sTagX),
                  Events_GetEventData_NWNX_Float(sTagY),
                  Events_GetEventData_NWNX_Float(sTagZ));
}

location Events_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(Events_GetEventData_NWNX_Object(sTagArea),
                    Events_GetEventData_NWNX_Vector(sTagX, sTagY, sTagZ), 0.0f);
}

void Events_EnterTargetingMode(object oPlayer, string sTargetingMode, int nValidObjectTypes = OBJECT_TYPE_ALL, int nMouseCursorId = MOUSECURSOR_MAGIC, int nBadTargetCursor = MOUSECURSOR_NOMAGIC)
{
    SetLocalString(oPlayer, "ES_TARGETING_MODE", sTargetingMode);
    EnterTargetingMode(oPlayer, nValidObjectTypes, nMouseCursorId, nBadTargetCursor);
}

string Events_GetCurrentTargetingMode(object oPlayer)
{
    return GetLocalString(oPlayer, "ES_TARGETING_MODE");
}

