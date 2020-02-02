/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:
*/

//void main() {}

#include "es_inc_util"

const string ES_CORE_LOG_TAG            = "Core";
const string ES_CORE_SCRIPT_NAME        = "es_inc_core";

const int ES_CORE_EVENT_FLAG_BEFORE     = 1;
const int ES_CORE_EVENT_FLAG_DEFAULT    = 2;
const int ES_CORE_EVENT_FLAG_AFTER      = 4;

/* Internal Functions */
int ES_Core_GetCoreHashChanged();
int ES_Core_GetFunctionHashChanged(string sFunction);
void ES_Core_CheckObjectEventScripts(int nStart, int nEnd);
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
// sSubsystemScript:
// nEvent: An EVENT_SCRIPT_* constant
// nEventFlags: One or more ES_CORE_EVENT_FLAG_* constants
//              For example, to subscribe to both the _BEFORE and _AFTER event you'd do the following:
//              ES_Core_SubscribeEvent_Object(sEventHandlerScript, nEvent, ES_CORE_EVENT_FLAG_BEFORE | ES_CORE_EVENT_FLAG_AFTER);
// bDispatchListMode: Convenience option to toggle DispatchListMode for the event
void ES_Core_SubscribeEvent_Object(string sSubsystemScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE);
// Convenience function to subscribe to a NWNX event
void ES_Core_SubscribeEvent_NWNX(string sSubsystemScript, string sNWNXEvent, int bDispatchListMode = FALSE);

void ES_Core_Init()
{
    ES_Util_Log(ES_CORE_LOG_TAG, "* Initializing EventSystem");

    // We do a lot of stuff so increase the max instruction limit for the init function
    // 64x Ought to be Enough for Anyone
    NWNX_Util_SetInstructionLimit(524288 * 64);

    // Workaround to reset the instruction limit increase without it showing an error
    // due to it resetting while the init function isn't done executing yet
    ES_Util_AddScript(ES_CORE_SCRIPT_NAME, ES_CORE_SCRIPT_NAME, nssFunction("NWNX_Util_SetInstructionLimit", "-1") +
        nssFunction("NWNX_Util_RemoveNWNXResourceFile", "ES_CORE_SCRIPT_NAME, NWNX_UTIL_RESREF_TYPE_NCS"));
    ES_Core_SubscribeEvent_Object(ES_CORE_SCRIPT_NAME, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);


    object oModule = GetModule();
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME);


    // This checks if any of the es_inc_* NSS files have changed
    // Can be disabled by setting the ES_SKIP_CORE_HASH_CHECK environment variable to true
    if (!ES_Util_GetBooleanEnvVar("ES_SKIP_CORE_HASH_CHECK"))
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > Checking Core Hashes");
        ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckCoreHashes"), oModule);
    }
    else
        ES_Util_Log(ES_CORE_LOG_TAG, "  > Skipping Core Hash Check");

    // This checks if any of the nwnx_* NSS files have changed
    // Can be disabled by setting the ES_SKIP_NWNX_HASH_CHECK environment variable to true
    if (!ES_Util_GetBooleanEnvVar("ES_SKIP_NWNX_HASH_CHECK"))
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > Checking NWNX Hashes");
        ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckNWNXHashes"), oModule);
    }
    else
        ES_Util_Log(ES_CORE_LOG_TAG, "  > Skipping NWNX Hash Check");

    // Check if the user has disabled any services through the ES_DISABLE_SERVICES environment variable
    string sDisabledServices = NWNX_Util_GetEnvironmentVariable("ES_DISABLE_SERVICES");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Manually Disabled Services: " + (sDisabledServices == "" ? "N/A" : sDisabledServices));
    ES_Util_SetString(oDataObject, "DisabledServices", sDisabledServices);

    // Check if the user has disabled any subsystems through the ES_DISABLE_SUBSYSTEMS environment variable
    string sDisabledSubsystems = NWNX_Util_GetEnvironmentVariable("ES_DISABLE_SUBSYSTEMS");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Manually Disabled Subsystems: " + (sDisabledSubsystems == "" ? "N/A" : sDisabledSubsystems));
    ES_Util_SetString(oDataObject, "DisabledSubsystems", sDisabledSubsystems);


    // *** CHECK EVENT SCRIPTS
    ES_Util_Log(ES_CORE_LOG_TAG, "  > Checking Object Event Scripts");
    // Check if ES_Core_SignalEvent's function hash has changed
    if (ES_Core_GetFunctionHashChanged("ES_Core_SignalEvent"))
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Recompiling Object Event Scripts");

    // Check if all the object event script exist and (re)compile them if needed
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_MODULE_ON_HEARTBEAT, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENT_SCRIPT_AREA_ON_EXIT);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_AREAOFEFFECT_ON_HEARTBEAT, EVENT_SCRIPT_AREAOFEFFECT_ON_OBJECT_EXIT);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_CREATURE_ON_HEARTBEAT, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, EVENT_SCRIPT_TRIGGER_ON_CLICKED);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_PLACEABLE_ON_CLOSED, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_DOOR_ON_OPEN, EVENT_SCRIPT_DOOR_ON_FAIL_TO_OPEN);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_ENCOUNTER_ON_OBJECT_ENTER, EVENT_SCRIPT_ENCOUNTER_ON_USER_DEFINED_EVENT);
    ES_Core_CheckObjectEventScripts(EVENT_SCRIPT_STORE_ON_OPEN, EVENT_SCRIPT_STORE_ON_CLOSE);


    // *** SET EVENT SCRIPTS
    ES_Util_Log(ES_CORE_LOG_TAG, "  > Hooking Module Event Scripts");
    // Set all module event script to the EventSystem event scripts
    int nEvent;
    for(nEvent = EVENT_SCRIPT_MODULE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT; nEvent++)
    {
        ES_Core_SetObjectEventScript(oModule, nEvent);
    }

    ES_Util_Log(ES_CORE_LOG_TAG, "  > Hooking Area Event Scripts");
    // Set all area event script to the EventSystem event scripts
    object oArea = GetFirstArea();
    while (GetIsObjectValid(oArea))
    {
        ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_HEARTBEAT);
        ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_USER_DEFINED_EVENT);
        ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_ENTER);
        ES_Core_SetObjectEventScript(oArea, EVENT_SCRIPT_AREA_ON_EXIT);

        oArea = GetNextArea();
    }


    // *** SERVICES
    ES_Util_Log(ES_CORE_LOG_TAG, "");

    // Get an array of all the services
    string sServicesArray = ES_Util_GetResRefArray(oDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_srv_.+", FALSE);
    ES_Util_SetString(oDataObject, "Services", sServicesArray);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Services: Load");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sServicesArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_Service_Load", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Services: Hash Check");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sServicesArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_CheckHash", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Services: Init");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sServicesArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Init")), oModule);


    // *** SUBSYSTEMS
    ES_Util_Log(ES_CORE_LOG_TAG, "");

    // Get an array of all the subsystems
    string sSubsystemArray = ES_Util_GetResRefArray(oDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_s_.+", FALSE);
    ES_Util_SetString(oDataObject, "Subsystems", sSubsystemArray);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Load");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sSubsystemArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_Subsystem_Load", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Hash Check");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sSubsystemArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_CheckHash", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Services Check");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sSubsystemArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_Subsystem_CheckServices", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Status Check");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sSubsystemArray, ES_CORE_SCRIPT_NAME,
    nssFunction("ES_Core_Subsystem_CheckStatus", "sArrayElement"), oModule);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Init");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sSubsystemArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Init")), oModule);


    // *** POST
    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Services: Post");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sServicesArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Post")), oModule);


    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Done!");
}

// *****************************************************************************
// Data Object Functions
object ES_Core_GetSystemObject(string sSystem)
{
    return ES_Util_GetDataObject("ESCore!" + ES_CORE_SCRIPT_NAME + "!" + sSystem);
}

// *****************************************************************************
// Core + Function Hash Check Functions
void ES_Core_CheckFunctionHash(string sScriptContents, string sFunction)
{
    string sFunctionContents = ES_Util_GetFunctionImplementation(sScriptContents, sFunction);

    if (sFunctionContents == "")
        ES_Util_Log(ES_CORE_LOG_TAG, "      > ERROR: Implementation for Function '" + sFunction + "' could not be found");
    else
    {
        int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", "FunctionHash_" + sFunction);
        int nNewHash = NWNX_Util_Hash(sFunctionContents);

        if (nOldHash != nNewHash)
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "      > Hash for Function '" + sFunction + "' Changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
            SetCampaignInt(GetModuleName() + "_EventSystemCore", "FunctionHash_" + sFunction, nNewHash);
            ES_Util_SetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "FunctionHashChanged_" + sFunction, TRUE);
        }
    }
}

void ES_Core_CheckIncludeHash(string sInclude)
{
    string sIncludeScriptContents = NWNX_Util_GetNSSContents(sInclude);
    int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sInclude);
    int nNewHash = NWNX_Util_Hash(sIncludeScriptContents);

    if (nOldHash != nNewHash)
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Hash for '" + sInclude + "' Changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
        SetCampaignInt(GetModuleName() + "_EventSystemCore", sInclude, nNewHash);
        ES_Util_SetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "CoreHashChanged", TRUE);
    }

    if (sInclude == ES_CORE_SCRIPT_NAME)
    {
        ES_Core_CheckFunctionHash(sIncludeScriptContents, "ES_Core_SignalEvent");
    }
}

void ES_Core_CheckCoreHashes()
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_inc_.+", FALSE);

    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    ES_Util_StringArray_Clear(oDataObject, sIncludeArray);
}

void ES_Core_CheckNWNXHashes()
{
    object oDataObject = ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "nwnx_.+", FALSE);

    // Manually insert nwnx.nss
    ES_Util_StringArray_Insert(oDataObject, sIncludeArray, "nwnx");

    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    ES_Util_StringArray_Clear(oDataObject, sIncludeArray);
}

int ES_Core_GetCoreHashChanged()
{
    return ES_Util_GetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "CoreHashChanged");
}

int ES_Core_GetFunctionHashChanged(string sFunction)
{
    return ES_Util_GetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "FunctionHashChanged_" + sFunction);
}

// *****************************************************************************
// Shared Service/Subsystem Functions
void ES_Core_CompileEventHandler(string sScriptName, string sEventHandlerFunction)
{
    string sEventHandlerScriptChunk = nssFunction(sEventHandlerFunction, nssEscapeDoubleQuotes(sScriptName) + ", " + nssFunction("NWNX_Events_GetCurrentEvent", "", FALSE));
    string sResult = ES_Util_AddScript(sScriptName, sScriptName, sEventHandlerScriptChunk);

    if (sResult != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > ERROR: Failed to compile Event Handler for '" + sScriptName + "' with error: " + sResult);
    }
}

void ES_Core_GetFunctionByType(object oDataObject, string sScriptContents, string sType)
{
    string sFunction = ES_Util_GetFunctionName(sScriptContents, sType);
    ES_Util_Log(ES_CORE_LOG_TAG, "    > " + sType + " Function: " + (sFunction == "" ? "N/A" : sFunction + "()"));
    ES_Util_SetString(oDataObject, sType + "Function", sFunction);
}

void ES_Core_CheckHash(string sScriptName)
{
    object oDataObject = ES_Core_GetSystemObject(sScriptName);
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();
    int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sScriptName);
    int nNewHash = ES_Util_GetInt(oDataObject, "Hash");
    int bHashChanged = nOldHash != nNewHash;

    if (bHashChanged)
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "   > Hash for '" + sScriptName + "' has changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
        SetCampaignInt(GetModuleName() + "_EventSystemCore", sScriptName, nNewHash);
        ES_Util_SetInt(oDataObject, "HashChanged", bHashChanged);
    }

    string sEventHandlerFunction = ES_Util_GetString(oDataObject, "EventHandlerFunction");

    if (sEventHandlerFunction != "")
    {
        int bEventScriptExists = NWNX_Util_IsValidResRef(sScriptName, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bCoreHashChanged || !bEventScriptExists || bHashChanged)
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "     > " + (!bEventScriptExists ? "Compiling" : "Recompiling") + " Event Handler for: " + sScriptName);

            ES_Core_CompileEventHandler(sScriptName, sEventHandlerFunction);

            ES_Util_SetInt(oDataObject, "DidNotExist", !bEventScriptExists);
            ES_Util_SetInt(oDataObject, "HasBeenCompiled", TRUE);
        }

        ES_Util_SetInt(oDataObject, "HasEventHandler", TRUE);
    }
}

void ES_Core_ExecuteFunction(string sScriptName, string sType)
{
    object oDataObject = ES_Core_GetSystemObject(sScriptName);
    string sFunction = ES_Util_GetString(oDataObject, sType + "Function");

    if (sFunction != "")
    {
        if (!ES_Util_GetInt(oDataObject, "Disabled"))
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "  > Executing '" + sFunction + "()' for: " + sScriptName);

            string sResult = ES_Util_ExecuteScriptChunk(sScriptName, nssFunction(sFunction, nssEscapeDoubleQuotes(sScriptName)), GetModule());

            if (sResult != "")
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "    > ERROR: Function failed with error: " + sResult);
            }
        }
    }
}

// *****************************************************************************
// Service Functions
void ES_Core_Service_Load(string sService)
{
    ES_Util_Log(ES_CORE_LOG_TAG, "  > Loading Service: " + sService);

    object oDataObject = ES_Core_GetSystemObject(sService);
    string sScriptContents = NWNX_Util_GetNSSContents(sService);

    int bDisabled = FindSubString(ES_Util_GetString(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "DisabledServices"), sService) != -1;
    ES_Util_SetInt(oDataObject, "Disabled", bDisabled);

    int nHash = NWNX_Util_Hash(sScriptContents);
    ES_Util_Log(ES_CORE_LOG_TAG, "    > Hash: " + IntToString(nHash));
    ES_Util_SetInt(oDataObject, "Hash", nHash);

    ES_Core_GetFunctionByType(oDataObject, sScriptContents, "Init");
    ES_Core_GetFunctionByType(oDataObject, sScriptContents, "EventHandler");
    ES_Core_GetFunctionByType(oDataObject, sScriptContents, "Post");
}

// *****************************************************************************
// Subsystem Functions
string ES_Core_Subsystem_GetServices(string sSubsystem, string sScriptContents)
{
    string sServices;
    object oDataObject = ES_Core_GetSystemObject(sSubsystem);
    int nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", 0), nIncludeEnd;

    while (nIncludeStart != -1)
    {
        nIncludeEnd = FindSubString(sScriptContents, "\"", nIncludeStart + 10);

        string sService = GetSubString(sScriptContents, nIncludeStart + 10, nIncludeEnd - nIncludeStart - 10);

        if (GetStringLeft(sService, 7) == "es_srv_")
        {
            ES_Util_StringArray_Insert(oDataObject, "Services", sService);

            sServices += sService + " ";
        }

        nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", nIncludeEnd);
    }

    return sServices;
}

void ES_Core_Subsystem_Load(string sSubsystem)
{
    ES_Util_Log(ES_CORE_LOG_TAG, "  > Loading Subsystem: " + sSubsystem);

    object oDataObject = ES_Core_GetSystemObject(sSubsystem);
    string sScriptContents = NWNX_Util_GetNSSContents(sSubsystem);

    int bDisabled = FindSubString(ES_Util_GetString(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "DisabledSubsystems"), sSubsystem) != -1;
    ES_Util_SetInt(oDataObject, "Disabled", bDisabled);

    int nHash = NWNX_Util_Hash(sScriptContents);
    ES_Util_Log(ES_CORE_LOG_TAG, "    > Hash: " + IntToString(nHash));
    ES_Util_SetInt(oDataObject, "Hash", nHash);

    string sServices = ES_Core_Subsystem_GetServices(sSubsystem, sScriptContents);
    ES_Util_Log(ES_CORE_LOG_TAG, "    > Services: " + (sServices == "" ? "N/A" : sServices));

    ES_Core_GetFunctionByType(oDataObject, sScriptContents, "Init");
    ES_Core_GetFunctionByType(oDataObject, sScriptContents, "EventHandler");
}

void ES_Core_Subsystem_CheckServices(string sSubsystem)
{
    object oDataObject = ES_Core_GetSystemObject(sSubsystem);
    int bHasEventHandler = ES_Util_GetInt(oDataObject, "HasEventHandler");
    int bDidNotExist = ES_Util_GetInt(oDataObject, "DidNotExist");
    int bHasBeenCompiled = ES_Util_GetInt(oDataObject, "HasBeenCompiled");

    if (bHasEventHandler && !bDidNotExist && !bHasBeenCompiled)
    {
        int nNumServices = ES_Util_StringArray_Size(oDataObject, "Services"), nServiceIndex;

        if (nNumServices)
        {
            for (nServiceIndex = 0; nServiceIndex < nNumServices; nServiceIndex++)
            {
                string sService = ES_Util_StringArray_At(oDataObject, "Services", nServiceIndex);
                object oServiceDataObject = ES_Core_GetSystemObject(sService);

                if (ES_Util_GetInt(oServiceDataObject, "HashChanged"))
                {
                    ES_Util_Log(ES_CORE_LOG_TAG, "  > Services for Subsystem '" + sSubsystem + "' have changed, recompiling Event Handler");

                    string sEventHandlerFunction = ES_Util_GetString(oDataObject, "EventHandlerFunction");

                    ES_Core_CompileEventHandler(sSubsystem, sEventHandlerFunction);

                    break;
                }
            }
        }
    }
}

void ES_Core_Subsystem_CheckStatus(string sSubsystem)
{
    object oDataObject = ES_Core_GetSystemObject(sSubsystem);
    int nSubsystemDisabled = ES_Util_GetInt(oDataObject, "Disabled");

    ES_Util_Log(ES_CORE_LOG_TAG, "  * Checking: " + sSubsystem);

    if (!nSubsystemDisabled)
    {
        int nNumServices = ES_Util_StringArray_Size(oDataObject, "Services");

        if (nNumServices)
        {
            int nServiceIndex;
            string sDisabledServices;

            for (nServiceIndex = 0; nServiceIndex < nNumServices; nServiceIndex++)
            {
                string sService = ES_Util_StringArray_At(oDataObject, "Services", nServiceIndex);
                object oServiceDataObject = ES_Core_GetSystemObject(sService);

                if (ES_Util_GetInt(oServiceDataObject, "Disabled"))
                {
                    sDisabledServices += sService + " ";
                }
            }

            if (sDisabledServices != "")
            {
                nSubsystemDisabled = TRUE;
                ES_Util_SetInt(oDataObject, "Disabled", nSubsystemDisabled);
                ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Disabled Services: " + sDisabledServices);
            }
        }
    }

    ES_Util_Log(ES_CORE_LOG_TAG, "    > Status: " + (nSubsystemDisabled ? "Disabled" : "Enabled"));
}

// *****************************************************************************
// Object Event Functions
void ES_Core_CheckObjectEventScripts(int nStart, int nEnd)
{
    int bFunctionHashChanged = ES_Core_GetFunctionHashChanged("ES_Core_SignalEvent"), nEvent;

    for (nEvent = nStart; nEvent <= nEnd; nEvent++)
    {
        string sScriptName = "es_obj_e_" + IntToString(nEvent);
        int bObjectEventScriptExists = NWNX_Util_IsValidResRef(sScriptName, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bFunctionHashChanged || !bObjectEventScriptExists)
        {
            ES_Util_AddScript(sScriptName, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_SignalEvent", IntToString(nEvent)));
        }
    }
}

int ES_Core_GetEventFlags(int nEvent)
{
    return ES_Util_GetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME), "EventFlags_" + IntToString(nEvent));
}

void ES_Core_SetEventFlag(int nEvent, int nEventFlag)
{
    ES_Util_SetInt(ES_Util_GetDataObject(ES_CORE_SCRIPT_NAME),
                   "EventFlags_" + IntToString(nEvent),
                   ES_Core_GetEventFlags(nEvent) | nEventFlag);
}

// @FunctionStart ES_Core_SignalEvent
void ES_Core_SignalEvent(int nEvent, object oTarget = OBJECT_SELF)
{
    int nEventFlags = ES_Core_GetEventFlags(nEvent);
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), oTarget);

    // Run any old stored event scripts
    string sScript = ES_Util_GetString(oTarget, "ES_Core_OldEventScript_" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), oTarget);
}
// @FunctionEnd ES_Core_SignalEvent

// *****************************************************************************
// "Public" Core Functions
void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sNewScript = "es_obj_e_" + sEvent;

    SetEventScript(oObject, nEvent, sNewScript);

    if (bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        ES_Util_SetString(oObject, "ES_Core_OldEventScript_" + sEvent, sOldScript);
}

int ES_Core_GetEventFlagFromEvent(string sEvent)
{
    return StringToInt(GetStringRight(sEvent, 1));
}

string ES_Core_GetEventName_Object(int nEvent, int nEventFlag = ES_CORE_EVENT_FLAG_DEFAULT)
{
    return IntToString(nEvent) + "_OBJEVT_" + IntToString(nEventFlag);
}

void ES_Core_SubscribeEvent_Object(string sSubsystemScript, int nEvent, int nEventFlags = ES_CORE_EVENT_FLAG_DEFAULT, int bDispatchListMode = FALSE)
{
    string sEvent = IntToString(nEvent) + "_OBJEVT_";

    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_BEFORE);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sSubsystemScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_BEFORE), sSubsystemScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_DEFAULT);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sSubsystemScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), sSubsystemScript, bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_AFTER);

        NWNX_Events_SubscribeEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sSubsystemScript);

        if (bDispatchListMode)
            NWNX_Events_ToggleDispatchListMode(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), sSubsystemScript, bDispatchListMode);
    }
}

void ES_Core_SubscribeEvent_NWNX(string sSubsystemScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    NWNX_Events_SubscribeEvent(sNWNXEvent, sSubsystemScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sNWNXEvent, sSubsystemScript, bDispatchListMode);
}

