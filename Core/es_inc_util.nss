/*
    ScriptName: es_inc_util.nss
    Created by: Daz

    Description: Event System Utility Include
*/

//void main() {}

#include "es_inc_nss"
#include "x0_i0_position"
#include "nwnx_object"
#include "nwnx_util"

const string ES_UTIL_DELIMITER              = ";";

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
void ES_Util_Log(string sSubSystem, string sMessage);

// Get a location fDistance ahead of oTarget
location ES_Util_GetAheadLocation(object oTarget, float fDistance);
// Get a location fDistance behind oTarget
location ES_Util_GetBehindLocation(object oTarget, float fDistance);
// Get a random location around a point
location ES_Util_GetRandomLocationAroundPoint(location locPoint, float fDistance);

// Remove all effects with sTag from oObject
void ES_Util_RemoveAllEffectsWithTag(object oObject, string sTag);

// Convert a location to a string
string ES_Util_LocationToString(location locLocation);
// Convert a string to a location
location ES_Util_StringToLocation(string sLocation);

// Convenience wrapper for NWNX_Util_AddScript()
string ES_Util_AddScript(string sFileName, string sInclude, string sScriptChunk);
// Convenience wrapper for NWNX_Util_AddScript()
string ES_Util_AddConditionalScript(string sFileName, string sInclude, string sScriptConditionalChunk);
// Convenience wrapper for ExecuteScriptChunk()
string ES_Util_ExecuteScriptChunk(string sInclude, string sScriptChunk, object oObject);

int floor(float f);
int ceil(float f);
int round(float f);

// Get a functionname from sScriptContents using sDecorator
string ES_Util_GetFunctionName(string sScriptContents, string sDecorator, string sFunctionType = "void");
// Get if sFlag is set in a script
int ES_Util_GetScriptFlag(string sScriptContents, string sFlag);
// Get a list of resrefs with ES_UTIL_DELIMITER as delimiter
string ES_Util_GetResRefList(int nType, string sRegexFilter = "", int bModuleResourcesOnly = TRUE);
// Get the first list item of sList or "" on error
string ES_Util_GetFirstListItem(string sList, string sIdentifier);
// Get the next list item of sList or "" on error
string ES_Util_GetNextListItem(string sList, string sIdentifier);
// Execute a script chunk and return a string result
string ES_Util_ExecuteScriptChunkAndReturnString(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "");
// Execute a script chunk and return an int result
int ES_Util_ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "");
// Execute a script chunk for every item in sList using ES_UTIL_DELIMITER
//
// You can access the list item through the sListItem variable in your script chunk
void ES_Util_ExecuteScriptChunkForListItem(string sList, string sInclude, string sScriptChunk, object oObject);

// Delete oObject's POS float variable sVarName
void ES_Util_DeleteFloat(object oObject, string sVarName);
// Get oObject's POS float variable sVarName
// * Return value on error: 0.0f
float ES_Util_GetFloat(object oObject, string sVarName);
// Set oObject's POS float variable sVarName to fValue
void ES_Util_SetFloat(object oObject, string sVarName, float fValue, int bPersist = FALSE);

// Delete oObject's POS integer variable sVarName
void ES_Util_DeleteInt(object oObject, string sVarName);
// Get oObject's POS integer variable sVarName
// * Return value on error: 0
int ES_Util_GetInt(object oObject, string sVarName);
// Set oObject's POS integer variable sVarName to nValue
void ES_Util_SetInt(object oObject, string sVarName, int nValue, int bPersist = FALSE);

// Delete oObject's POS location variable sVarName
void ES_Util_DeleteLocation(object oObject, string sVarName);
// Get oObject's POS location variable sVarname
location ES_Util_GetLocation(object oObject, string sVarName);
// Set oObject's POS location variable sVarname to locValue
void ES_Util_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE);

// Delete oObject's POS object variable sVarName
void ES_Util_DeleteObject(object oObject, string sVarName);
// Get oObject's POS object variable sVarName
// * Return value on error: OBJECT_INVALID
object ES_Util_GetObject(object oObject, string sVarName);
// Set oObject's POS object variable sVarName to oValue
void ES_Util_SetObject(object oObject, string sVarName, object oValue);

// Delete oObject's POS string variable sVarName
void ES_Util_DeleteString(object oObject, string sVarName);
// Get oObject's POS string variable sVarName
// * Return value on error: ""
string ES_Util_GetString(object oObject, string sVarName);
// Set oObject's POS string variable sVarName to sValue
void ES_Util_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE);



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
    object oDataObject = ES_Util_GetObject(GetModule(), "ESDataObject_" + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        ES_Util_DeleteObject(GetModule(), "ESDataObject_" + sTag);
        DestroyObject(oDataObject);
    }
}

object ES_Util_GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = ES_Util_GetObject(GetModule(), "ESDataObject_" + sTag);

    return GetIsObjectValid(oDataObject) ? oDataObject : bCreateIfNotExists ? ES_Util_CreateDataObject(sTag) : OBJECT_INVALID;
}

void ES_Util_Log(string sSubSystem, string sMessage)
{
    WriteTimestampedLogEntry("[EventSystem] " + sSubSystem + ": " + sMessage);
}

location ES_Util_GetAheadLocation(object oTarget, float fDistance)
{
    float fDir = GetFacing(oTarget);

    return GenerateNewLocation(oTarget, fDistance, fDir, fDir);
}

location ES_Util_GetBehindLocation(object oTarget, float fDistance)
{
    float fDir = GetFacing(oTarget);
    float fAngleOpposite = GetOppositeDirection(fDir);

    return GenerateNewLocation(oTarget, fDistance, fAngleOpposite, fDir);
}

location ES_Util_GetRandomLocationAroundPoint(location locPoint, float fDistance)
{
    float fAngle = IntToFloat(Random(360));
    float fOrient = IntToFloat(Random(360));

    return GenerateNewLocationFromLocation(locPoint, fDistance, fAngle, fOrient);
}

void ES_Util_RemoveAllEffectsWithTag(object oObject, string sTag)
{
    effect eEffect = GetFirstEffect(oObject);

    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == sTag)
            RemoveEffect(oObject, eEffect);

        eEffect = GetNextEffect(oObject);
    }
}

string ES_Util_LocationToString(location locLocation)
{
    string sAreaTag = GetTag(GetAreaFromLocation(locLocation));
    vector vPosition = GetPositionFromLocation(locLocation);
    float fFacing = GetFacingFromLocation(locLocation);

    return "#A#" + sAreaTag +
           "#X#" + FloatToString(vPosition.x, 0, 2) +
           "#Y#" + FloatToString(vPosition.y, 0, 2) +
           "#Z#" + FloatToString(vPosition.z, 0, 2) +
           "#F#" + FloatToString(fFacing, 0, 2) + "#";
}

location ES_Util_StringToLocation(string sLocation)
{
    location locLocation;

    int nLength = GetStringLength(sLocation);

    if(nLength > 0)
    {
        int nPos, nCount;

        // Area
        nPos = FindSubString(sLocation, "#A#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        object oArea = GetObjectByTag(GetSubString(sLocation, nPos, nCount));

        // Position X
        nPos = FindSubString(sLocation, "#X#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fX = StringToFloat(GetSubString(sLocation, nPos, nCount));

        // Position Y
        nPos = FindSubString(sLocation, "#Y#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fY = StringToFloat(GetSubString(sLocation, nPos, nCount));

        // Position Z
        nPos = FindSubString(sLocation, "#Z#") + 3;
        nCount = FindSubString(GetSubString(sLocation, nPos, nLength - nPos), "#");
        float fZ = StringToFloat(GetSubString(sLocation, nPos, nCount));

        // Position
        vector vPosition = Vector(fX, fY, fZ);

        // Facing
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

int ES_Util_GetScriptFlag(string sScriptContents, string sFlag)
{
    return FindSubString(sScriptContents, "@" + sFlag, 0) != -1;
}

string ES_Util_GetResRefList(int nType, string sRegexFilter = "", int bModuleResourcesOnly = TRUE)
{
    string sResRefList, sResRef = NWNX_Util_GetFirstResRef(nType, sRegexFilter, bModuleResourcesOnly);

    while (sResRef != "")
    {
        sResRefList += sResRef + ES_UTIL_DELIMITER;
        sResRef = NWNX_Util_GetNextResRef();
    }

    return sResRefList;
}

string ES_Util_GetFirstListItem(string sList, string sIdentifier)
{
    if (sList == "")
        return "";

    object oModule = GetModule();
    int nEnd = FindSubString(sList, ES_UTIL_DELIMITER, 0);
    string sListItem;

    ES_Util_DeleteInt(oModule, "ES_TEMP_LIST_START_" + sIdentifier);

    if (nEnd != -1)
    {
        sListItem = GetSubString(sList, 0, nEnd);
        ES_Util_SetInt(oModule, "ES_TEMP_LIST_START_" + sIdentifier, nEnd + 1);
    }

    return sListItem;
}

string ES_Util_GetNextListItem(string sList, string sIdentifier)
{
    if (sList == "")
        return "";

    object oModule = GetModule();
    int nStart = ES_Util_GetInt(oModule, "ES_TEMP_LIST_START_" + sIdentifier);
    int nEnd = FindSubString(sList, ES_UTIL_DELIMITER, nStart);
    string sListItem;

    if (nEnd != -1)
    {
        sListItem = GetSubString(sList, nStart, nEnd - nStart);
        ES_Util_SetInt(oModule, "ES_TEMP_LIST_START_" + sIdentifier, nEnd + 1);
    }
    else
    {
        ES_Util_DeleteInt(oModule, "ES_TEMP_LIST_START_" + sIdentifier);
    }

    return sListItem;
}

string ES_Util_ExecuteScriptChunkAndReturnString(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude("es_inc_util") + nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssString("sReturn", sScriptChunk) +
        nssFunction("ES_Util_SetString", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", sReturn"));

    ES_Util_DeleteString(oModule, "ES_TEMP_VAR");
    ExecuteScriptChunk(sScript, oObject, FALSE);

    return ES_Util_GetString(oModule, "ES_TEMP_VAR");
}

int ES_Util_ExecuteScriptChunkAndReturnInt(string sInclude, string sScriptChunk, object oObject, string sObjectSelfVarName = "")
{
    object oModule = GetModule();
    string sObjectSelf = sObjectSelfVarName != "" ? nssObject(sObjectSelfVarName, "OBJECT_SELF") : "";
    string sScript = nssInclude("es_inc_util") + nssInclude(sInclude) + nssVoidMain(sObjectSelf + nssInt("nReturn", sScriptChunk) +
        nssFunction("ES_Util_SetInt", nssFunction("GetModule", "", FALSE) + ", " + nssEscapeDoubleQuotes("ES_TEMP_VAR") + ", nReturn"));

    ES_Util_DeleteInt(oModule, "ES_TEMP_VAR");
    ExecuteScriptChunk(sScript, oObject, FALSE);

    return ES_Util_GetInt(oModule, "ES_TEMP_VAR");
}

void ES_Util_ExecuteScriptChunkForListItem(string sList, string sInclude, string sScriptChunk, object oObject)
{
    if (sList == "") return;

    string sIdentifier = GetRandomUUID();
    string sListItem = ES_Util_GetFirstListItem(sList, sIdentifier);

    while (sListItem != "")
    {
        string sScript = nssInclude(sInclude) + nssVoidMain(nssString("sListItem", nssEscapeDoubleQuotes(sListItem)) + sScriptChunk);

        ExecuteScriptChunk(sScript, oObject, FALSE);

        sListItem = ES_Util_GetNextListItem(sList, sIdentifier);
    }
}

void ES_Util_DeleteFloat(object oObject, string sVarName)
{
    NWNX_Object_DeleteFloat(oObject, "ES!FLT!" + sVarName);
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

location ES_Util_GetLocation(object oObject, string sVarName)
{
    return ES_Util_StringToLocation(NWNX_Object_GetString(oObject, "ES!LOC!" + sVarName));
}

void ES_Util_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!LOC!" + sVarName, ES_Util_LocationToString(locValue), bPersist);
}

void ES_Util_DeleteObject(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!OBJ!" + sVarName);
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

string ES_Util_GetString(object oObject, string sVarName)
{
    return NWNX_Object_GetString(oObject, "ES!STR!" + sVarName);
}

void ES_Util_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!STR!" + sVarName, sValue, bPersist);
}

