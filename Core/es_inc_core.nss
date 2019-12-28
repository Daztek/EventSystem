/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:
*/

//void main(){}

#include "es_inc_util"

#include "x0_i0_stringlib"
#include "nwnx_events"
#include "nwnx_object"

const string ES_CORE_SYSTEM_TAG                     = "Core";

const int ES_CORE_EVENT_FLAG_BEFORE                 = 1;
const int ES_CORE_EVENT_FLAG_DEFAULT                = 2;
const int ES_CORE_EVENT_FLAG_AFTER                  = 4;

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN    = 3018;

/* Internal Functions */
int ES_Core_GetCoreHashChanged();
string ES_Core_GetDependencies(string sScriptContents);
int ES_Core_GetEventFlags(int nEvent);
void ES_Core_SetEventFlag(int nEvent, int nEventFlag);
/* ****************** */

// Set oObject's nEvent script to the EventSystem's event script
//
// nEvent: An EVENT_SCRIPT_* constant
// bStoreOldEvent: If TRUE, the existing script will be stored and called before the _DEFAULT event.
void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE);
// Get an ES_CORE_EVENT_FLAG_* from an object event
int ES_Core_GetEventFlagFromEvent(string sEvent);
// Convenience function to construct an object event
//
// If nEvent = EVENT_SCRIPT_MODULE_ON_MODULE_LOAD and nEventFlag = ES_CORE_EVENT_FLAG_AFTER -> Returns: 3002_OBJEVT_4
string ES_Core_GetEventName_Object(int nEvent, int nEventFlag = ES_CORE_EVENT_FLAG_DEFAULT);

// Subscribe to an object event, generally called in a subsystem's init function.
//
// sEventHandlerScript:
// nEvent: An EVENT_SCRIPT_* constant
// nEventFlags: One or more ES_CORE_EVENT_FLAG_* constants
//              For example, to subscribe to both the _BEFORE and _AFTER event you'd do the following:
//              ES_Core_SubscribeEvent_Object(sEventHandlerScript, nEvent, ES_CORE_EVENT_FLAG_BEFORE | ES_CORE_EVENT_FLAG_AFTER);
// bDispatchListMode: Convenience option to toggle DispatchListMode for the event
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

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Checking Core Hash");
    ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_CheckCoreHash();", oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Checking object event scripts");
    string sCreateObjectEventScripts =
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_MODULE_ON_HEARTBEAT, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENT_SCRIPT_AREA_ON_EXIT);" +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, EVENT_SCRIPT_TRIGGER_ON_CLICKED); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_PLACEABLE_ON_CLOSED, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK); "+
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_DOOR_ON_OPEN, EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER, EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT); " +
        "ES_Core_CreateObjectEventScripts(EVENT_SCRIPT_STORE_ON_OPEN, EVENT_SCRIPT_STORE_ON_CLOSE);";
    ES_Util_ExecuteScriptChunk("es_inc_core", sCreateObjectEventScripts, oModule);

    int nEvent;
    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Hooking module event scripts");
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT; nEvent++)
    {
        ES_Core_SetObjectEventScript(oModule, nEvent);
    }

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Hooking area event scripts");
    string sSetAreaEventScripts =
        "object oArea = GetFirstArea(); " +
        "while (GetIsObjectValid(oArea)) { " +
            "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_HEARTBEAT); " +
            "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_USER_DEFINED_EVENT); " +
            "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_ENTER); " +
            "ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_EXIT); " +
            "oArea = GetNextArea(); }";
    ES_Util_ExecuteScriptChunk("es_inc_core", sSetAreaEventScripts, oModule);

    string sSubsystemList = ES_Util_GetResRefList(NWNX_UTIL_RESREF_TYPE_NSS, "es_s_.+", FALSE);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Initializing Subsystems");
    ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_InitSubsystems(\"" + sSubsystemList + "\");", oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " * Checking subsystem changes");
    ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_CheckSubsystemChanges(\"" + sSubsystemList + "\");", oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " * Checking dependency changes");
    ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_CheckDependencyChanges(\"" + sSubsystemList + "\");", oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, " * Cleaning up");
    ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_Cleanup(\"" + sSubsystemList + "\");", oModule);

    ES_Util_Log(ES_CORE_SYSTEM_TAG, "* Done!");
}

void ES_Core_CheckCoreHash()
{
    string sCoreIncludeScript = "es_inc_core";
    string sCoreScriptContents = NWNX_Util_GetNSSContents(sCoreIncludeScript);
    int nOldCoreHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sCoreIncludeScript);
    int nNewCoreHash = NWNX_Util_Hash(sCoreScriptContents);

    if (nOldCoreHash != nNewCoreHash)
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > Core Hash Changed -> Old: " + IntToString(nOldCoreHash) + ", New: " + IntToString(nNewCoreHash));

        SetCampaignInt(GetModuleName() + "_EventSystemCore", sCoreIncludeScript, nNewCoreHash);
        SetLocalInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "CoreHashChanged", TRUE);
    }
}

int ES_Core_GetCoreHashChanged()
{
    return GetLocalInt(ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG), "CoreHashChanged");
}

void ES_Core_InitSubsystem(string sSubsystemScript)
{
    ES_Util_Log(ES_CORE_SYSTEM_TAG, " > Initializing subsystem: '" + sSubsystemScript + "'");

    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystemScript);
    string sSubsystemScriptContents = NWNX_Util_GetNSSContents(sSubsystemScript);

    string sSubsystemDependencies = ES_Core_GetDependencies(sSubsystemScriptContents);
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > Dependencies: " + (sSubsystemDependencies == "" ? "N/A" : sSubsystemDependencies));
    SetLocalString(oDataObject, "Dependencies", sSubsystemDependencies);

    int nSubsystemHash = NWNX_Util_Hash(sSubsystemScriptContents);
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > Hash: " + IntToString(nSubsystemHash));
    SetLocalInt(oDataObject, "Hash", nSubsystemHash);

    string sSubsystemEventHandlerFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_EventHandler");
    ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > EventHandler: " + (sSubsystemEventHandlerFunction == "" ? "N/A" : sSubsystemEventHandlerFunction + "()"));
    SetLocalString(oDataObject, "EventHandlerFunction", sSubsystemEventHandlerFunction);

    string sEventHandlerScript = "es_e_" + GetSubString(sSubsystemScript, 5, GetStringLength(sSubsystemScript) - 5);
    SetLocalString(oDataObject, "EventHandlerScript", sEventHandlerScript);

    int bForceRecompileFlag = ES_Util_GetScriptFlag(sSubsystemScriptContents, "EventSystem_ForceRecompile");
    SetLocalInt(oDataObject, "ForceRecompile", bForceRecompileFlag);

    string sSubsystemInitFunction = ES_Util_GetFunctionName(sSubsystemScriptContents, "EventSystem_Init");

    if (sSubsystemInitFunction != "")
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > Executing init function: " + sSubsystemInitFunction + "()");

        string sResult = ES_Util_ExecuteScriptChunk(sSubsystemScript, sSubsystemInitFunction + "(\"" + sEventHandlerScript + "\");", GetModule());

        if (sResult != "")
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "     > ERROR: Init function for subsystem: '" + sSubsystemScript + "' failed with error: " + sResult);
        }
    }
    else
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > WARNING: '" + sSubsystemScript + "' does not have an init function set");
    }
}

void ES_Core_InitSubsystems(string sSubsystemList)
{
    object oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sSubsystemList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sSubsystem = GetTokenByPosition(sSubsystemList, ";", nCount);

        ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_InitSubsystem(\"" + sSubsystem + "\");", oModule);
    }
}

void ES_Core_CreateObjectEventScripts(int nStart, int nEnd)
{
    int nEvent;
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();

    for (nEvent = nStart; nEvent <= nEnd; nEvent++)
    {
        string sScriptName = "es_obj_e_" + IntToString(nEvent);
        int bObjectEventScriptExists = NWNX_Util_IsValidResRef(sScriptName, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bCoreHashChanged || !bObjectEventScriptExists)
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "   > " + (!bObjectEventScriptExists ? "Creating" : "Recompiling") + " object event script: '" + sScriptName + "'");

            ES_Util_AddScript(sScriptName, "es_inc_core", "ES_Core_SignalEvent(" + IntToString(nEvent) + ");");
        }
    }
}

string ES_Core_GetDependencies(string sScriptContents)
{
    string sDependencies;
    int nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", 0), nIncludeEnd;

    while (nIncludeStart != -1)
    {
        nIncludeEnd = FindSubString(sScriptContents, "\"", nIncludeStart + 10);

        string sDependency = GetSubString(sScriptContents, nIncludeStart + 10, nIncludeEnd - nIncludeStart - 10);

        if (GetStringLeft(sDependency, 5) == "es_s_")
            sDependencies += sDependency + ";";

        nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", nIncludeEnd);
    }

    if (GetStringLength(sDependencies))
        sDependencies = GetSubString(sDependencies, 0, GetStringLength(sDependencies) - 1);

    return sDependencies;
}

void ES_Core_CompileEventHandler(string sSubsystem, string sEventHandlerScript, string sEventHandlerFunction)
{
    string sEventHandlerScriptChunk = sEventHandlerFunction + "(\"" + sEventHandlerScript + "\", NWNX_Events_GetCurrentEvent());";
    string sResult = ES_Util_AddScript(sEventHandlerScript, sSubsystem, sEventHandlerScriptChunk);

    if (sResult != "")
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > ERROR: Failed to compile event handler for subsystem: '" + sSubsystem + "' with error: " + sResult);
    }
}

void ES_Core_HandleSubsystemChanges(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();

    int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sSubsystem);
    int nNewHash = GetLocalInt(oDataObject, "Hash");
    int bHashChanged = nOldHash != nNewHash;

    if (bHashChanged)
    {
        ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Hash for subsystem '" + sSubsystem + "' has changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
        SetCampaignInt(GetModuleName() + "_EventSystemCore", sSubsystem, nNewHash);
        SetLocalInt(oDataObject, "HashChanged", bHashChanged);
    }

    string sSubsystemEventHandlerFunction = GetLocalString(oDataObject, "EventHandlerFunction");

    if (sSubsystemEventHandlerFunction != "")
    {
        string sSubsystemEventHandlerScript = GetLocalString(oDataObject, "EventHandlerScript");
        int bEventScriptExists = NWNX_Util_IsValidResRef(sSubsystemEventHandlerScript, NWNX_UTIL_RESREF_TYPE_NCS);
        int bForceRecompileFlag = GetLocalInt(oDataObject, "ForceRecompile");

        if (bCoreHashChanged || !bEventScriptExists || bHashChanged || bForceRecompileFlag)
        {
            ES_Util_Log(ES_CORE_SYSTEM_TAG, "    > " + (!bEventScriptExists ? "Compiling" :
                (bForceRecompileFlag && !bHashChanged) ? "(Forced) Recompiling" : "Recompiling") + " event handler for subsystem: '" + sSubsystem + "'");

            ES_Core_CompileEventHandler(sSubsystem, sSubsystemEventHandlerScript, sSubsystemEventHandlerFunction);

            SetLocalInt(oDataObject, "DidNotExist", !bEventScriptExists);
            SetLocalInt(oDataObject, "HasBeenCompiled", TRUE);
        }

        SetLocalInt(oDataObject, "HasEventHandler", TRUE);
    }
}

void ES_Core_CheckSubsystemChanges(string sSubsystemList)
{
    object oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sSubsystemList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sSubsystem = GetTokenByPosition(sSubsystemList, ";", nCount);

        ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_HandleSubsystemChanges(\"" + sSubsystem + "\");", oModule);
    }
}

void ES_Core_HandleDependencyChanges(string sSubsystem)
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
    int bHasEventHandler = GetLocalInt(oDataObject, "HasEventHandler");
    int bDidNotExist = GetLocalInt(oDataObject, "DidNotExist");
    int bHasBeenCompiled = GetLocalInt(oDataObject, "HasBeenCompiled");

    if (bHasEventHandler && !bDidNotExist && !bHasBeenCompiled)
    {
        string sSubsystemDependencies = GetLocalString(oDataObject, "Dependencies");

        if (sSubsystemDependencies != "")
        {
            int nDepCount, nNumDeps = GetNumberTokens(sSubsystemDependencies, ";");

            for (nDepCount = 0; nDepCount < nNumDeps; nDepCount++)
            {
                string sDepSubsystem = GetTokenByPosition(sSubsystemDependencies, ";", nDepCount);
                object oDepDataObject = ES_Util_GetDataObject(ES_CORE_SYSTEM_TAG + "_" + sDepSubsystem);

                if (GetLocalInt(oDepDataObject, "HashChanged"))
                {
                    ES_Util_Log(ES_CORE_SYSTEM_TAG, "  > Dependencies for '" + sSubsystem + "' have changed, recompiling event handler");

                    string sSubsystemEventHandlerScript = GetLocalString(oDataObject, "EventHandlerScript");
                    string sSubsystemEventHandlerFunction = GetLocalString(oDataObject, "EventHandlerFunction");

                    ES_Core_CompileEventHandler(sSubsystem, sSubsystemEventHandlerScript, sSubsystemEventHandlerFunction);

                    break;
                }
            }
        }
    }
}

void ES_Core_CheckDependencyChanges(string sSubsystemList)
{
    object oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sSubsystemList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sSubsystem = GetTokenByPosition(sSubsystemList, ";", nCount);

        ES_Util_ExecuteScriptChunk("es_inc_core", "ES_Core_HandleDependencyChanges(\"" + sSubsystem + "\");", oModule);
    }
}

void ES_Core_Cleanup(string sSubsystemList)
{
    int nCount, nNumTokens = GetNumberTokens(sSubsystemList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sSubsystem = GetTokenByPosition(sSubsystemList, ";", nCount);

        ES_Util_DestroyDataObject(ES_CORE_SYSTEM_TAG + "_" + sSubsystem);
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

    // *** Run any old stored event scripts
    string sScript = GetLocalString(oTarget, "ES_Core_OldEventScript_" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);
    // ***

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), oTarget);

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

string ES_Core_GetEventName_Object(int nEvent, int nEventFlag = ES_CORE_EVENT_FLAG_DEFAULT)
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

