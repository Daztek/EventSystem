/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:

    Environment Variables:
        ES_SKIP_CORE_HASH_CHECK
        ES_SKIP_NWNX_HASH_CHECK
        ES_DISABLE_PROVIDERS
        ES_DISABLE_SERVICES
        ES_DISABLE_SUBSYSTEMS
*/

//void main() {}

#include "es_inc_util"

const string ES_CORE_LOG_TAG                = "Core";
const string ES_CORE_SCRIPT_NAME            = "es_inc_core";

const int ES_CORE_EVENT_FLAG_BEFORE         = 1;
const int ES_CORE_EVENT_FLAG_DEFAULT        = 2;
const int ES_CORE_EVENT_FLAG_AFTER          = 4;

const int ES_CORE_COMPONENT_TYPE_PROVIDER   = 1;
const int ES_CORE_COMPONENT_TYPE_SERVICE    = 2;
const int ES_CORE_COMPONENT_TYPE_SUBSYSTEM  = 3;

/* Internal Functions */
// INTERNAL FUNCTION: Returns the dataobject for the Core
object ES_Core_GetCoreDataObject();
// INTERNAL FUNCTION: Returns the dataobject for a component
object ES_Core_GetComponentDataObject(string sComponent, int bCreateIfNotExists = TRUE);
// INTERNAL FUNCTION
int ES_Core_GetCoreHashChanged();
// INTERNAL FUNCTION
int ES_Core_GetFunctionHashChanged(string sFunction);
// INTERNAL FUNCTION
void ES_Core_CheckObjectEventScripts(int nStart, int nEnd);
// INTERNAL FUNCTION: Subscribe sScript to sEvent.
// You probably want one of these instead:
//  - ES_Core_SubscribeEvent_Object()
//  - ES_Core_SubscribeEvent_NWNX();
void ES_Core_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode);
// INTERNAL FUNCTION
string ES_Core_Component_GetDisabledNWNXPlugins(string sPlugins);
// INTERNAL FUNCTION
string ES_Core_Component_GetTypeNameFromType(int nType, int bPlural);
// INTERNAL FUNCTION
string ES_Core_Component_GetScriptPrefixFromType(int nType);
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
// Unsubscribe sSubsystemScript from sEvent
void ES_Core_UnsubscribeEvent(string sSubsystemScript, string sEvent, int bClearDispatchList = FALSE);
// Unsubscribe sSubsystemScript from all its subscribed events
void ES_Core_UnsubscribeAllEvents(string sSubsystemScript, int bClearDispatchLists = FALSE);

void ES_Core_Init()
{
    string sCoreRequiredNWNXPlugins = "Events Object Util";
    string sDisabledPlugins = ES_Core_Component_GetDisabledNWNXPlugins(sCoreRequiredNWNXPlugins);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Checking Core NWNX Plugin Dependencies: " + sCoreRequiredNWNXPlugins);

    if (sDisabledPlugins != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > ERROR: Unable to initialize EventSystem: Missing Required NWNX Plugins: " + sDisabledPlugins);
        return;
    }

    ES_Util_Log(ES_CORE_LOG_TAG, "* Initializing EventSystem");

    ES_Util_Log(ES_CORE_LOG_TAG, "  > Increasing Instruction Limit");
    // We do a lot of stuff, so increase the max instruction limit for the init function and module load scripts.
    // 64x Ought to be Enough for Anyone
    NWNX_Util_SetInstructionLimit(524288 * 64);

    // We reset the instruction limit in the OnModuleLoad AFTER event
    ES_Util_AddScript(ES_CORE_SCRIPT_NAME, ES_CORE_SCRIPT_NAME,
        nssFunction("NWNX_Util_SetInstructionLimit", "-1") +
        nssFunction("ES_Util_Log", "ES_CORE_LOG_TAG, " + nssEscapeDoubleQuotes("* Instruction Limit Reset")) +
        nssFunction("NWNX_Util_RemoveNWNXResourceFile", "ES_CORE_SCRIPT_NAME, NWNX_UTIL_RESREF_TYPE_NCS") +
        nssFunction("ES_Core_UnsubscribeAllEvents", "ES_CORE_SCRIPT_NAME"));
    ES_Core_SubscribeEvent_Object(ES_CORE_SCRIPT_NAME, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD, ES_CORE_EVENT_FLAG_AFTER);


    object oModule = GetModule();
    object oCoreDataObject = ES_Core_GetCoreDataObject();


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


    // *** CHECK EVENT SCRIPTS
    ES_Util_Log(ES_CORE_LOG_TAG, "  > Checking Object Event Scripts");

    // Check if the module shutdown script is set to sShutdownScriptName
    string sShutdownScriptName = "es_obj_e_3018";
    if (NWNX_Util_GetEnvironmentVariable("NWNX_CORE_SHUTDOWN_SCRIPT") != sShutdownScriptName)
        ES_Util_Log(ES_CORE_LOG_TAG, "    > WARNING: NWNX environment variable 'NWNX_CORE_SHUTDOWN_SCRIPT' is not set to: " + sShutdownScriptName);

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


    // *** INITIALIZE COMPONENTS
    int nComponentType;
    for (nComponentType = ES_CORE_COMPONENT_TYPE_PROVIDER; nComponentType <= ES_CORE_COMPONENT_TYPE_SUBSYSTEM; nComponentType++)
    {
        string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nComponentType, TRUE);
        string sComponentScriptPrefix = ES_Core_Component_GetScriptPrefixFromType(nComponentType);

        ES_Util_Log(ES_CORE_LOG_TAG, "");
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Init");

        // Get an array of all the components of nComponentType
        string sComponentsArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, sComponentScriptPrefix + ".+", FALSE);
        SetLocalString(oCoreDataObject, sComponentTypeNamePlural, sComponentsArray);

        // Check if any components have been manually disabled
        string sDisabledComponents = NWNX_Util_GetEnvironmentVariable("ES_DISABLE_" + GetStringUpperCase(sComponentTypeNamePlural));
        if (sDisabledComponents != "")
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "  * Manually Disabled " + sComponentTypeNamePlural + ": " + sDisabledComponents);
            SetLocalString(oCoreDataObject, "Disabled" + sComponentTypeNamePlural, sDisabledComponents);
        }

        // Initialize all components of nComponentType
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_Initialize", "sArrayElement, " + IntToString(nComponentType)), oModule);

        // Check NWNX Plugin Dependencies of all components
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": NWNX Plugin Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckNWNXPluginDependencies", "sArrayElement"), oModule);

        // Check the hash of all components
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Hash Check");
        if (ES_Core_GetCoreHashChanged())
            ES_Util_Log(ES_CORE_LOG_TAG, "   > Core Hash Changed");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckHash", "sArrayElement"), oModule);

        // Check the dependencies of all services and subsystems
        if (nComponentType == ES_CORE_COMPONENT_TYPE_SERVICE || nComponentType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Providers Check");
            ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
                nssFunction("ES_Core_Component_CheckComponentDependenciesByType", "sArrayElement, ES_CORE_COMPONENT_TYPE_PROVIDER"), oModule);

            if (nComponentType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Services Check");
                ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
                    nssFunction("ES_Core_Component_CheckComponentDependenciesByType", "sArrayElement, ES_CORE_COMPONENT_TYPE_SERVICE"), oModule);
            }

            // Check the status of all components
            ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Status Check");
            ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
                nssFunction("ES_Core_Component_CheckStatus", "sArrayElement, " + IntToString(nComponentType)), oModule);
        }

        // Execute the Load Function of all components
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Load");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Load")), oModule);
    }


    // *** SERVICES POST
    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Services: Post");
    string sServicesArray = GetLocalString(oCoreDataObject, "Services");
    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sServicesArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_Component_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Post")), oModule);


    // Delete the CoreHashChanged variable so HotSwappable subsystems don't needlessly get recompiled
    DeleteLocalInt(oCoreDataObject, "CoreHashChanged");


    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Done!");
}

// *****************************************************************************
// Data Object Functions
object ES_Core_GetCoreDataObject()
{
    return ES_Util_GetDataObject("ES!Core!" + ES_CORE_SCRIPT_NAME);
}

object ES_Core_GetComponentDataObject(string sComponent, int bCreateIfNotExists = TRUE)
{
    return ES_Util_GetDataObject("ES!Core!Component!" + sComponent, bCreateIfNotExists);
}

// *****************************************************************************
// Core Functions
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
            SetLocalInt(ES_Core_GetCoreDataObject(), "FunctionHashChanged_" + sFunction, TRUE);
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
        SetLocalInt(ES_Core_GetCoreDataObject(), "CoreHashChanged", TRUE);
    }

    if (sInclude == ES_CORE_SCRIPT_NAME)
    {
        ES_Core_CheckFunctionHash(sIncludeScriptContents, "ES_Core_SignalEvent");
    }
}

void ES_Core_CheckCoreHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject(), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_inc_.+", FALSE);

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    ES_Util_StringArray_Clear(oCoreDataObject, sIncludeArray);
}

void ES_Core_CheckNWNXHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject(), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "(?!nwnx_.+_t*)nwnx_.+", FALSE);

    // Manually insert nwnx.nss
    ES_Util_StringArray_Insert(oCoreDataObject, sIncludeArray, "nwnx");

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    ES_Util_StringArray_Clear(oCoreDataObject, sIncludeArray);
}

int ES_Core_GetCoreHashChanged()
{
    return GetLocalInt(ES_Core_GetCoreDataObject(), "CoreHashChanged");
}

int ES_Core_GetFunctionHashChanged(string sFunction)
{
    return GetLocalInt(ES_Core_GetCoreDataObject(), "FunctionHashChanged_" + sFunction);
}

// *****************************************************************************
// Component Functions
void ES_Core_DisableComponent(string sComponent)
{
    SetLocalInt(ES_Core_GetComponentDataObject(sComponent), "Disabled", TRUE);
}

string ES_Core_Component_GetScriptFlags(string sScriptContents)
{
    string sFlags;

    if (ES_Util_GetHasScriptFlag(sScriptContents, "HotSwap"))
        sFlags += "HotSwap ";

    return sFlags;
}

string ES_Core_Component_GetTypeNameFromType(int nType, int bPlural)
{
    string sComponentTypeName;

    switch (nType)
    {
        case ES_CORE_COMPONENT_TYPE_PROVIDER:   sComponentTypeName = "Provider"; break;
        case ES_CORE_COMPONENT_TYPE_SERVICE:    sComponentTypeName = "Service"; break;
        case ES_CORE_COMPONENT_TYPE_SUBSYSTEM:  sComponentTypeName = "Subsystem"; break;
    }

    return bPlural ? sComponentTypeName + "s" : sComponentTypeName;
}

string ES_Core_Component_GetScriptPrefixFromType(int nType)
{
    string sComponentScriptPrefix;

    switch (nType)
    {
        case ES_CORE_COMPONENT_TYPE_PROVIDER:   sComponentScriptPrefix = "es_prv_"; break;
        case ES_CORE_COMPONENT_TYPE_SERVICE:    sComponentScriptPrefix = "es_srv_"; break;
        case ES_CORE_COMPONENT_TYPE_SUBSYSTEM:  sComponentScriptPrefix = "es_s_"; break;
    }

    return sComponentScriptPrefix;
}

void ES_Core_Component_ExecuteFunction(string sComponent, string sFunctionType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sFunction = GetLocalString(oComponentDataObject, sFunctionType + "Function");

    if (sFunction != "")
    {
        if (!GetLocalInt(oComponentDataObject, "Disabled"))
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "  > Executing '" + sFunction + "()' for: " + sComponent);

            string sResult = ES_Util_ExecuteScriptChunk(sComponent, nssFunction(sFunction, nssEscapeDoubleQuotes(sComponent)), GetModule());

            if (sResult != "")
                ES_Util_Log(ES_CORE_LOG_TAG, "    > ERROR: Function failed with error: " + sResult);
        }
    }
}

string ES_Core_Component_GetDisabledNWNXPlugins(string sPlugins)
{
    if (sPlugins != "" && GetStringRight(sPlugins, 1) != " ")
        sPlugins += " ";

    int nPluginStart, nPluginEnd = FindSubString(sPlugins, " ", nPluginStart);
    string sDisabledPlugins;

    while (nPluginEnd != -1)
    {
        string sPlugin = GetSubString(sPlugins, nPluginStart, nPluginEnd - nPluginStart);
        int bPluginExists = NWNX_Util_PluginExists("NWNX_" + sPlugin);

        if (!bPluginExists)
            sDisabledPlugins += sPlugin + " ";

        nPluginStart = nPluginEnd + 1;
        nPluginEnd = FindSubString(sPlugins, " ", nPluginStart);
    }

    return sDisabledPlugins;
}

string ES_Core_Component_GetNWNXPluginDependencies(string sScriptContents)
{
    int nNWNXPluginsStart = FindSubString(sScriptContents, "@NWNX[", 0);
    int nNWNXPluginsEnd = FindSubString(sScriptContents, "]", nNWNXPluginsStart);

    if (nNWNXPluginsStart == -1 || nNWNXPluginsEnd == -1)
        return "";

    int nNWNXPluginsStartLength = GetStringLength("@NWNX[");

    string sPlugins = GetSubString(sScriptContents, nNWNXPluginsStart + nNWNXPluginsStartLength, nNWNXPluginsEnd - nNWNXPluginsStart - nNWNXPluginsStartLength);

    return sPlugins;
}

void ES_Core_Component_CheckNWNXPluginDependencies(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sNWNXPlugins = GetLocalString(oComponentDataObject, "NWNXPlugins");

    string sDisabledNWNXPlugins = ES_Core_Component_GetDisabledNWNXPlugins(sNWNXPlugins);

    if (sDisabledNWNXPlugins != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > Disabling '" + sComponent + "', missing required NWNX Plugins: " + sDisabledNWNXPlugins);

        SetLocalInt(oComponentDataObject, "Disabled", TRUE);
    }
}

string ES_Core_Component_GetDependenciesByType(string sComponent, string sScriptContents, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sComponentDependencyTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);
    string sComponentDependencyScriptPrefix = ES_Core_Component_GetScriptPrefixFromType(nType);
    int nComponentDependencyScriptPrefixLength = GetStringLength(sComponentDependencyScriptPrefix);
    string sComponentDependencies;

    int nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", 0), nIncludeEnd;

    while (nIncludeStart != -1)
    {
        nIncludeEnd = FindSubString(sScriptContents, "\"", nIncludeStart + 10);

        string sComponentDependency = GetSubString(sScriptContents, nIncludeStart + 10, nIncludeEnd - nIncludeStart - 10);

        if (GetStringLeft(sComponentDependency, nComponentDependencyScriptPrefixLength) == sComponentDependencyScriptPrefix)
        {
            ES_Util_StringArray_Insert(oComponentDataObject, sComponentDependencyTypeNamePlural, sComponentDependency);

            sComponentDependencies += sComponentDependency + " ";
        }

        nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", nIncludeEnd);
    }

    return sComponentDependencies;
}

void ES_Core_Component_CompileEventHandler(string sComponent, string sEventHandlerFunction)
{
    string sEventHandlerScriptChunk = nssFunction(sEventHandlerFunction, nssEscapeDoubleQuotes(sComponent) + ", " + nssFunction("NWNX_Events_GetCurrentEvent", "", FALSE));
    string sResult = ES_Util_AddScript(sComponent, sComponent, sEventHandlerScriptChunk);

    if (sResult != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > ERROR: Failed to compile Event Handler for '" + sComponent + "' with error: " + sResult, FALSE);
}

void ES_Core_Component_GetFunctionByType(object oComponentDataObject, string sScriptContents, string sFunctionType)
{
    string sFunction = ES_Util_GetFunctionName(sScriptContents, sFunctionType);

    if (sFunction != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > " + sFunctionType + " Function: " + sFunction + "()");
        SetLocalString(oComponentDataObject, sFunctionType + "Function", sFunction);
    }
}

void ES_Core_Component_Initialize(string sComponent, int nType)
{
    string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(nType, FALSE);
    string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);
    object oCoreDataObject = ES_Core_GetCoreDataObject();
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sScriptContents = NWNX_Util_GetNSSContents(sComponent);

    ES_Util_Log(ES_CORE_LOG_TAG, "  > Initializing " + sComponentTypeName + ": " + sComponent);

    // Check Manually Disabled
    int bDisabled = FindSubString(GetLocalString(oCoreDataObject, "Disabled" + sComponentTypeNamePlural), sComponent) != -1;
    SetLocalInt(oComponentDataObject, "Disabled", bDisabled);

    // Get hash
    int nHash = NWNX_Util_Hash(sScriptContents);
    ES_Util_Log(ES_CORE_LOG_TAG, "    > Hash: " + IntToString(nHash));
    SetLocalInt(oComponentDataObject, "Hash", nHash);

    // Get Script Flags
    string sFlags = ES_Core_Component_GetScriptFlags(sScriptContents);
    if (sFlags != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Flags: " + sFlags);
        SetLocalString(oComponentDataObject, "Flags", sFlags);
    }

    // Get NWNX Plugin Dependencies
    string sNWNXPlugins = ES_Core_Component_GetNWNXPluginDependencies(sScriptContents);
    if (sNWNXPlugins != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > NWNX Plugins: " + sNWNXPlugins);
        SetLocalString(oComponentDataObject, "NWNXPlugins", sNWNXPlugins);
    }

    // Get Provider Dependencies for Services and Subsystems
    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        string sProviders = ES_Core_Component_GetDependenciesByType(sComponent, sScriptContents, ES_CORE_COMPONENT_TYPE_PROVIDER);
        if (sProviders != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Providers: " + sProviders);
    }

    // Get Service Dependencies for Subsystems
    if (nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        string sServices = ES_Core_Component_GetDependenciesByType(sComponent, sScriptContents, ES_CORE_COMPONENT_TYPE_SERVICE);
        if (sServices != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Services: " + sServices);
    }

    // Get Functions
    ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Load");

    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "EventHandler");
    }

    if (nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Unload");
    }

    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE)
    {
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Post");
    }
}

void ES_Core_Component_CheckStatus(string sComponent, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(nType, FALSE);

    int nComponentDisabled = GetLocalInt(oComponentDataObject, "Disabled");

    string sDisabledProviders, sMissingProviders;
    string sDisabledServices, sMissingServices;

    if (!nComponentDisabled)
    {
        int nNumProviders = ES_Util_StringArray_Size(oComponentDataObject, "Providers");

        if (nNumProviders)
        {
            int nProviderIndex;

            for (nProviderIndex = 0; nProviderIndex < nNumProviders; nProviderIndex++)
            {
                string sProvider = ES_Util_StringArray_At(oComponentDataObject, "Providers", nProviderIndex);
                object oProviderDataObject = ES_Core_GetComponentDataObject(sProvider);

                if (GetLocalInt(oProviderDataObject, "Disabled"))
                {
                    sDisabledProviders += sProvider + " ";
                }

                if (!NWNX_Util_IsValidResRef(sProvider, NWNX_UTIL_RESREF_TYPE_NSS))
                {
                    sMissingProviders += sProvider + " ";
                }
            }

            if (sDisabledProviders != "")
            {
                nComponentDisabled = TRUE;
                SetLocalInt(oComponentDataObject, "Disabled", nComponentDisabled);
            }

            if (sMissingProviders != "")
            {
                nComponentDisabled = TRUE;
                SetLocalInt(oComponentDataObject, "Disabled", nComponentDisabled);
            }
        }

        int nNumServices = ES_Util_StringArray_Size(oComponentDataObject, "Services");

        if (nNumServices)
        {
            int nServiceIndex;

            for (nServiceIndex = 0; nServiceIndex < nNumServices; nServiceIndex++)
            {
                string sService = ES_Util_StringArray_At(oComponentDataObject, "Services", nServiceIndex);
                object oServiceDataObject = ES_Core_GetComponentDataObject(sService);

                if (GetLocalInt(oServiceDataObject, "Disabled"))
                {
                    sDisabledServices += sService + " ";
                }

                if (!NWNX_Util_IsValidResRef(sService, NWNX_UTIL_RESREF_TYPE_NSS))
                {
                    sMissingServices += sService + " ";
                }
            }

            if (sDisabledServices != "")
            {
                nComponentDisabled = TRUE;
                SetLocalInt(oComponentDataObject, "Disabled", nComponentDisabled);
            }

            if (sMissingServices != "")
            {
                nComponentDisabled = TRUE;
                SetLocalInt(oComponentDataObject, "Disabled", nComponentDisabled);
            }
        }
    }

    if (nComponentDisabled)
    {
        if (sDisabledServices == "" && sMissingServices == "" && sDisabledProviders == "" && sMissingProviders == "")
            ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentTypeName + " '" + sComponent + "' -> Manually Disabled");
        else
            ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentTypeName + " '" + sComponent + "' -> Disabled");

        if (sDisabledProviders != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Disabled Providers: " + sDisabledProviders);

        if (sMissingProviders != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Missing Providers: " + sMissingProviders);

        if (sDisabledServices != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Disabled Services: " + sDisabledServices);

        if (sMissingServices != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Missing Services: " + sMissingServices);
    }
}

void ES_Core_Component_CheckComponentDependenciesByType(string sComponent, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sComponentDependencyTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);
    int bHasEventHandler = GetLocalInt(oComponentDataObject, "HasEventHandler");
    int bDidNotExist = GetLocalInt(oComponentDataObject, "DidNotExist");
    int bHasBeenCompiled = GetLocalInt(oComponentDataObject, "HasBeenCompiled");

    if (bHasEventHandler && !bDidNotExist && !bHasBeenCompiled)
    {
        int nNumComponentDependencies = ES_Util_StringArray_Size(oComponentDataObject, sComponentDependencyTypeNamePlural), nComponentDependencyIndex;

        if (nNumComponentDependencies)
        {
            for (nComponentDependencyIndex = 0; nComponentDependencyIndex < nNumComponentDependencies; nComponentDependencyIndex++)
            {
                string sComponentDependency = ES_Util_StringArray_At(oComponentDataObject, sComponentDependencyTypeNamePlural, nComponentDependencyIndex);
                object oComponentDependencyDataObject = ES_Core_GetComponentDataObject(sComponentDependency);

                if (GetLocalInt(oComponentDependencyDataObject, "HashChanged"))
                {
                    ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentDependencyTypeNamePlural + " for '" + sComponent + "' have changed, recompiling Event Handler");

                    string sEventHandlerFunction = GetLocalString(oComponentDataObject, "EventHandlerFunction");

                    ES_Core_Component_CompileEventHandler(sComponent, sEventHandlerFunction);

                    break;
                }
            }
        }
    }
}

void ES_Core_Component_CheckHash(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    int bCoreHashChanged = ES_Core_GetCoreHashChanged();
    int nOldHash = GetCampaignInt(GetModuleName() + "_EventSystemCore", sComponent);
    int nNewHash = GetLocalInt(oComponentDataObject, "Hash");
    int bHashChanged = nOldHash != nNewHash;

    if (bHashChanged)
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "   > Hash for '" + sComponent + "' has changed -> Old: " + IntToString(nOldHash) + ", New: " + IntToString(nNewHash));
        SetCampaignInt(GetModuleName() + "_EventSystemCore", sComponent, nNewHash);
        SetLocalInt(oComponentDataObject, "HashChanged", bHashChanged);
    }

    string sEventHandlerFunction = GetLocalString(oComponentDataObject, "EventHandlerFunction");

    if (sEventHandlerFunction != "")
    {
        int bEventScriptExists = NWNX_Util_IsValidResRef(sComponent, NWNX_UTIL_RESREF_TYPE_NCS);

        if (bCoreHashChanged || !bEventScriptExists || bHashChanged)
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "     > " + (!bEventScriptExists ? "Compiling" : "Recompiling") + " Event Handler for: " + sComponent);

            ES_Core_Component_CompileEventHandler(sComponent, sEventHandlerFunction);

            SetLocalInt(oComponentDataObject, "DidNotExist", !bEventScriptExists);
            SetLocalInt(oComponentDataObject, "HasBeenCompiled", TRUE);
        }

        SetLocalInt(oComponentDataObject, "HasEventHandler", TRUE);
    }
}

// *****************************************************************************
// Event Functions
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
    return GetLocalInt(ES_Core_GetCoreDataObject(), "EventFlags_" + IntToString(nEvent));
}

void ES_Core_SetEventFlag(int nEvent, int nEventFlag)
{
    SetLocalInt(ES_Core_GetCoreDataObject(),
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
    string sScript = GetLocalString(oTarget, "ES!Core!OldEventScript!" + IntToString(nEvent));
    if (sScript != "") ExecuteScript(sScript, oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_DEFAULT), oTarget);

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
        NWNX_Events_SignalEvent(sEvent + IntToString(ES_CORE_EVENT_FLAG_AFTER), oTarget);
}
// @FunctionEnd ES_Core_SignalEvent

void ES_Core_SubscribeEvent(string sScript, string sEvent, int bDispatchListMode)
{
    object oDataObject = ES_Util_GetDataObject(sScript);

    ES_Util_StringArray_Insert(oDataObject, "SubscribedEvents", sEvent);

    NWNX_Events_SubscribeEvent(sEvent, sScript);

    if (bDispatchListMode)
        NWNX_Events_ToggleDispatchListMode(sEvent, sScript, bDispatchListMode);
}

// *****************************************************************************
// "Public" Core Functions
void ES_Core_SetObjectEventScript(object oObject, int nEvent, int bStoreOldEvent = TRUE)
{
    string sEvent = IntToString(nEvent);
    string sOldScript = GetEventScript(oObject, nEvent);
    string sNewScript = "es_obj_e_" + sEvent;

    int bSet = SetEventScript(oObject, nEvent, sNewScript);

    if (bSet && bStoreOldEvent && sOldScript != "" && sOldScript != sNewScript)
        SetLocalString(oObject, "ES!Core!OldEventScript!" + sEvent, sOldScript);
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
    if (nEventFlags & ES_CORE_EVENT_FLAG_BEFORE)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_BEFORE);
        ES_Core_SubscribeEvent(sSubsystemScript, ES_Core_GetEventName_Object(nEvent, ES_CORE_EVENT_FLAG_BEFORE), bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_DEFAULT)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_DEFAULT);
        ES_Core_SubscribeEvent(sSubsystemScript, ES_Core_GetEventName_Object(nEvent, ES_CORE_EVENT_FLAG_DEFAULT), bDispatchListMode);
    }

    if (nEventFlags & ES_CORE_EVENT_FLAG_AFTER)
    {
        ES_Core_SetEventFlag(nEvent, ES_CORE_EVENT_FLAG_AFTER);
        ES_Core_SubscribeEvent(sSubsystemScript, ES_Core_GetEventName_Object(nEvent, ES_CORE_EVENT_FLAG_AFTER), bDispatchListMode);
    }
}

void ES_Core_SubscribeEvent_NWNX(string sSubsystemScript, string sNWNXEvent, int bDispatchListMode = FALSE)
{
    ES_Core_SubscribeEvent(sSubsystemScript, sNWNXEvent, bDispatchListMode);
}

void ES_Core_UnsubscribeEvent(string sSubsystemScript, string sEvent, int bClearDispatchList = FALSE)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);

    ES_Util_StringArray_DeleteByValue(oDataObject, "SubscribedEvents", sEvent);

    NWNX_Events_UnsubscribeEvent(sEvent, sSubsystemScript);

    if (bClearDispatchList)
        NWNX_Events_ToggleDispatchListMode(sEvent, sSubsystemScript, FALSE);
}

void ES_Core_UnsubscribeAllEvents(string sSubsystemScript, int bClearDispatchLists = FALSE)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);

    int nNumEvents = ES_Util_StringArray_Size(oDataObject, "SubscribedEvents"), nIndex;

    for (nIndex = 0; nIndex < nNumEvents; nIndex++)
    {
        string sEvent = ES_Util_StringArray_At(oDataObject, "SubscribedEvents", nIndex);

        NWNX_Events_UnsubscribeEvent(sEvent, sSubsystemScript);

        if (bClearDispatchLists)
            NWNX_Events_ToggleDispatchListMode(sEvent, sSubsystemScript, FALSE);
    }

    ES_Util_StringArray_Clear(oDataObject, "SubscribedEvents");
}

