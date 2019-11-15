/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:
*/

#include "es_inc_util"

#include "nwnx_events"
#include "nwnx_util"
#include "nwnx_object"

const string ES_CORE_SYSTEM_TAG                                 = "Core";

const int ES_CORE_EVENT_FLAG_BEFORE                             = 1;
const int ES_CORE_EVENT_FLAG_DEFAULT                            = 2;
const int ES_CORE_EVENT_FLAG_AFTER                              = 4;

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN                = 3018;

/* Internal Functions */
void ES_Core_Init();
void ES_Core_InitSubsystem(string sSubsystemScript);
void ES_Core_CreateObjectEventScripts(int nStart, int nEnd);
int ES_Core_GetEventFlags(int nEvent);
void ES_Core_SetEventFlag(int nEvent, int nEventFlag);
void ES_Core_SignalEvent(int nEvent, object oTarget = OBJECT_SELF);
/* ****************** */

// Set oObject's nEvent script to the EventSystem's event script
//
// nEvent: An EVENT_SCRIPT_* constant
// bStoreOldEvent: If TRUE, the existing script will be stored and called after the _DEFAULT event.
void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
// Get an ES_CORE_EVENT_FLAG_* from an object event
int ES_Core_GetEventFlagFromEvent(string sEvent);
// Convenience function to construct an object event
//
// If: nEvent = EVENT_SCRIPT_MODULE_ON_MODULE_LOAD & nEventFlag = ES_CORE_EVENT_FLAG_AFTER
// Returns: 3002_OBJEVT_4
string ES_Core_GetEventName_Object(int nEvent, int nEventFlag);

// Subscribe to an object event, generally called in a subsystem's init function.
//
// sEventHandlerScript:
// nEvent: An EVENT_SCRIPT_* constant
// nEventFlags: One or more ES_CORE_EVENT_FLAG_* constants
//              For example, to subscribe to both the _BEFORE and _AFTER event you'd do the following:
//              ES_Core_SubscribeEvent_Object(sEventHandlerScript, nEvent, ES_CORE_EVENT_FLAG_BEFORE | ES_CORE_EVENT_FLAG_AFTER);
// bDispatchListMode: Utility option to toggle DispatchListMode for the event
void ES_Core_SubscribeEvent_Object(string sEventHandlerScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE);
// Convenience function to subscribe to a NWNX event
void ES_Core_SubscribeEvent_NWNX(string sEventHandlerScript, string sNWNXEvent, int bDispatchListMode = FALSE);

// NWNX_Events_GetEventData() string data wrapper (Not really needed)
string ES_Core_GetEventData_NWNX_String(string sTag);
// NWNX_Events_GetEventData() int data wrapper
int ES_Core_GetEventData_NWNX_Int(string sTag);
// NWNX_Events_GetEventData() float data wrapper
float ES_Core_GetEventData_NWNX_Float(string sTag);
// NWNX_Events_GetEventData() object data wrapper
object ES_Core_GetEventData_NWNX_Object(string sTag);
// NWNX_Events_GetEventData() vector data wrapper
vector ES_Core_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ);
// NWNX_Events_GetEventData() location data wrapper
location ES_Core_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ);

void ES_Core_Init()
{
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Initializing Core System");

    object oModule = GetModule();

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Creating object event scripts");
    string sCreateObjectEventScripts = "#" + "include \"es_inc_core\" \n void main() { " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_MODULE_ON_HEARTBEAT, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENT_SCRIPT_AREA_ON_EXIT);" +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, EVENT_SCRIPT_TRIGGER_ON_CLICKED); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_PLACEABLE_ON_CLOSED, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK); "+
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_DOOR_ON_OPEN, EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER, EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_STORE_ON_OPEN, EVENT_SCRIPT_STORE_ON_CLOSE); }";
    ExecuteScriptChunk(sCreateObjectEventScripts, oModule, FALSE);

    int nEvent;
    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Hooking module event scripts");
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT; nEvent++)
    {
        ES_Core_SetObjectEventScript(oModule, nEvent);
    }

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Hooking area event scripts");
    string sSetAreaEventScripts = "#" + "include \"es_inc_core\" \n void main() { " +
        "object oArea = GetFirstArea(); " +
        "while (GetIsObjectValid(oArea)) { " +
        "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_HEARTBEAT); " +
        "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_USER_DEFINED_EVENT); " +
        "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_ENTER); " +
        "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_EXIT); " +
        "oArea = GetNextArea(); } } ";
    ExecuteScriptChunk(sSetAreaEventScripts, oModule, FALSE);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Initializing Subsystems");

    string sSubsystemScript = NWNX_Util_GetFirstResRef(NWNX_UTIL_RESREF_TYPE_NSS, "es_s_.+", FALSE);

    while (sSubsystemScript != "")
    {
        if (GetLocalInt(oModule, sSubsystemScript))
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Skipping subsystem initialization: '" + sSubsystemScript + "'");
        }
        else
        {
            string sInitSubsystemScriptChunk = "#" + "include \"es_inc_core\" \n void main() { ES_Core_InitSubsystem(\"" + sSubsystemScript + "\"); }";
            ExecuteScriptChunk(sInitSubsystemScriptChunk, oModule, FALSE);
        }

        sSubsystemScript = NWNX_Util_GetNextResRef();
    }

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Done!");
}

void ES_Core_InitSubsystem(string sSubsystemScript)
{
    string sSubsystemName = GetSubString(sSubsystemScript, 5, GetStringLength(sSubsystemScript) - 5);
    string sSubsystemScriptContents = NWNX_Util_GetNSSContents(sSubsystemScript);
    string sSubsystemInitFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_Init");

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Initializing subsystem: '" + sSubsystemScript + "'");

    if (sSubsystemInitFunction == "")
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > WARNING: '" + sSubsystemScript + "' does not have an init function set, skipping initialization.");
        return;
    }
    else
    {
        string sEventHandlerScript;
        string sSubsystemEventHandlerFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_EventHandler");

        if (sSubsystemEventHandlerFunction != "")
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Creating event handler script with function '" + sSubsystemEventHandlerFunction + "()' for subsystem: '" + sSubsystemName + "'");

            sEventHandlerScript = "es_e_" + sSubsystemName;

            string sSubsystemEventHandlerScriptChunk = "#" + "include \"" + sSubsystemScript  + "\" \n void main() { " +
                sSubsystemEventHandlerFunction + "(\"" + sEventHandlerScript + "\", NWNX_Events_GetCurrentEvent()); }";

            if (!NWNX_Util_AddScript(sEventHandlerScript, sSubsystemEventHandlerScriptChunk))
            {
                ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > ERROR: Failed to compile event handler script for subsystem: '" + sSubsystemName + "'");
            }
        }
        else
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Not creating event handler script for subsystem: '" + sSubsystemName + "'");
        }

        ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Executing init function '" + sSubsystemInitFunction + "()' for subsystem: '" + sSubsystemName + "'");

        string sSubsystemInitScriptChunk = "#" + "include \"" + sSubsystemScript  + "\" \n void main() { " + sSubsystemInitFunction + "(\"" + sEventHandlerScript + "\"); }";
        string sResult = ExecuteScriptChunk(sSubsystemInitScriptChunk, GetModule(), FALSE);

        if (sResult != "")
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > ERROR: Init function for subsystem: '" + sSubsystemName + "' failed with compilation error: " + sResult);
        }
    }
}

void ES_Core_CreateObjectEventScripts(int nStart, int nEnd)
{
    int nEvent;
    for (nEvent = nStart; nEvent <= nEnd; nEvent++)
    {
        string sScriptName = "es_obj_e_" + IntToString(nEvent);
        string sScriptData = "#" + "include \"es_inc_core\" \n void main() { ES_Core_SignalEvent(" + IntToString(nEvent) + "); }";

        NWNX_Util_AddScript(sScriptName, sScriptData);
    }
}

int ES_Core_GetEventFlags(int nEvent)
{
    return GetLocalInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "EventFlags_" + IntToString(nEvent));
}

void ES_Core_SetEventFlag(int nEvent, int nEventFlag)
{
    SetLocalInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG),
                "EventFlags_" + IntToString(nEvent),
                ES_Core_GetEventFlags(nEvent) | nEventFlag);
}

void ES_Core_SignalEvent(int nEvent, object oTarget = OBJECT_SELF)
{
    int nEventFlags = ES_Core_GetEventFlags(nEvent);
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), oTarget);

    // *** Run any old stored event scripts
    string sScript = GetLocalString(oTarget, "ES_Core_OldEventScript_" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);
    // ***

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), oTarget);
}

/* *** */

void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sNewScript = "es_obj_e_" + sEvent;

    SetEventScript(oObject, nEvent, sNewScript);

    if (bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        SetLocalString(oObject, "ES_Core_OldEventScript_" + sEvent, sOldScript);
}

int ES_Core_GetEventFlagFromEvent(string sEvent)
{
    return StringToInt(GetStringRight(sEvent, 1));
}

string ES_Core_GetEventName_Object(int nEvent, int nEventFlag)
{
    return IntToString(nEvent) + "_OBJEVT_" + IntToString(nEventFlag);
}

void ES_Core_SubscribeEvent_Object(string sEventHandlerScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE)
{
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_BEFORE);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sEventHandlerScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_DEFAULT);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sEventHandlerScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_AFTER);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sEventHandlerScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sEventHandlerScript, bDispatchListMode);
    }
}

void ES_Core_SubscribeEvent_NWNX(string sEventHandlerScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    NWNX_Events_SubscribeEvent(sNWNXEvent, sEventHandlerScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sNWNXEvent, sEventHandlerScript, bDispatchListMode);
}

/* *** */

string ES_Core_GetEventData_NWNX_String(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int ES_Core_GetEventData_NWNX_Int(string sTag)
{
    return StringToInt(ES_Core_GetEventData_NWNX_String(sTag));
}

float ES_Core_GetEventData_NWNX_Float(string sTag)
{
    return StringToFloat(ES_Core_GetEventData_NWNX_String(sTag));
}

object ES_Core_GetEventData_NWNX_Object(string sTag)
{
    return NWNX_Object_StringToObject(ES_Core_GetEventData_NWNX_String(sTag));
}

vector ES_Core_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(ES_Core_GetEventData_NWNX_Float(sTagX),
                  ES_Core_GetEventData_NWNX_Float(sTagY),
                  ES_Core_GetEventData_NWNX_Float(sTagZ));
}

location ES_Core_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(ES_Core_GetEventData_NWNX_Object(sTagArea),
                    ES_Core_GetEventData_NWNX_Vector(sTagX, sTagY, sTagZ), 0.0f);
}

