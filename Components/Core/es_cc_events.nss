/*
    ScriptName: es_cc_events.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Events Object]

    Description: An EventSystem Core Component that allows Services
                 and Subsystems to subscribe to events
*/

#include "es_inc_core"
#include "nwnx_events"
#include "nwnx_object"

//void main(){}

const string EVENTS_LOG_TAG                         = "Events";
const string EVENTS_SCRIPT_NAME                     = "es_cc_events";

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN    = 3018;
const string EVENTS_SCRIPT_PREFIX                   = "es_obj_e_";

const int EVENTS_EVENT_FLAG_BEFORE                  = 1;
const int EVENTS_EVENT_FLAG_DEFAULT                 = 2;
const int EVENTS_EVENT_FLAG_AFTER                   = 4;

// INTERNAL FUNCTION
void Events_CheckObjectEventScripts(int nStart, int nEnd);
// INTERNAL FUNCTION: Subscribe sScript to sEvent.
// You probably want one of these instead:
//  - Events_SubscribeEvent_Object()
//  - Events_SubscribeEvent_NWNX();
void Events_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode);

// Set oObject's nEvent script to the EventSystem's event script
//
// nEvent: An EVENT_SCRIPT_* constant
// bStoreOldEvent: If TRUE, the existing script will be stored and called before the _DEFAULT event.
void Events_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
// Wrapper for Events_SetObjectEventScript() to set all event scripts for an area
void Events_SetAreaEventScripts(object oArea, int bStoreOldEvent = TRUE);
// Get an ES_CORE_EVENT_FLAG_* from an object event
int Events_GetEventFlagFromEvent(string sEvent);
// Convenience function to construct an object event
//
// If nEvent = EVENT_SCRIPT_MODULE_ON_MODULE_LOAD and nEventFlag = EVENTS_EVENT_FLAG_AFTER -> Return = 3002_OBJEVT_4
string Events_GetEventName_Object(int nEvent, int nEventFlag = EVENTS_EVENT_FLAG_DEFAULT);
// Skips execution of the currently executing event.
void Events_SkipEvent();
// Subscribe to an object event, generally called in a component's init function.
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
// Attempt to add oObject to the dispatch lists of *all* events sComponentScript is subscribed to
void Events_AddObjectToAllDispatchLists(string sComponentScript, object oObject);
// Attempt to remove oObject from the dispatch lists of *all* events sComponentScript is subscribed to
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

// @Load
void Events_Load(string sCoreComponentScript)
{
    ES_Util_Log(EVENTS_LOG_TAG, "* Checking Object Event Scripts");

    // Check if the module shutdown script is set to sShutdownScriptName
    string sShutdownScriptName = EVENTS_SCRIPT_PREFIX + IntToString(EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN);
    if (NWNX_Util_GetEnvironmentVariable("NWNX_CORE_SHUTDOWN_SCRIPT") != sShutdownScriptName)
        ES_Util_Log(EVENTS_LOG_TAG, "  > WARNING: NWNX environment variable 'NWNX_CORE_SHUTDOWN_SCRIPT' is not set to: " + sShutdownScriptName);

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
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT; nEvent++)
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

// *** INTERNAL FUNCTIONS
void Events_CheckObjectEventScripts(int nStart, int nEnd)
{
    int bHashChanged = GetLocalInt(ES_Core_GetComponentDataObject(EVENTS_SCRIPT_NAME), "HashChanged"), nEvent;

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

int Events_GetEventFlags(int nEvent)
{
    return GetLocalInt(ES_Util_GetDataObject(EVENTS_SCRIPT_NAME), "EventFlags_" + IntToString(nEvent));
}

void Events_SetEventFlag(int nEvent, int nEventFlag)
{
    SetLocalInt(ES_Util_GetDataObject(EVENTS_SCRIPT_NAME),
                "EventFlags_" + IntToString(nEvent),
                Events_GetEventFlags(nEvent) | nEventFlag);
}

void Events_SignalObjectEvent(int nEvent, object oTarget = OBJECT_SELF)
{
    int nEventFlags = Events_GetEventFlags(nEvent);
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & EVENTS_EVENT_FLAG_BEFORE)
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_BEFORE), oTarget);

    // Run any old stored event scripts
    string sScript = GetLocalString(oTarget, EVENTS_SCRIPT_NAME + "_OldEventScript!" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);

    if (nEventFlags & EVENTS_EVENT_FLAG_DEFAULT)
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_DEFAULT), oTarget);

    if (nEventFlags & EVENTS_EVENT_FLAG_AFTER)
        Events_SignalEvent(sEvent + IntToString(EVENTS_EVENT_FLAG_AFTER), oTarget);
}

void Events_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode)
{
    object oDataObject = ES_Util_GetDataObject(sScript);

    StringArray_Insert(oDataObject, "SubscribedEvents", sEvent);

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

    if (bSet && bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        SetLocalString(oObject, EVENTS_SCRIPT_NAME + "_OldEventScript!" + sEvent, sOldScript);
}

void Events_SetAreaEventScripts(object oArea, int bStoreOldEvent = TRUE)
{
    Events_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_HEARTBEAT, bStoreOldEvent);
    Events_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_USER_DEFINED_EVENT, bStoreOldEvent);
    Events_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_ENTER, bStoreOldEvent);
    Events_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_EXIT, bStoreOldEvent);
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
    {
        Events_SetEventFlag(nEvent, EVENTS_EVENT_FLAG_BEFORE);
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_BEFORE), bDispatchListMode);
    }

    if (nEventFlags & EVENTS_EVENT_FLAG_DEFAULT)
    {
        Events_SetEventFlag(nEvent, EVENTS_EVENT_FLAG_DEFAULT);
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_DEFAULT), bDispatchListMode);
    }

    if (nEventFlags & EVENTS_EVENT_FLAG_AFTER)
    {
        Events_SetEventFlag(nEvent, EVENTS_EVENT_FLAG_AFTER);
        Events_SubscribeEvent(sComponentScript, Events_GetEventName_Object(nEvent, EVENTS_EVENT_FLAG_AFTER), bDispatchListMode);
    }
}

void Events_SubscribeEvent_NWNX(string sComponentScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    Events_SubscribeEvent(sComponentScript, sNWNXEvent, bDispatchListMode);
}

void Events_UnsubscribeEvent(string sComponentScript, string sEvent, int bClearDispatchList = FALSE)
{
    object oDataObject = ES_Util_GetDataObject(sComponentScript);

    StringArray_DeleteByValue(oDataObject, "SubscribedEvents", sEvent);

    NWNX_Events_UnsubscribeEvent(sEvent, sComponentScript);

    if (bClearDispatchList)
        NWNX_Events_ToggleDispatchListMode(sEvent, sComponentScript, FALSE);
}

void Events_UnsubscribeAllEvents(string sComponentScript, int bClearDispatchLists = FALSE)
{
    object oDataObject = ES_Util_GetDataObject(sComponentScript);

    int nNumEvents = StringArray_Size(oDataObject, "SubscribedEvents"), nIndex;

    for (nIndex = 0; nIndex < nNumEvents; nIndex++)
    {
        string sEvent = StringArray_At(oDataObject, "SubscribedEvents", nIndex);

        NWNX_Events_UnsubscribeEvent(sEvent, sComponentScript);

        if (bClearDispatchLists)
            NWNX_Events_ToggleDispatchListMode(sEvent, sComponentScript, FALSE);
    }

    StringArray_Clear(oDataObject, "SubscribedEvents");
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
    object oDataObject = ES_Util_GetDataObject(sComponentScript);

    int nNumEvents = StringArray_Size(oDataObject, "SubscribedEvents"), nIndex;

    for (nIndex = 0; nIndex < nNumEvents; nIndex++)
    {
        string sEvent = StringArray_At(oDataObject, "SubscribedEvents", nIndex);

        Events_AddObjectToDispatchList(sComponentScript, sEvent, oObject);
    }
}

void Events_RemoveObjectFromAllDispatchLists(string sComponentScript, object oObject)
{
    object oDataObject = ES_Util_GetDataObject(sComponentScript);

    int nNumEvents = StringArray_Size(oDataObject, "SubscribedEvents"), nIndex;

    for (nIndex = 0; nIndex < nNumEvents; nIndex++)
    {
        string sEvent = StringArray_At(oDataObject, "SubscribedEvents", nIndex);

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
    return NWNX_Object_StringToObject(Events_GetEventData_NWNX_String(sTag));
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

