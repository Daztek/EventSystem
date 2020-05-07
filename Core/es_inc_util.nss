/*
    ScriptName: es_inc_util.nss
    Created by: Daz

    Description: Event System Utility Include
*/

//void main() {}

#include "es_inc_array"
#include "es_inc_nss"
#include "nwnx_util"

#include "x3_inc_string"
#include "x0_i0_position"

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
string ES_Util_GetResRefArray(object oArrayObject, int nResType, string sRegexFilter = "", int bCustomResourcesOnly = TRUE);
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
string ltrim(string s);
string rtrim(string s);
string trim(string s);

// Calculate vCenter's angle to face vPoint
float ES_Util_CalculateFacing(vector vCenter, vector vPoint);

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
// Send a server message to all players in oArea
void ES_Util_SendServerMessageToArea(object oArea, string sMessage, int bServerTag = TRUE);

// Returns TRUE if there is at least 1 player or DM online
int ES_Util_GetPlayersOnline();

// Delete oObject's local vector variable sVarName
void DeleteLocalVector(object oObject, string sVarName);
// Get oObject's local vector variable sVarname
vector GetLocalVector(object oObject, string sVarName);
// Set oObject's local vector variable sVarname to vValue
void SetLocalVector(object oObject, string sVarName, vector vValue);

// Get the nNth object with sTag in oArea
object ES_Util_GetObjectByTagInArea(string sTag, object oArea, int nNth = 0);

// Get a random location fDistance from locPoint
location ES_Util_GetRandomLocationAroundPoint(location locPoint, float fDistance);

// Remove all effects with sTag from oPlayer
void ES_Util_RemoveAllEffectsWithTag(object oPlayer, string sTag);


object ES_Util_CreateWaypoint(location locLocation, string sTag)
{
    return CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation, FALSE, sTag);
}

object ES_Util_CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        ES_Util_DestroyDataObject(sTag);

    object oDataObject = ES_Util_CreateWaypoint(GetStartingLocation(), "ESDataObject_" + sTag);

    SetLocalObject(GetModule(), "ESDataObject_" + sTag, oDataObject);

    return oDataObject;
}

void ES_Util_DestroyDataObject(string sTag)
{
    object oModule = GetModule();
    object oDataObject = GetLocalObject(oModule, "ESDataObject_" + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        DeleteLocalObject(oModule, "ESDataObject_" + sTag);
        DestroyObject(oDataObject);
    }
}

object ES_Util_GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = GetLocalObject(GetModule(), "ESDataObject_" + sTag);

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

string ES_Util_GetResRefArray(object oArrayObject, int nResType, string sRegexFilter = "", int bCustomResourcesOnly = TRUE)
{
    string sArrayName = "RRA_" + GetRandomUUID();
    string sResRef = NWNX_Util_GetFirstResRef(nResType, sRegexFilter, bCustomResourcesOnly);

    while (sResRef != "")
    {
        StringArray_Insert(oArrayObject, sArrayName, sResRef);

        sResRef = NWNX_Util_GetNextResRef();
    }

    return sArrayName;
}

string ES_Util_ExecuteScriptChunkAndReturnString(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssString("sReturn", sScriptChunk) +
        nssFunction("SetLocalString", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", sReturn"));

    DeleteLocalString(oModule, "ES_TEMP_VAR");
    ExecuteScriptChunk(sScript, oObject, FALSE);

    string sResult = ExecuteScriptChunk(sScript, oObject, FALSE);

    if (sResult != "")
        ES_Util_Log("ERROR", "ExecuteScriptChunkAndReturnString() failed with error: " + sResult);

    return GetLocalString(oModule, "ES_TEMP_VAR");
}

int ES_Util_ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssInt("nReturn", sScriptChunk) +
        nssFunction("SetLocalInt", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", nReturn"));

    DeleteLocalInt(oModule, "ES_TEMP_VAR");
    string sResult = ExecuteScriptChunk(sScript, oObject, FALSE);

    if (sResult != "")
        ES_Util_Log("ERROR", "ExecuteScriptChunkAndReturnInt() failed with error: " + sResult);

    return GetLocalInt(oModule, "ES_TEMP_VAR");
}

void ES_Util_ExecuteScriptChunkForArrayElements(object oArrayObject, string sArrayName, string sInclude, string sScriptChunk, object oObject)
{
    int nArraySize = StringArray_Size(oArrayObject, sArrayName);

    if(nArraySize)
    {
        int nIndex;

        for (nIndex = 0; nIndex < nArraySize; nIndex++)
        {
            string sArrayElement = StringArray_At(oArrayObject, sArrayName, nIndex);
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

string ltrim(string s)
{
    while (GetStringLeft(s, 1) == " ")
        s = GetStringRight(s, GetStringLength(s) - 1);

    return s;
}

string rtrim(string s)
{
    while (GetStringRight(s, 1) == " ")
        s = GetStringLeft(s, GetStringLength(s) - 1);

    return s;
}

string trim(string s)
{
    return ltrim(rtrim(s));
}

float ES_Util_CalculateFacing(vector vCenter, vector vPoint)
{
    float fAngle;
    float fAtan = atan((fabs(fabs(vCenter.y) - fabs(vPoint.y))) / (fabs(fabs(vCenter.x) - fabs(vPoint.x))));

    if (vCenter.x >= vPoint.x && vCenter.y <= vPoint.y)
        fAngle = 90 - fAtan;
    else if (vCenter.x >= vPoint.x && vCenter.y >= vPoint.y)
        fAngle = 90 + fAtan;
    else if (vCenter.x <= vPoint.x && vCenter.y >= vPoint.y)
        fAngle =  270 - fAtan;
    else if (vCenter.x <= vPoint.x && vCenter.y <= vPoint.y)
    {
        float f = 270 + fAtan;
        fAngle = (f == 360.0f ? 0.0f : f);
    }
    return fAngle - 270;
}

string ES_Util_ColorString(string sString, string sRGB)
{
    return StringToRGBString(sString, sRGB);
}

void ES_Util_SendServerMessage(string sMessage, object oPlayer = OBJECT_INVALID, int bServerTag = TRUE)
{
    if(sMessage == "")
        return;
    else
        sMessage = ES_Util_ColorString((bServerTag ? "[Server] " : "") + sMessage, "444");

    if (oPlayer == OBJECT_INVALID)
    {
        oPlayer = GetFirstPC();

        while (GetIsObjectValid(oPlayer))
        {
            SendMessageToPC(oPlayer, sMessage);

            oPlayer = GetNextPC();
        }
    }
    else
        SendMessageToPC(oPlayer, sMessage);
}

void ES_Util_SendServerMessageToArea(object oArea, string sMessage, int bServerTag = TRUE)
{
    if(sMessage == "")
        return;
    else
        sMessage = ES_Util_ColorString((bServerTag ? "[Server] " : "") + sMessage, "444");

    object oPlayer = GetFirstPC();

    while( GetIsObjectValid(oPlayer) )
    {
        if (GetArea(oPlayer) == oArea)
            SendMessageToPC(oPlayer, sMessage);

        oPlayer = GetNextPC();
    }
}

int ES_Util_GetPlayersOnline()
{
    return GetFirstPC() != OBJECT_INVALID;
}

void DeleteLocalVector(object oObject, string sVarName)
{
    DeleteLocalLocation(oObject, "VEC:" + sVarName);
}

vector GetLocalVector(object oObject, string sVarName)
{
    return GetPositionFromLocation(GetLocalLocation(oObject, "VEC:" + sVarName));
}

void SetLocalVector(object oObject, string sVarName, vector vValue)
{
    SetLocalLocation(oObject, "VEC:" + sVarName, Location(GetAreaFromLocation(GetStartingLocation()), vValue, 0.0f));
}

object ES_Util_GetObjectByTagInArea(string sTag, object oArea, int nNth = 0)
{
    object oObject;
    int nNthLoop;

    while ((oObject = GetObjectByTag(sTag, nNthLoop++)) != OBJECT_INVALID)
    {
        if (GetArea(oObject) == oArea)
        {
            if (--nNth < 0)
                return oObject;
        }
    }

    return OBJECT_INVALID;
}

location ES_Util_GetRandomLocationAroundPoint(location locPoint, float fDistance)
{
    float fAngle = IntToFloat(Random(360));
    float fOrient = IntToFloat(Random(360));

    return GenerateNewLocationFromLocation(locPoint, fDistance, fAngle, fOrient);
}

void ES_Util_RemoveAllEffectsWithTag(object oPlayer, string sTag)
{
    effect eEffect = GetFirstEffect(oPlayer);

    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == sTag)
            RemoveEffect(oPlayer, eEffect);

        eEffect = GetNextEffect(oPlayer);
    }
}
