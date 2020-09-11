/*
    ScriptName: es_inc_core.nss
    Created by: Daz

    Description:

    Environment Variables:
        ES_DISABLE_CORE_COMPONENTS
        ES_DISABLE_SERVICES
        ES_DISABLE_SUBSYSTEMS
*/

//void main() {}

#include "es_inc_util"
#include "es_inc_effects"
#include "es_inc_test"
#include "es_inc_sqlite"
#include "es_inc_sqlocals"

const string ES_CORE_LOG_TAG                = "Core";
const string ES_CORE_SCRIPT_NAME            = "es_inc_core";

const int ES_CORE_COMPONENT_TYPE_CORE       = 1;
const int ES_CORE_COMPONENT_TYPE_SERVICE    = 2;
const int ES_CORE_COMPONENT_TYPE_SUBSYSTEM  = 3;

/* Internal Functions */
object ES_Core_GetCoreDataObject();
object ES_Core_GetComponentDataObject(string sComponent, int bCreateIfNotExists = TRUE);
void ES_Core_SetDBInt(string sVarName, int nValue, string sComponent = "");
int ES_Core_GetDBInt(string sVarName, string sComponent = "");

int ES_Core_GetCoreHashChanged();
int ES_Core_GetNWNXHashChanged(string sNWNXFile);
int ES_Core_GetComponentHashChanged(string sComponent);

void ES_Core_DisableComponent(string sComponent);
string ES_Core_Component_GetTypeNameFromType(int nType, int bPlural);
string ES_Core_Component_GetScriptPrefixFromType(int nType);
int ES_Core_Component_GetTypeFromScriptName(string sScriptName);
string ES_Core_Component_GetScriptFlags(string sScriptContents);
string ES_Core_Component_GetNWNXPluginDependencies(string sScriptContents);
string ES_Core_Component_GetNWNXScriptDependencies(string sComponent, string sScriptContents);
string ES_Core_Component_GetDependenciesByType(string sComponent, string sScriptContents, int nType);
void ES_Core_Component_GetFunctionByType(object oComponentDataObject, string sScriptContents, string sFunctionType);
void ES_Core_Component_ExecuteFunction(string sComponent, string sFunctionType, int bUseCachedScript = FALSE, int bForceExecute = FALSE);
void ES_Core_Component_ExecuteTestFunction(string sComponent);

void ES_Core_Init()
{
    ES_Util_Log(ES_CORE_LOG_TAG, "* Initializing EventSystem");

    ES_Util_Log(ES_CORE_LOG_TAG, "* Increasing Instruction Limit");
    // We do a lot of stuff, so increase the max instruction limit for the init function.
    // 64x Ought to be Enough for Anyone
    NWNX_Util_SetInstructionLimit(524288 * 64);

    object oModule = GetModule();
    object oCoreDataObject = ES_Core_GetCoreDataObject();

    SQLocals_CreateTable();

    // Check Core EventSystem Hashes
    ES_Util_Log(ES_CORE_LOG_TAG, "* Hash Check: Core");
    ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckCoreHashes"), oModule);

    // Check NWNX Hashes
    ES_Util_Log(ES_CORE_LOG_TAG, "* Hash Check: NWNX");
    ES_Util_ExecuteScriptChunk(ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckNWNXHashes"), oModule);

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

        // Initialize
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_Initialize", "sArrayElement, " + IntToString(nComponentType)), oModule);

        // Check NWNX Plugin Dependencies
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": NWNX Plugin Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckNWNXPluginDependencies", "sArrayElement"), oModule);

        // Check NWNX Script Dependencies
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": NWNX Script Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckNWNXScriptDependencies", "sArrayElement"), oModule);

        // Check EventSystem dependencies for Services/Subsystems
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

        // Check Event Handlers
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Event Handler Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckEventHandler", "sArrayElement"), oModule);

        // Execute Test Functions
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Running Tests");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_ExecuteTestFunction", "sArrayElement"), oModule);

        // Check Status
        ES_Util_Log(ES_CORE_LOG_TAG, "* " + sComponentTypeNamePlural + ": Status Check");
        ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sComponentsArray, ES_CORE_SCRIPT_NAME,
            nssFunction("ES_Core_Component_CheckStatus", "sArrayElement, " + IntToString(nComponentType)), oModule);

        // Execute Load Function
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

    // *** SUBSYSTEMS POST
    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Subsystems: Post");
    string sSubsystemsArray = GetLocalString(oCoreDataObject, "Subsystems");
    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sSubsystemsArray, ES_CORE_SCRIPT_NAME,
        nssFunction("ES_Core_Component_ExecuteFunction", "sArrayElement, " + nssEscapeDoubleQuotes("Post")), oModule);

    // Delete the CoreHashChanged variable so HotSwappable subsystems don't needlessly get recompiled
    DeleteLocalInt(oCoreDataObject, "CoreHashChanged");

    ES_Util_Log(ES_CORE_LOG_TAG, "");
    ES_Util_Log(ES_CORE_LOG_TAG, "* Resetting Instruction Limit");
    NWNX_Util_SetInstructionLimit(-1);

    ES_Util_Log(ES_CORE_LOG_TAG, "* Done!");
}

// *****************************************************************************
// Data Storage Functions

/*
- oCoreDataObject
  - CoreHashChanged (int)
  - Disabled{ComponentPlural} (string)

- oComponentDataObject
  - HashChanged (int)
  - NWNXScriptDependencies (StringArray)
  - {ComponentPlural} (StringArray)
  - {FunctionType}Function (string)
  - ScriptContents (string)
  - ManuallyDisabled (int)
  - NWNXPlugins (string)
  - MissingNWNXPlugins (int)
  - DepencencyHashChanged (int)
  - FailedToCompile (int)
  - Disabled (int)
  - Flags (string)
  - FailedToExecute{FunctionType} (int)
  - FailedTest
*/

object ES_Core_GetCoreDataObject()
{
    return ES_Util_GetDataObject("ESCore_" + ES_CORE_SCRIPT_NAME);
}

object ES_Core_GetComponentDataObject(string sComponent, int bCreateIfNotExists = TRUE)
{
    return ES_Util_GetDataObject("ESCoreComponent_" + sComponent, bCreateIfNotExists);
}

string ES_Core_GetDatabaseName()
{
    return ES_CORE_SCRIPT_NAME;
}

void ES_Core_SetDBInt(string sVarName, int nValue, string sComponent = "")
{
    sVarName = sComponent == "" ? sVarName : sComponent + "_" + sVarName;
    SetCampaignInt(ES_Core_GetDatabaseName(), sVarName , nValue);
}

int ES_Core_GetDBInt(string sVarName, string sComponent = "")
{
    sVarName = sComponent == "" ? sVarName : sComponent + "_" + sVarName;
    return GetCampaignInt(ES_Core_GetDatabaseName(), sVarName);
}

// *****************************************************************************
// Hash Check Helped Functions
struct ES_Core_HashCheck
{
    int nOldHash;
    int nNewHash;
    int bHashChanged;
};

struct ES_Core_HashCheck ES_Core_CheckHash(string sNSSFile, string sScriptContents = "")
{
    struct ES_Core_HashCheck hc;

    if (sScriptContents == "")
        sScriptContents = NWNX_Util_GetNSSContents(sNSSFile);

    hc.nOldHash = ES_Core_GetDBInt("Hash", sNSSFile);
    hc.nNewHash = NWNX_Util_Hash(sScriptContents);
    hc.bHashChanged = hc.nOldHash != hc.nNewHash;

    return hc;
}

// *****************************************************************************
// Core Hash Check Functions
void ES_Core_CheckCoreHash(string sNSSFile)
{
    struct ES_Core_HashCheck hc = ES_Core_CheckHash(sNSSFile);

    if (hc.bHashChanged)
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "   > Hash Changed: " + sNSSFile);

        ES_Core_SetDBInt("Hash", hc.nNewHash, sNSSFile);

        SetLocalInt(ES_Core_GetCoreDataObject(), "CoreHashChanged", TRUE);
    }
}

void ES_Core_CheckCoreHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "es_inc_.+", FALSE);

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckCoreHash", "sArrayElement"));
    StringArray_Clear(oCoreDataObject, sIncludeArray);
}

int ES_Core_GetCoreHashChanged()
{
    return GetLocalInt(ES_Core_GetCoreDataObject(), "CoreHashChanged") ||
           ES_Core_GetNWNXHashChanged("nwnx_util"); // nwnx_util.nss is used in es_inc_util
}

int ES_Core_GetComponentHashChanged(string sComponent)
{
    return GetLocalInt(ES_Core_GetComponentDataObject(sComponent), "HashChanged");
}

// *****************************************************************************
// NWNX Hash Check Functions
void ES_Core_CheckNWNXHash(string sNWNXFile)
{
    struct ES_Core_HashCheck hc = ES_Core_CheckHash(sNWNXFile);

    if (hc.bHashChanged)
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "   > Hash Changed: " + sNWNXFile);

        ES_Core_SetDBInt("Hash", hc.nNewHash, sNWNXFile);
        SetLocalInt(ES_Core_GetComponentDataObject(sNWNXFile), "HashChanged", TRUE);
    }
}

void ES_Core_CheckNWNXHashes()
{
    object oCoreDataObject = ES_Core_GetCoreDataObject();
    string sIncludeArray = ES_Util_GetResRefArray(oCoreDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "(?!nwnx_.+_t*)nwnx_.+", FALSE);

    // Manually insert nwnx.nss
    if (NWNX_Util_IsValidResRef("nwnx", NWNX_UTIL_RESREF_TYPE_NSS))
        StringArray_Insert(oCoreDataObject, sIncludeArray, "nwnx");

    ES_Util_ExecuteScriptChunkForArrayElements(oCoreDataObject, sIncludeArray, ES_CORE_SCRIPT_NAME, nssFunction("ES_Core_CheckNWNXHash", "sArrayElement"));
    StringArray_Clear(oCoreDataObject, sIncludeArray);
}

int ES_Core_GetNWNXHashChanged(string sNWNXFile)
{
    int bNWNXCoreHashChanged = GetLocalInt(ES_Core_GetComponentDataObject("nwnx"), "HashChanged");
    int bNWNXPluginHashChanged = GetLocalInt(ES_Core_GetComponentDataObject(sNWNXFile), "HashChanged");

    return bNWNXCoreHashChanged || bNWNXPluginHashChanged;
}

// *****************************************************************************
// Component Helper Functions
void ES_Core_DisableComponent(string sComponent)
{
    SetLocalInt(ES_Core_GetComponentDataObject(sComponent), "Disabled", TRUE);
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

string ES_Core_Component_GetScriptFlags(string sScriptContents)
{
    string sFlags;

    if (ES_Util_GetHasScriptFlag(sScriptContents, "HotSwap"))
        sFlags += "HotSwap ";

    return sFlags;
}

string ES_Core_Component_GetNWNXPluginDependencies(string sScriptContents)
{
    int nNWNXPluginsStart = FindSubString(sScriptContents, "@NWNX[", 0);
    int nNWNXPluginsEnd = FindSubString(sScriptContents, "]", nNWNXPluginsStart);

    if (nNWNXPluginsStart == -1 || nNWNXPluginsEnd == -1)
        return "";

    int nNWNXPluginsStartLength = GetStringLength("@NWNX[");

    return GetSubString(sScriptContents, nNWNXPluginsStart + nNWNXPluginsStartLength, nNWNXPluginsEnd - nNWNXPluginsStart - nNWNXPluginsStartLength);
}

string ES_Core_Component_GetNWNXScriptDependencies(string sComponent, string sScriptContents)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sNWNXDependencyScriptPrefix = "nwnx_";
    int nNWNXDependencyScriptPrefixLength = GetStringLength(sNWNXDependencyScriptPrefix);
    string sNWNXDependencies;

    int nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", 0), nIncludeEnd;

    while (nIncludeStart != -1)
    {
        nIncludeEnd = FindSubString(sScriptContents, "\"", nIncludeStart + 10);

        string sNWNXDependency = GetSubString(sScriptContents, nIncludeStart + 10, nIncludeEnd - nIncludeStart - 10);

        if (GetStringLeft(sNWNXDependency, nNWNXDependencyScriptPrefixLength) == sNWNXDependencyScriptPrefix)
        {
            StringArray_Insert(oComponentDataObject, "NWNXScriptDependencies", sNWNXDependency);

            sNWNXDependencies += sNWNXDependency + " ";
        }

        nIncludeStart = FindSubString(sScriptContents, "#" + "include \"", nIncludeEnd);
    }

    return sNWNXDependencies;
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

void ES_Core_Component_GetFunctionByType(object oComponentDataObject, string sScriptContents, string sFunctionType)
{
    string sFunction = ES_Util_GetFunctionName(sScriptContents, sFunctionType);

    if (sFunction != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "    > " + sFunctionType + " Function: " + sFunction + "()");
        SetLocalString(oComponentDataObject, sFunctionType + "Function", sFunction);
    }
}

void ES_Core_Component_ExecuteFunction(string sComponent, string sFunctionType, int bUseCachedScript = FALSE, int bForceExecute = FALSE)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sFunction = GetLocalString(oComponentDataObject, sFunctionType + "Function");

    if (sFunction != "")
    {
        if (bForceExecute || !GetLocalInt(oComponentDataObject, "Disabled"))
        {
            string sResult;

            SetScriptParam("SCRIPT_NAME", sComponent);

            if (bUseCachedScript)
            {
                string sCachedScript = GetLocalString(oComponentDataObject, "ScriptContents");
                string sScriptChunk = sCachedScript + " " + nssVoidMain(nssFunction(sFunction, nssEscapeDoubleQuotes(sComponent)));

                ES_Util_Log(ES_CORE_LOG_TAG, "  > Executing Cached " + sFunctionType + " Function '" + sFunction + "()' for: " + sComponent);

                sResult = ExecuteScriptChunk(sScriptChunk, GetModule(), FALSE);
            }
            else
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "  > Executing " + sFunctionType + " Function '" + sFunction + "()' for: " + sComponent);

                sResult = ES_Util_ExecuteScriptChunk(sComponent, nssFunction(sFunction, nssEscapeDoubleQuotes(sComponent)), GetModule());
            }

            if (sResult != "")
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "    > ERROR: Function failed with error: " + sResult);

                SetLocalInt(oComponentDataObject, "FailedToExecute" + sFunctionType, TRUE);

                ES_Core_DisableComponent(sComponent);
            }
        }
    }
}

void ES_Core_Component_ExecuteTestFunction(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sFunction = GetLocalString(oComponentDataObject, "TestFunction");

    if (sFunction != "")
    {
        object oModule = GetModule();

        ES_Util_Log(ES_CORE_LOG_TAG, "  > Executing Test Function '" + sFunction + "()' for: " + sComponent);

        int bResult = Test_ExecuteTestFunction(sComponent, sFunction);

        if (!bResult)
            SetLocalInt(oComponentDataObject, "FailedTest", TRUE);
    }
}

// *****************************************************************************
// Initialize Component Functions
void ES_Core_Component_Initialize(string sComponent, int nType)
{
    string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(nType, FALSE);
    string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);
    object oCoreDataObject = ES_Core_GetCoreDataObject();
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);

    ES_Util_Log(ES_CORE_LOG_TAG, "  > Initializing " + sComponentTypeName + ": " + sComponent);

    // Get the NSS Script Contents
    string sScriptContents = NWNX_Util_GetNSSContents(sComponent);
    SetLocalString(oComponentDataObject, "ScriptContents", sScriptContents);

    // Check Manually Disabled
    int bDisabled = FindSubString(GetLocalString(oCoreDataObject, "Disabled" + sComponentTypeNamePlural), sComponent) != -1;
    SetLocalInt(oComponentDataObject, "ManuallyDisabled", bDisabled);

    // Check hash
    struct ES_Core_HashCheck hc = ES_Core_CheckHash(sComponent, sScriptContents);

    if (hc.bHashChanged)
    {
        ES_Core_SetDBInt("Hash", hc.nNewHash, sComponent);
        SetLocalInt(oComponentDataObject, "HashChanged", TRUE);
    }

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

    // Get NWNX Script Dependencies
    string sNWNXScriptDependencies = ES_Core_Component_GetNWNXScriptDependencies(sComponent, sScriptContents);
    if (sNWNXScriptDependencies != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > NWNX Script Dependencies: " + sNWNXScriptDependencies);

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
    ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Test");

    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "EventHandler");

    if (nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Unload");

    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
        ES_Core_Component_GetFunctionByType(oComponentDataObject, sScriptContents, "Post");
}

void ES_Core_Component_CheckNWNXPluginDependencies(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sComponentType = ES_Core_Component_GetTypeNameFromType(ES_Core_Component_GetTypeFromScriptName(sComponent), FALSE);
    string sPlugins = GetLocalString(oComponentDataObject, "NWNXPlugins");

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

    if (sDisabledPlugins != "")
    {
        ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentType + " '" + sComponent + "' is missing required NWNX Plugins: " + sDisabledPlugins);

        SetLocalInt(oComponentDataObject, "MissingNWNXPlugins", TRUE);
    }
}

void ES_Core_Component_CheckNWNXScriptDependencies(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    int nNumNWNXScriptDependencies = StringArray_Size(oComponentDataObject, "NWNXScriptDependencies"), nNWNXScriptDependencyIndex;

    if (nNumNWNXScriptDependencies)
    {
        for (nNWNXScriptDependencyIndex = 0; nNWNXScriptDependencyIndex < nNumNWNXScriptDependencies; nNWNXScriptDependencyIndex++)
        {
            string sNWNXScriptDependency = StringArray_At(oComponentDataObject, "NWNXScriptDependencies", nNWNXScriptDependencyIndex);

            if (ES_Core_GetNWNXHashChanged(sNWNXScriptDependency))
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "  > NWNX Scripts for '" + sComponent + "' have changed");

                SetLocalInt(oComponentDataObject, "DependencyHashChanged", TRUE);

                break;
            }
        }
    }
}

void ES_Core_Component_CheckComponentDependenciesByType(string sComponent, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sComponentDependencyTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);

    int nNumComponentDependencies = StringArray_Size(oComponentDataObject, sComponentDependencyTypeNamePlural), nComponentDependencyIndex;

    if (nNumComponentDependencies)
    {
        for (nComponentDependencyIndex = 0; nComponentDependencyIndex < nNumComponentDependencies; nComponentDependencyIndex++)
        {
            string sComponentDependency = StringArray_At(oComponentDataObject, sComponentDependencyTypeNamePlural, nComponentDependencyIndex);
            object oComponentDependencyDataObject = ES_Core_GetComponentDataObject(sComponentDependency);

            if (GetLocalInt(oComponentDependencyDataObject, "HashChanged") || GetLocalInt(oComponentDependencyDataObject, "DependencyHashChanged"))
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentDependencyTypeNamePlural + " for '" + sComponent + "' have changed");

                SetLocalInt(oComponentDataObject, "DependencyHashChanged", TRUE);

                break;
            }
        }
    }
}

string ES_Core_GetCompileReason(string sComponent, object oComponentDataObject)
{
    string sReturn;

    if (!NWNX_Util_IsValidResRef(sComponent, NWNX_UTIL_RESREF_TYPE_NCS))
        sReturn = "File Does Not Exist";
    else if (ES_Core_GetDBInt("FailedToCompileLastRun", sComponent))
        sReturn = "Failed To Compile Last Run";
    else if (ES_Core_GetCoreHashChanged())
        sReturn = "Core Hash Changed";
    else if (GetLocalInt(oComponentDataObject, "DependencyHashChanged"))
        sReturn = "Dependency Hash Changed";
    else if (GetLocalInt(oComponentDataObject, "HashChanged"))
        sReturn = "Hash Changed";

    return sReturn;
}

void ES_Core_Component_CheckEventHandler(string sComponent)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    string sEventHandlerFunction = GetLocalString(oComponentDataObject, "EventHandlerFunction");

    if (sEventHandlerFunction != "")
    {
        string sCompileReason = ES_Core_GetCompileReason(sComponent, oComponentDataObject);

        if (sCompileReason != "")
        {
            ES_Util_Log(ES_CORE_LOG_TAG, "   > Compiling Event Handler for '" + sComponent + "' with reason: " + sCompileReason);

            string sEventHandlerScriptChunk = nssFunction(sEventHandlerFunction, nssEscapeDoubleQuotes(sComponent) + ", " + nssFunction("NWNX_Events_GetCurrentEvent", "", FALSE));
            string sResult = ES_Util_AddScript(sComponent, sComponent, sEventHandlerScriptChunk);

            if (sResult != "")
            {
                ES_Util_Log(ES_CORE_LOG_TAG, "     > ERROR: Failed to compile Event Handler for '" + sComponent + "' with error: " + sResult);

                SetLocalInt(oComponentDataObject, "FailedToCompile", TRUE);
                ES_Core_SetDBInt("FailedToCompileLastRun", TRUE, sComponent);
            }
            else
            {
                DeleteLocalInt(oComponentDataObject, "FailedToCompile");
                ES_Core_SetDBInt("FailedToCompileLastRun", FALSE, sComponent);
            }
        }
    }
}

struct ES_Core_ComponentStatus
{
    int nComponentType;
    string sFailedToExecuteLoadComponents;
    string sDisabledComponents;
    string sMissingComponents;
    int bDisable;
};

struct ES_Core_ComponentStatus ES_Core_GetStatusByType(object oComponentDataObject, int nComponentType)
{
    string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nComponentType, TRUE);
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

            if (GetLocalInt(oComponentDependencyDataObject, "FailedToExecuteLoad"))
            {
                cs.sFailedToExecuteLoadComponents += sComponentDependency + " ";
            }

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

    if (cs.sFailedToExecuteLoadComponents != "" || cs.sDisabledComponents != "" || cs.sMissingComponents != "")
        cs.bDisable = TRUE;

    return cs;
}

void ES_Core_Component_PrintStatus(struct ES_Core_ComponentStatus cs)
{
    string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(cs.nComponentType, FALSE);
    string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(cs.nComponentType, TRUE);

    if (cs.sFailedToExecuteLoadComponents != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > " + sComponentTypeName + " dependencies failed to Load: " + cs.sFailedToExecuteLoadComponents);

    if (cs.sDisabledComponents != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Disabled " + sComponentTypeNamePlural + ": " + cs.sDisabledComponents);

    if (cs.sMissingComponents != "")
        ES_Util_Log(ES_CORE_LOG_TAG, "    > Found Missing " + sComponentTypeNamePlural + ": " + cs.sMissingComponents);
}

void ES_Core_Component_CheckStatus(string sComponent, int nType)
{
    object oComponentDataObject = ES_Core_GetComponentDataObject(sComponent);
    int bManuallyDisabled = GetLocalInt(oComponentDataObject, "ManuallyDisabled");
    int bMissingNWNXPlugins = GetLocalInt(oComponentDataObject, "MissingNWNXPlugins");
    int bFailedToCompile = GetLocalInt(oComponentDataObject, "FailedToCompile");
    int bFailedTest = GetLocalInt(oComponentDataObject, "FailedTest");
    struct ES_Core_ComponentStatus csCoreComponents;
    struct ES_Core_ComponentStatus csServices;

    if (nType == ES_CORE_COMPONENT_TYPE_SERVICE || nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        csCoreComponents = ES_Core_GetStatusByType(oComponentDataObject, ES_CORE_COMPONENT_TYPE_CORE);
    }

    if (nType == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
    {
        csServices = ES_Core_GetStatusByType(oComponentDataObject, ES_CORE_COMPONENT_TYPE_SERVICE);
    }

    if (bManuallyDisabled || bMissingNWNXPlugins || bFailedToCompile || bFailedTest || csCoreComponents.bDisable || csServices.bDisable)
    {
        ES_Core_DisableComponent(sComponent);

        string sComponentTypeName = ES_Core_Component_GetTypeNameFromType(nType, FALSE);
        string sComponentTypeNamePlural = ES_Core_Component_GetTypeNameFromType(nType, TRUE);

        ES_Util_Log(ES_CORE_LOG_TAG, "  > " + sComponentTypeName + " '" + sComponent + "' was disabled, reasons:");

        if (bManuallyDisabled)
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Manually Disabled");

        if (bMissingNWNXPlugins)
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Missing NWNX Plugins");

        ES_Core_Component_PrintStatus(csCoreComponents);
        ES_Core_Component_PrintStatus(csServices);

        if (bFailedToCompile)
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Compilation Failure");

        if (bFailedTest)
            ES_Util_Log(ES_CORE_LOG_TAG, "    > Test Failure");
    }
}

