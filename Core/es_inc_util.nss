/*
    ScriptName: es_inc_util.nss
    Created by: Daz

    Description: Event System Utility Include
*/

//void main() {}

#include "es_inc_nss"

#include "nwnx_object"
#include "nwnx_util"
#include "nwnx_events"

#include "x3_inc_string"

const int EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN = 3018;

// Create a waypoint at locLocation with sTag
object ES_Util_CreateWaypoint(location locLocation, string sTag);

// Create a new data object with sTag
//
// A data object is a waypoint that can be used to store local variables on
object ES_Util_CreateDataObject(string sTag, int bDestroyExisting = TRUE);
// Destroy a data object with sTag
void ES_Util_DestroyDataObject(string sTag);
// Get a data object with sTag
// bCreateIfNotExists: if TRUE, create one if it does not exist.
//
// A data object is a waypoint that can be used to store local variables on
object ES_Util_GetDataObject(string sTag, int bCreateIfNotExists = TRUE);

// Write an Event System message to the log
void ES_Util_Log(string sSubSystem, string sMessage, int bSuppressible = TRUE);
// Toggle log supression
void ES_Util_SuppressLog(int bSuppress);

// Returns TRUE/FALSE for sEnvironmentVariable
int ES_Util_GetBooleanEnvVar(string sEnvironmentVariable);

// Convert a location to a string
string ES_Util_LocationToString(location locLocation);
// Convert a string to a location
location ES_Util_StringToLocation(string sLocation);

// Convert a vector to a string
string ES_Util_VectorToString(vector vVector);
// Convert a string to a vector
vector ES_Util_StringToVector(string sVector);

// Convenience wrapper for NWNX_Util_AddScript()
string ES_Util_AddScript(string sFileName, string sInclude, string sScriptChunk);
// Convenience wrapper for NWNX_Util_AddScript()
string ES_Util_AddConditionalScript(string sFileName, string sInclude, string sScriptConditionalChunk);
// Convenience wrapper for ExecuteScriptChunk()
string ES_Util_ExecuteScriptChunk(string sInclude, string sScriptChunk, object oObject);
// Convenience wrapper for NWNX_Util_RegisterServerConsoleCommand()
int ES_Util_RegisterServerConsoleCommand(string sCommand, string sInclude, string sScriptChunk, int bUnregisterExisting = FALSE);

// Get a functionname from sScriptContents using sDecorator
string ES_Util_GetFunctionName(string sScriptContents, string sDecorator, string sFunctionType = "void");
// Get the implementation of sFunctionName from sScriptContents
//
// The function must be prepared in the following way:
//
// // @FunctionStart TestFunction
// void TestFunction(string sTestString)
// {
//     // Code
// }
// // @FunctionEnd TestFunction
string ES_Util_GetFunctionImplementation(string sScriptContents, string sFunctionName);
// Returns TRUE if sScriptContents has sFlag
int ES_Util_GetHasScriptFlag(string sScriptContents, string sFlag);

// Create an array of resrefs on oArrayObject
// Returns: The array name
string ES_Util_GetResRefArray(object oArrayObject, int nType, string sRegexFilter = "", int bModuleResourcesOnly = TRUE);
// Execute a script chunk and return a string result
string ES_Util_ExecuteScriptChunkAndReturnString(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "");
// Execute a script chunk and return an int result
int ES_Util_ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "");
// Execute a script chunk for every element in sArrayName
// You can access the array element through the sArrayElement variable in your script chunk
void ES_Util_ExecuteScriptChunkForArrayElements(object oArrayObject, string sArrayName, string sInclude, string sScriptChunk, object oObject);

int floor(float f);
int ceil(float f);
int round(float f);

// Delete oObject's POS float variable sVarName
void ES_Util_DeleteFloat(object oObject, string sVarName);
// Delete any of oObject's POS float variables that match sRegex
void ES_Util_DeleteFloatRegex(object oObject, string sRegex);
// Get oObject's POS float variable sVarName
// * Return value on error: 0.0f
float ES_Util_GetFloat(object oObject, string sVarName);
// Set oObject's POS float variable sVarName to fValue
void ES_Util_SetFloat(object oObject, string sVarName, float fValue, int bPersist = FALSE);

// Delete oObject's POS integer variable sVarName
void ES_Util_DeleteInt(object oObject, string sVarName);
// Delete any of oObject's POS int variables that match sRegex
void ES_Util_DeleteIntRegex(object oObject, string sRegex);
// Get oObject's POS integer variable sVarName
// * Return value on error: 0
int ES_Util_GetInt(object oObject, string sVarName);
// Set oObject's POS integer variable sVarName to nValue
void ES_Util_SetInt(object oObject, string sVarName, int nValue, int bPersist = FALSE);

// Delete oObject's POS location variable sVarName
void ES_Util_DeleteLocation(object oObject, string sVarName);
// Delete any of oObject's POS location variables that match sRegex
void ES_Util_DeleteLocationRegex(object oObject, string sRegex);
// Get oObject's POS location variable sVarname
location ES_Util_GetLocation(object oObject, string sVarName);
// Set oObject's POS location variable sVarname to locValue
void ES_Util_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE);

// Delete oObject's POS vector variable sVarName
void ES_Util_DeleteVector(object oObject, string sVarName);
// Delete any of oObject's POS vector variables that match sRegex
void ES_Util_DeleteVectorRegex(object oObject, string sRegex);
// Get oObject's POS vector variable sVarname
vector ES_Util_GetVector(object oObject, string sVarName);
// Set oObject's POS vector variable sVarname to vValue
void ES_Util_SetVector(object oObject, string sVarName, vector vValue, int bPersist = FALSE);

// Delete oObject's POS object variable sVarName
void ES_Util_DeleteObject(object oObject, string sVarName);
// Delete any of oObject's POS object variables that match sRegex
void ES_Util_DeleteObjectRegex(object oObject, string sRegex);
// Get oObject's POS object variable sVarName
// * Return value on error: OBJECT_INVALID
object ES_Util_GetObject(object oObject, string sVarName);
// Set oObject's POS object variable sVarName to oValue
void ES_Util_SetObject(object oObject, string sVarName, object oValue);

// Delete oObject's POS string variable sVarName
void ES_Util_DeleteString(object oObject, string sVarName);
// Delete any of oObject's POS string variables that match sRegex
void ES_Util_DeleteStringRegex(object oObject, string sRegex);
// Get oObject's POS string variable sVarName
// * Return value on error: ""
string ES_Util_GetString(object oObject, string sVarName);
// Set oObject's POS string variable sVarName to sValue
void ES_Util_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE);

// Delete any POS variables from oObject that match sRegex
void ES_Util_DeleteVarRegex(object oObject, string sRegex);

// Insert a string to sArrayName
void ES_Util_StringArray_Insert(object oObject, string sArrayName, string sValue);
// Set nIndex of sArrayName to sValue
void ES_Util_StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue);
// Get the size of sArrayName
int ES_Util_StringArray_Size(object oObject, string sArrayName);
// Get the string at nIndex of sArrayName
string ES_Util_StringArray_At(object oObject, string sArrayName, int nIndex);
// Delete sArrayName
void ES_Util_StringArray_Clear(object oObject, string sArrayName);
// Returns the index of sValue if it exists in sArrayName or -1 if not
int ES_Util_StringArray_Contains(object oObject, string sArrayName, string sValue);
// Delete nIndex from sArrayName on oObject
void ES_Util_StringArray_Delete(object oObject, string sArrayName, int nIndex);
// Delete sValue from sArrayName on oObject
void ES_Util_StringArray_DeleteByValue(object oObject, string sArrayName, string sValue);

// NWNX_Events_GetEventData() string data wrapper
string ES_Util_GetEventData_NWNX_String(string sTag);
// NWNX_Events_GetEventData() int data wrapper
int ES_Util_GetEventData_NWNX_Int(string sTag);
// NWNX_Events_GetEventData() float data wrapper
float ES_Util_GetEventData_NWNX_Float(string sTag);
// NWNX_Events_GetEventData() object data wrapper
object ES_Util_GetEventData_NWNX_Object(string sTag);
// NWNX_Events_GetEventData() vector data wrapper
vector ES_Util_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ);
// NWNX_Events_GetEventData() location data wrapper
location ES_Util_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ);

// This function will make sString be the specified color
// as specified in sRGB.  RGB is the Red, Green, and Blue
// components of the color.  Each color can have a value from
// 0 to 7.
// Ex: red   == "700"
//     green == "070"
//     blue  == "007"
//     white == "777"
//     black == "000"
// The STRING_COLOR_* constants may be used for sRGB.
string ES_Util_ColorString(string sString, string sRGB);
// Send a server message
// If oPlayer is OBJECT_INVALID, the message will be sent to all players
void ES_Util_SendServerMessage(string sMessage, object oPlayer = OBJECT_INVALID, int bServerTag = TRUE);

// Returns TRUE if there is at least 1 player or DM online
int ES_Util_GetPlayersOnline();


object ES_Util_CreateWaypoint(location locLocation, string sTag)
{
    return CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation, FALSE, sTag);
}

object ES_Util_CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        ES_Util_DestroyDataObject(sTag);

    object oDataObject = ES_Util_CreateWaypoint(GetStartingLocation(), "ESDataObject_" + sTag);

    ES_Util_SetObject(GetModule(), "ESDataObject_" + sTag, oDataObject);

    return oDataObject;
}

void ES_Util_DestroyDataObject(string sTag)
{
    object oModule = GetModule();
    object oDataObject = ES_Util_GetObject(oModule, "ESDataObject_" + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        ES_Util_DeleteObject(oModule, "ESDataObject_" + sTag);
        DestroyObject(oDataObject);
    }
}

object ES_Util_GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = ES_Util_GetObject(GetModule(), "ESDataObject_" + sTag);

    return GetIsObjectValid(oDataObject) ? oDataObject : bCreateIfNotExists ? ES_Util_CreateDataObject(sTag) : OBJECT_INVALID;
}

void ES_Util_Log(string sSubSystem, string sMessage, int bSuppressible = TRUE)
{
    if (bSuppressible)
    {
        if (!GetLocalInt(GetModule(), "ES_SuppressLogs"))
            WriteTimestampedLogEntry("[EventSystem] " + sSubSystem + ": " + sMessage);
    }
    else
        WriteTimestampedLogEntry("[EventSystem] " + sSubSystem + ": " + sMessage);
}

void ES_Util_SuppressLog(int bSuppress)
{
    SetLocalInt(GetModule(), "ES_SuppressLogs", bSuppress);
}

int ES_Util_GetBooleanEnvVar(string sEnvironmentVariable)
{
    string sValue = NWNX_Util_GetEnvironmentVariable(sEnvironmentVariable);
    return sValue == "" ? FALSE : FindSubString(";t;true;y;yes;1;", ";" + GetStringLowerCase(sValue) + ";") != -1;
}

string ES_Util_LocationToString(location locLocation)
{
    string sAreaTag = GetTag(GetAreaFromLocation(locLocation));
    vector vPosition = GetPositionFromLocation(locLocation);
    float fFacing = GetFacingFromLocation(locLocation);

    return "#A#" + sAreaTag +
           "#X#" + FloatToString(vPosition.x, 0, 5) +
           "#Y#" + FloatToString(vPosition.y, 0, 5) +
           "#Z#" + FloatToString(vPosition.z, 0, 5) +
           "#F#" + FloatToString(fFacing, 0, 5) + "#";
}

location ES_Util_StringToLocation(string sLocation)
{
    location locLocation;

    int nLength = GetStringLength(sLocation);

    if(nLength > 0)
    {
        int nPos, nCount;

        nPos = FindSubString(sLocation, "#A#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        object oArea = GetObjectByTag(GetSubString(sLocation, nPos, nCount));

        nPos = FindSubString(sLocation, "#X#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fX = StringToFloat(GetSubString(sLocation, nPos, nCount));

        nPos = FindSubString(sLocation, "#Y#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fY = StringToFloat(GetSubString(sLocation, nPos, nCount));

        nPos = FindSubString(sLocation, "#Z#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fZ = StringToFloat(GetSubString(sLocation, nPos, nCount));

        vector vPosition = Vector(fX, fY, fZ);

        nPos = FindSubString(sLocation, "#F#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fOrientation = StringToFloat(GetSubString(sLocation, nPos, nCount));

        if( GetIsObjectValid(oArea) )
            locLocation = Location(oArea, vPosition, fOrientation);
        else
            locLocation = GetStartingLocation();
    }

    return locLocation;
}

string ES_Util_VectorToString(vector vVector)
{
    return "#X#" + FloatToString(vVector.x, 0, 5) +
           "#Y#" + FloatToString(vVector.y, 0, 5) +
           "#Z#" + FloatToString(vVector.z, 0, 5) + "#";
}

vector ES_Util_StringToVector(string sVector)
{
    vector vVector;

    int nLength = GetStringLength(sVector);

    if(nLength > 0)
    {
        int nPos, nCount;

        nPos = FindSubString(sVector, "#X#") + 3;
        nCount = FindSubString(GetSubString(sVector, nPos, nLength - nPos), "#");
        vVector.x = StringToFloat(GetSubString(sVector, nPos, nCount));

        nPos = FindSubString(sVector, "#Y#") + 3;
        nCount = FindSubString(GetSubString(sVector, nPos, nLength - nPos), "#");
        vVector.y = StringToFloat(GetSubString(sVector, nPos, nCount));

        nPos = FindSubString(sVector, "#Z#") + 3;
        nCount = FindSubString(GetSubString(sVector, nPos, nLength - nPos), "#");
        vVector.z = StringToFloat(GetSubString(sVector, nPos, nCount));
    }

    return vVector;
}

string ES_Util_AddScript(string sFileName, string sInclude, string sScriptChunk)
{
    string sScript = nssInclude(sInclude) + nssVoidMain(sScriptChunk);

    return NWNX_Util_AddScript(sFileName, sScript);
}

string ES_Util_AddConditionalScript(string sFileName, string sInclude, string sScriptConditionalChunk)
{
    string sScript = nssInclude(sInclude) + nssStartingConditional(sScriptConditionalChunk);

    return NWNX_Util_AddScript(sFileName, sScript);
}

string ES_Util_ExecuteScriptChunk(string sInclude, string sScriptChunk, object oObject)
{
    string sScript = nssInclude(sInclude) + nssVoidMain(sScriptChunk);

    return ExecuteScriptChunk(sScript, oObject, FALSE);
}

int ES_Util_RegisterServerConsoleCommand(string sCommand, string sInclude, string sScriptChunk, int bUnregisterExisting = FALSE)
{
    string sScript = nssInclude(sInclude) + nssVoidMain(nssString("sArgs", nssEscapeDoubleQuotes("$args")) + sScriptChunk);

    if (bUnregisterExisting)
        NWNX_Util_UnregisterServerConsoleCommand(sCommand);

    return NWNX_Util_RegisterServerConsoleCommand(sCommand, sScript);
}

string ES_Util_GetFunctionName(string sScriptContents, string sDecorator, string sFunctionType = "void")
{
    int nDecoratorPosition = FindSubString(sScriptContents, "@" + sDecorator, 0);

    if (nDecoratorPosition == -1)
        return "";

    int nFunctionTypeLength = GetStringLength(sFunctionType) + 1;
    int nFunctionStart = FindSubString(sScriptContents, sFunctionType + " ", nDecoratorPosition);
    int nFunctionEnd = FindSubString(sScriptContents, "(", nFunctionStart);

    return GetSubString(sScriptContents, nFunctionStart + nFunctionTypeLength, nFunctionEnd - nFunctionStart - nFunctionTypeLength);
}

string ES_Util_GetFunctionImplementation(string sScriptContents, string sFunctionName)
{
    int nImplementationStart = FindSubString(sScriptContents, "@FunctionStart " + sFunctionName, 0);
    int nImplementationEnd = FindSubString(sScriptContents, "@FunctionEnd " + sFunctionName, nImplementationStart);

    if (nImplementationStart == -1 || nImplementationEnd == -1)
        return "";

    int nImplementationStartLength = GetStringLength("@FunctionStart " + sFunctionName);

    return GetSubString(sScriptContents, nImplementationStart + nImplementationStartLength, nImplementationEnd - nImplementationStart - nImplementationStartLength - 3);
}

int ES_Util_GetHasScriptFlag(string sScriptContents, string sFlag)
{
    return FindSubString(sScriptContents, "@" + sFlag, 0) != -1;
}

string ES_Util_GetResRefArray(object oArrayObject, int nType, string sRegexFilter = "", int bModuleResourcesOnly = TRUE)
{
    string sArrayName = "RRA_" + GetRandomUUID();
    string sResRef = NWNX_Util_GetFirstResRef(nType, sRegexFilter, bModuleResourcesOnly);

    while (sResRef != "")
    {
        ES_Util_StringArray_Insert(oArrayObject, sArrayName, sResRef);

        sResRef = NWNX_Util_GetNextResRef();
    }

    return sArrayName;
}

string ES_Util_ExecuteScriptChunkAndReturnString(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude("es_inc_util") + nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssString("sReturn", sScriptChunk) +
        nssFunction("ES_Util_SetString", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", sReturn"));

    ES_Util_DeleteString(oModule, "ES_TEMP_VAR");
    ExecuteScriptChunk(sScript, oObject, FALSE);

    string sResult = ExecuteScriptChunk(sScript, oObject, FALSE);

    if (sResult != "")
        ES_Util_Log("ERROR", "ExecuteScriptChunkAndReturnString() failed with error: " + sResult);

    return ES_Util_GetString(oModule, "ES_TEMP_VAR");
}

int ES_Util_ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude("es_inc_util") + nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssInt("nReturn", sScriptChunk) +
        nssFunction("ES_Util_SetInt", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", nReturn"));

    ES_Util_DeleteInt(oModule, "ES_TEMP_VAR");
    string sResult = ExecuteScriptChunk(sScript, oObject, FALSE);

    if (sResult != "")
        ES_Util_Log("ERROR", "ExecuteScriptChunkAndReturnInt() failed with error: " + sResult);

    return ES_Util_GetInt(oModule, "ES_TEMP_VAR");
}

void ES_Util_ExecuteScriptChunkForArrayElements(object oArrayObject, string sArrayName, string sInclude, string sScriptChunk, object oObject)
{
    int nArraySize = ES_Util_StringArray_Size(oArrayObject, sArrayName);

    if(nArraySize)
    {
        int nIndex;

        for (nIndex = 0; nIndex < nArraySize; nIndex++)
        {
            string sArrayElement = ES_Util_StringArray_At(oArrayObject, sArrayName, nIndex);
            string sScript = nssInclude(sInclude) + nssVoidMain(nssString("sArrayElement", nssEscapeDoubleQuotes(sArrayElement)) + sScriptChunk);

            string sResult = ExecuteScriptChunk(sScript, oObject, FALSE);

            if (sResult != "")
                ES_Util_Log("ERROR", "ExecuteScriptChunkForArrayElements() failed on element '" + sArrayElement + "' with error: " + sResult);
        }
    }
}

int floor(float f)
{
    return FloatToInt(f);
}

int ceil(float f)
{
    return FloatToInt(f + (IntToFloat(FloatToInt(f)) < f ? 1.0 : 0.0));
}

int round(float f)
{
    return FloatToInt(f + 0.5f);
}

void ES_Util_DeleteFloat(object oObject, string sVarName)
{
    NWNX_Object_DeleteFloat(oObject, "ES!FLT!" + sVarName);
}

void ES_Util_DeleteFloatRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!FLT!)" + sRegex);
}

float ES_Util_GetFloat(object oObject, string sVarName)
{
    return NWNX_Object_GetFloat(oObject, "ES!FLT!" + sVarName);
}

void ES_Util_SetFloat(object oObject, string sVarName, float fValue, int bPersist = FALSE)
{
    NWNX_Object_SetFloat(oObject, "ES!FLT!" + sVarName, fValue, bPersist);
}

void ES_Util_DeleteInt(object oObject, string sVarName)
{
    NWNX_Object_DeleteInt(oObject, "ES!INT!" + sVarName);
}

void ES_Util_DeleteIntRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!INT!)" + sRegex);
}

int ES_Util_GetInt(object oObject, string sVarName)
{
    return NWNX_Object_GetInt(oObject, "ES!INT!" + sVarName);
}

void ES_Util_SetInt(object oObject, string sVarName, int nValue, int bPersist = FALSE)
{
    NWNX_Object_SetInt(oObject, "ES!INT!" + sVarName, nValue, bPersist);
}

void ES_Util_DeleteLocation(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!LOC!" + sVarName);
}

void ES_Util_DeleteLocationRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!LOC!)" + sRegex);
}

location ES_Util_GetLocation(object oObject, string sVarName)
{
    return ES_Util_StringToLocation(NWNX_Object_GetString(oObject, "ES!LOC!" + sVarName));
}

void ES_Util_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!LOC!" + sVarName, ES_Util_LocationToString(locValue), bPersist);
}

void ES_Util_DeleteVector(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!VEC!" + sVarName);
}

void ES_Util_DeleteVectorRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!VEC!)" + sRegex);
}

vector ES_Util_GetVector(object oObject, string sVarName)
{
    return ES_Util_StringToVector(NWNX_Object_GetString(oObject, "ES!VEC!" + sVarName));
}

void ES_Util_SetVector(object oObject, string sVarName, vector vValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!VEC!" + sVarName, ES_Util_VectorToString(vValue), bPersist);
}

void ES_Util_DeleteObject(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!OBJ!" + sVarName);
}

void ES_Util_DeleteObjectRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!OBJ!)" + sRegex);
}

object ES_Util_GetObject(object oObject, string sVarName)
{
    return NWNX_Object_StringToObject(NWNX_Object_GetString(oObject, "ES!OBJ!" + sVarName));
}

void ES_Util_SetObject(object oObject, string sVarName, object oValue)
{
    NWNX_Object_SetString(oObject, "ES!OBJ!" + sVarName, ObjectToString(oValue), FALSE);
}

void ES_Util_DeleteString(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!STR!" + sVarName);
}

void ES_Util_DeleteStringRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!STR!)" + sRegex);
}

string ES_Util_GetString(object oObject, string sVarName)
{
    return NWNX_Object_GetString(oObject, "ES!STR!" + sVarName);
}

void ES_Util_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!STR!" + sVarName, sValue, bPersist);
}

void ES_Util_DeleteVarRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!)((?:FLT!)|(?:INT!)|(?:LOC!)|(?:OBJ!)|(?:STR!))" + sRegex);
}

void ES_Util_StringArray_Insert(object oObject, string sArrayName, string sValue)
{
    int nSize = ES_Util_StringArray_Size(oObject, sArrayName);
    ES_Util_SetString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), sValue);
    ES_Util_SetInt(oObject, "SA!NUM!" + sArrayName, ++nSize);
}

void ES_Util_StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue)
{
    int nSize = ES_Util_StringArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        ES_Util_SetString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), sValue);
}

int ES_Util_StringArray_Size(object oObject, string sArrayName)
{
    return ES_Util_GetInt(oObject, "SA!NUM!" + sArrayName);
}

string ES_Util_StringArray_At(object oObject, string sArrayName, int nIndex)
{
    return ES_Util_GetString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void ES_Util_StringArray_Clear(object oObject, string sArrayName)
{
    ES_Util_DeleteVarRegex(oObject, "(?:SA!)((?:ELEMENT!)|(?:NUM!))(?:" + sArrayName + ")!?\d*");
}

int ES_Util_StringArray_Contains(object oObject, string sArrayName, string sValue)
{
    int nSize = ES_Util_StringArray_Size(oObject, sArrayName), nIndex;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            string sElement = ES_Util_StringArray_At(oObject, sArrayName, nIndex);

            if (sElement == sValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void ES_Util_StringArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = ES_Util_StringArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            ES_Util_StringArray_Set(oObject, sArrayName, nIndexNew, ES_Util_StringArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        ES_Util_DeleteString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        ES_Util_SetInt(oObject, "SA!NUM!" + sArrayName, nSize - 1);
    }
}

void ES_Util_StringArray_DeleteByValue(object oObject, string sArrayName, string sValue)
{
    int nSize = ES_Util_StringArray_Size(oObject, sArrayName), nIndex;
    string sElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        sElement = ES_Util_StringArray_At(oObject, sArrayName, nIndex);

        if (sElement == sValue)
        {
            ES_Util_StringArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}

string ES_Util_GetEventData_NWNX_String(string sTag)
{
    return NWNX_Events_GetEventData(sTag);
}

int ES_Util_GetEventData_NWNX_Int(string sTag)
{
    return StringToInt(ES_Util_GetEventData_NWNX_String(sTag));
}

float ES_Util_GetEventData_NWNX_Float(string sTag)
{
    return StringToFloat(ES_Util_GetEventData_NWNX_String(sTag));
}

object ES_Util_GetEventData_NWNX_Object(string sTag)
{
    return NWNX_Object_StringToObject(ES_Util_GetEventData_NWNX_String(sTag));
}

vector ES_Util_GetEventData_NWNX_Vector(string sTagX, string sTagY, string sTagZ)
{
    return Vector(ES_Util_GetEventData_NWNX_Float(sTagX),
                  ES_Util_GetEventData_NWNX_Float(sTagY),
                  ES_Util_GetEventData_NWNX_Float(sTagZ));
}

location ES_Util_GetEventData_NWNX_Location(string sTagArea, string sTagX, string sTagY, string sTagZ)
{
    return Location(ES_Util_GetEventData_NWNX_Object(sTagArea),
                    ES_Util_GetEventData_NWNX_Vector(sTagX, sTagY, sTagZ), 0.0f);
}

string ES_Util_ColorString(string sString, string sRGB)
{
    return StringToRGBString(sString, sRGB);
}

void ES_Util_SendServerMessage(string sMessage, object oPlayer = OBJECT_INVALID, int bServerTag = TRUE)
{
    sMessage = ES_Util_ColorString((bServerTag ? "[Server] " : "") + sMessage, "444");

    if (oPlayer == OBJECT_INVALID)
    {
        oPlayer = GetFirstPC();

        while( GetIsObjectValid(oPlayer) )
        {
            SendMessageToPC(oPlayer, sMessage);

            oPlayer = GetNextPC();
        }
    }
    else
        SendMessageToPC(oPlayer, sMessage);
}

int ES_Util_GetPlayersOnline()
{
    return GetFirstPC() != OBJECT_INVALID;
}

