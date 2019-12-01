/*
    ScriptName: es_inc_util.nss
    Created by: Daz

    Description: Event System Utility Include
*/

#include "x0_i0_position"
#include "nwnx_util"

const string ES_UTIL_DATA_OBJECT_TAG      = "ESDataObject_";
const string ES_UTIL_EVENT_SYSTEM_LOG_TAG = "EventSystem";

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

// Apply an effect to all players in a sphere
void ES_Util_ApplyEffectToPlayersInSphere(object oCenter, float fRadius, effect eEffect, float fDuration = 0.0f);

/**/

object ES_Util_CreateDataObject(string sTag, int bDestroyExisting = TRUE)
{
    if (bDestroyExisting)
        ES_Util_DestroyDataObject(ES_UTIL_DATA_OBJECT_TAG + sTag);

    object oDataObject = CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", GetStartingLocation(), FALSE, ES_UTIL_DATA_OBJECT_TAG + sTag);

    SetLocalObject(GetModule(), ES_UTIL_DATA_OBJECT_TAG + sTag, oDataObject);

    return oDataObject;
}

void ES_Util_DestroyDataObject(string sTag)
{
    object oDataObject = GetLocalObject(GetModule(), ES_UTIL_DATA_OBJECT_TAG + sTag);

    if (GetIsObjectValid(oDataObject))
    {
        DeleteLocalObject(GetModule(), ES_UTIL_DATA_OBJECT_TAG + sTag);
        DestroyObject(oDataObject);
    }
}

object ES_Util_GetDataObject(string sTag, int bCreateIfNotExists = TRUE)
{
    object oDataObject = GetLocalObject(GetModule(), ES_UTIL_DATA_OBJECT_TAG + sTag);

    return GetIsObjectValid(oDataObject) ? oDataObject : bCreateIfNotExists ? ES_Util_CreateDataObject(sTag) : OBJECT_INVALID;
}

void ES_Util_Log(string sSubSystem, string sMessage)
{
    WriteTimestampedLogEntry("[" + ES_UTIL_EVENT_SYSTEM_LOG_TAG + "] " + sSubSystem + ": " + sMessage);
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
           "#F#" + FloatToString(fFacing, 0, 2) +
           "#E#";
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
    string sScript = (sInclude != "" ? ("#" + "include \"" + sInclude + "\" \n") : "") + "void main() { " + sScriptChunk + " }";
    return NWNX_Util_AddScript(sFileName, sScript);
}

string ES_Util_AddConditionalScript(string sFileName, string sInclude, string sScriptConditionalChunk)
{
    string sScript = (sInclude != "" ? ("#" + "include \"" + sInclude + "\" \n") : "") + "int StartingConditional() { return " + sScriptConditionalChunk + " }";
    return NWNX_Util_AddScript(sFileName, sScript);
}

string ES_Util_ExecuteScriptChunk(string sInclude, string sScriptChunk, object oObject)
{
    string sScript = (sInclude != "" ? ("#" + "include \"" + sInclude + "\" \n") : "") + "void main() { " + sScriptChunk + " }";
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

void ES_Util_ApplyEffectToPlayersInSphere(object oCenter, float fRadius, effect eEffect, float fDuration = 0.0f)
{
    location locCenter = GetLocation(oCenter);

    object oObject = GetFirstObjectInShape(SHAPE_SPHERE, fRadius, locCenter);

    while (GetIsObjectValid(oObject))
    {
        if (GetIsPC(oObject))
        {
            ApplyEffectToObject(fDuration == 0.0f ? DURATION_TYPE_INSTANT : DURATION_TYPE_TEMPORARY, eEffect, oObject, fDuration);

            oObject = GetNextObjectInShape(SHAPE_SPHERE, fRadius, locCenter);
        }
    }
}

