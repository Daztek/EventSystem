/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:

    Environment Variables:
        ES_SKIP_CORE_HASH_CHECK
        ES_SKIP_NWNX_HASH_CHECK
        ES_DISABLE_CORE_COMPONENTS
        ES_DISABLE_SERVICES
        ES_DISABLE_SUBSYSTEMS
*/

//void main() {}

#include "es_inc_util"

const string ES_CORE_LOG_TAG                = "Core";
const string ES_CORE_SCRIPT_NAME            = "es_inc_core";

const int ES_CORE_COMPONENT_TYPE_CORE       = 1;
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
string ES_Core_Component_GetDisabledNWNXPlugins(string sPlugins);
// INTERNAL FUNCTION
string ES_Core_Component_GetTypeNameFromType(int nType, int bPlural);
// INTERNAL FUNCTION
string ES_Core_Component_GetScriptPrefixFromType(int nType);
// INTERNAL FUNCTION
int ES_Core_Component_GetTypeFromScriptName(string sScriptName);

void ES_Core_Init()
{
    /* Not really useful at the moment...
    string sCoreRequiredNWNXPlugins = "Util";
    string sDisabledPlugins = ES_Core_Component_GetDisabledNWNXPlugins(sCoreRequiredNWNXPlugins);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Checking Core NWNX Plugin Dependencies: " + sCoreRequiredNWNXPlugins);

    if (sDisabledPlugins != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > ERROR: Unable to initialize EventSystem: Missing Required NWNX Plugins: " + sDisabledPlugins);
        return;
    }
    */

    ES_Util_Log(ES_CORE_LOG_TAG, "* Initializing EventSystem");

    ES_Util_Log(ES_CORE_LOG_TAG, "* Increasing Instruction Limit");
    // We do a lot of stuff, so increase the max instruction limit for the init function.
    // 64x Ought to be Enough for Anyone
    NWNX_Util_SetInstructionLimit(524288 * 64);

    object oModule = GetModule();
    object oCoreDataObject = ES_Core_GetCoreDataObject();

    // This checks if any of the es_inc_* NSS files have changed
    // Can be disabled by setting the ES_SKIP_CORE_HASH_CHECK environment variable to true
    if (!ES_Util_GetBooleanEnvVar("ES_SKIP_CORE_HASH_CHECK"))
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "* Checking Core Hashes");
        ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckCoreHashes"), oModule);
    }
    else
        ES_Util_Log(ES_CORE_LOG_TAG, "* WARNING: Skipping Core Hash Check");

    // This checks if any of the nwnx_* NSS files have changed
    // Can be disabled by setting the ES_SKIP_NWNX_HASH_CHECK environment variable to true
    if (!ES_Util_GetBooleanEnvVar("ES_SKIP_NWNX_HASH_CHECK"))
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "* Checking NWNX Hashes");
        ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckNWNXHashes"), oModule);
    }
    else
        ES_Util_Log(ES_CORE_LOG_TAG, "* WARNING: Skipping NWNX Hash Check");

    // *** INITIALIZE COMPONENTS
    int nComponentType;
    for (nComponentType = ES_CORE_COMPONENT_TYPE_CORE; nComponentType <= ES_CORE_COMPONENT_TYPE_SUBSYSTEM; nComponentType++)
    {
        string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nComponentType, TRUE);
        string sComponentScriptPrefix = ES_Core_Component_GetScriptPrefixFromType(nComponentType);

        ES_Util_Log(ES_CORE_LOG_TAG, "");
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Init");

        // Get an array of all the components of nComponentType
        string sComponentsArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, sComponentScriptPrefix + ".+", FALSE);
        SetLocalString(oCoreDataObject, sComponentTypeNamePlural, sComponentsArray);

        // Check if any components have been manually disabled
        string sDisabledComponents = NWNX_Util_GetEnvironmentVariable("ES_DISABLE_" + StringReplace(GetStringUpperCase(sComponentTypeNamePlural), " ", "_"));
        if (sDisabledComponents != "")
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "  > Manually Disabled " + sComponentTypeNamePlural + ": " + sDisabledComponents);
            SetLocalString(oCoreDataObject, "Disabled" + sComponentTypeNamePlural, sDisabledComponents);
        }

        // Initialize all components
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
            ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Core Components Check");
            ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
                nssFunction("ES_Core_Component_CheckComponentDependenciesByType", "sArrayElement, ES_CORE_COMPONENT_TYPE_CORE"), oModule);

            if (nComponentType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Services Check");
                ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
                    nssFunction("ES_Core_Component_CheckComponentDependenciesByType", "sArrayElement, ES_CORE_COMPONENT_TYPE_SERVICE"), oModule);
            }
        }

        // Check the status of all components
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Status Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckStatus", "sArrayElement, " + IntToString(nComponentType)), oModule);

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
    ES_Util_Log(ES_CORE_LOG_TAG, "* Resetting Instruction Limit");
    NWNX_Util_SetInstructionLimit(-1);

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
}

void ES_Core_CheckCoreHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject(), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_inc_.+", FALSE);

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    StringArray_Clear(oCoreDataObject, sIncludeArray);
}

void ES_Core_CheckNWNXHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject(), oModule = GetModule();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "(?!nwnx_.+_t*)nwnx_.+", FALSE);

    // Manually insert nwnx.nss
    StringArray_Insert(oCoreDataObject, sIncludeArray, "nwnx");

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckIncludeHash", "sArrayElement"), oModule);
    StringArray_Clear(oCoreDataObject, sIncludeArray);
}

int ES_Core_GetCoreHashChanged()
{
    return GetLocalInt(ES_Core_GetCoreDataObject(), "CoreHashChanged");
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
        case ES_CORE_COMPONENT_TYPE_CORE:       sComponentTypeName = "Core Component"; break;
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
        case ES_CORE_COMPONENT_TYPE_CORE:       sComponentScriptPrefix = "es_cc_"; break;
        case ES_CORE_COMPONENT_TYPE_SERVICE:    sComponentScriptPrefix = "es_srv_"; break;
        case ES_CORE_COMPONENT_TYPE_SUBSYSTEM:  sComponentScriptPrefix = "es_s_"; break;
    }

    return sComponentScriptPrefix;
}

int ES_Core_Component_GetTypeFromScriptName(string sScriptName)
{
    int nComponentType;
    for (nComponentType = ES_CORE_COMPONENT_TYPE_CORE; nComponentType <= ES_CORE_COMPONENT_TYPE_SUBSYSTEM; nComponentType++)
    {
        string sScriptPrefix = ES_Core_Component_GetScriptPrefixFromType(nComponentType);
        if (GetStringLeft(sScriptName, GetStringLength(sScriptPrefix)) == sScriptPrefix)
            return nComponentType;
    }

    return 0;
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
            StringArray_Insert(oComponentDataObject, sComponentDependencyTypeNamePlural, sComponentDependency);

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

    // Get Core Component Dependencies for Services and Subsystems
    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        string sCoreComponents = ES_Core_Component_GetDependenciesByType(sComponent, sScriptContents, ES_CORE_COMPONENT_TYPE_CORE);
        if (sCoreComponents != "")
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Core Components: " + sCoreComponents);
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

struct ES_Core_ComponentStatus
{
    int nComponentType;
    string sDisabledComponents;
    string sMissingComponents;
    int bDisable;
};

struct ES_Core_ComponentStatus ES_Core_GetStatusByType(object oComponentDataObject, int nComponentType)
{
    string sComponentTypeNamePlural =  ES_Core_Component_GetTypeNameFromType(nComponentType, TRUE);
    struct ES_Core_ComponentStatus cs;
    cs.nComponentType = nComponentType;

    int nNumComponentDependencies = StringArray_Size(oComponentDataObject, sComponentTypeNamePlural);

    if (nNumComponentDependencies)
    {
        int nComponentDependencyIndex;

        for (nComponentDependencyIndex = 0; nComponentDependencyIndex < nNumComponentDependencies; nComponentDependencyIndex++)
        {
            string sComponentDependency = StringArray_At(oComponentDataObject, sComponentTypeNamePlural, nComponentDependencyIndex);
            object oComponentDependencyDataObject = ES_Core_GetComponentDataObject(sComponentDependency);

            if (GetLocalInt(oComponentDependencyDataObject, "Disabled"))
            {
                cs.sDisabledComponents += sComponentDependency + " ";
            }

            if (!NWNX_Util_IsValidResRef(sComponentDependency, NWNX_UTIL_RESREF_TYPE_NSS))
            {
                cs.sMissingComponents += sComponentDependency + " ";
            }
        }
    }

    if (cs.sDisabledComponents != "" || cs.sMissingComponents != "")
        cs.bDisable = TRUE;

    return cs;
}

void ES_Core_Component_PrintStatus(struct ES_Core_ComponentStatus cs)
{
    string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(cs.nComponentType, TRUE);

    if (cs.sDisabledComponents != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Disabled " + sComponentTypeNamePlural + ": " + cs.sDisabledComponents);

    if (cs.sMissingComponents != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Missing " + sComponentTypeNamePlural + ": " + cs.sMissingComponents);
}

void ES_Core_Component_CheckStatus(string sComponent, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    int nComponentDisabled = GetLocalInt(oComponentDataObject, "Disabled");
    struct ES_Core_ComponentStatus csCoreComponents;
    struct ES_Core_ComponentStatus csServices;

    if (!nComponentDisabled)
    {
        if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        {
            csCoreComponents = ES_Core_GetStatusByType(oComponentDataObject, ES_CORE_COMPONENT_TYPE_CORE);
        }

        if (nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        {
            csServices = ES_Core_GetStatusByType(oComponentDataObject, ES_CORE_COMPONENT_TYPE_SERVICE);
        }

        if (csCoreComponents.bDisable || csServices.bDisable)
            nComponentDisabled = TRUE;
    }

    if (nComponentDisabled)
    {
        SetLocalInt(oComponentDataObject, "Disabled", nComponentDisabled);

        string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(nType, FALSE);
        string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);

        if (FindSubString(GetLocalString(ES_Core_GetCoreDataObject(), "Disabled" + sComponentTypeNamePlural), sComponent) != -1)
            ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentTypeName + " '" + sComponent + "' -> Manually Disabled");
        else
            ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentTypeName + " '" + sComponent + "' -> Disabled");

        ES_Core_Component_PrintStatus(csCoreComponents);
        ES_Core_Component_PrintStatus(csServices);
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
        int nNumComponentDependencies = StringArray_Size(oComponentDataObject, sComponentDependencyTypeNamePlural), nComponentDependencyIndex;

        if (nNumComponentDependencies)
        {
            for (nComponentDependencyIndex = 0; nComponentDependencyIndex < nNumComponentDependencies; nComponentDependencyIndex++)
            {
                string sComponentDependency = StringArray_At(oComponentDataObject, sComponentDependencyTypeNamePlural, nComponentDependencyIndex);
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

