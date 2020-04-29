/*
    ScriptName: es_cc_pos.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Object]

    Description: An EventSystem Core Component that allows Services
                 and Subsystems to store data in the POS of objects
*/

#include "es_inc_core"
#include "nwnx_object"

const string POS_LOG_TAG                = "POS";
const string POS_SCRIPT_NAME            = "es_cc_pos";

// Delete oObject's POS float variable sVarName
void POS_DeleteFloat(object oObject, string sVarName);
// Delete any of oObject's POS float variables that match sRegex
void POS_DeleteFloatRegex(object oObject, string sRegex);
// Get oObject's POS float variable sVarName
// * Return value on error: 0.0f
float POS_GetFloat(object oObject, string sVarName);
// Set oObject's POS float variable sVarName to fValue
void POS_SetFloat(object oObject, string sVarName, float fValue, int bPersist = FALSE);

// Delete oObject's POS integer variable sVarName
void POS_DeleteInt(object oObject, string sVarName);
// Delete any of oObject's POS int variables that match sRegex
void POS_DeleteIntRegex(object oObject, string sRegex);
// Get oObject's POS integer variable sVarName
// * Return value on error: 0
int POS_GetInt(object oObject, string sVarName);
// Set oObject's POS integer variable sVarName to nValue
void POS_SetInt(object oObject, string sVarName, int nValue, int bPersist = FALSE);

// Delete oObject's POS location variable sVarName
void POS_DeleteLocation(object oObject, string sVarName);
// Delete any of oObject's POS location variables that match sRegex
void POS_DeleteLocationRegex(object oObject, string sRegex);
// Get oObject's POS location variable sVarname
location POS_GetLocation(object oObject, string sVarName);
// Set oObject's POS location variable sVarname to locValue
void POS_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE);

// Delete oObject's POS vector variable sVarName
void POS_DeleteVector(object oObject, string sVarName);
// Delete any of oObject's POS vector variables that match sRegex
void POS_DeleteVectorRegex(object oObject, string sRegex);
// Get oObject's POS vector variable sVarname
vector POS_GetVector(object oObject, string sVarName);
// Set oObject's POS vector variable sVarname to vValue
void POS_SetVector(object oObject, string sVarName, vector vValue, int bPersist = FALSE);

// Delete oObject's POS object variable sVarName
void POS_DeleteObject(object oObject, string sVarName);
// Delete any of oObject's POS object variables that match sRegex
void POS_DeleteObjectRegex(object oObject, string sRegex);
// Get oObject's POS object variable sVarName
// * Return value on error: OBJECT_INVALID
object POS_GetObject(object oObject, string sVarName);
// Set oObject's POS object variable sVarName to oValue
void POS_SetObject(object oObject, string sVarName, object oValue);

// Delete oObject's POS string variable sVarName
void POS_DeleteString(object oObject, string sVarName);
// Delete any of oObject's POS string variables that match sRegex
void POS_DeleteStringRegex(object oObject, string sRegex);
// Get oObject's POS string variable sVarName
// * Return value on error: ""
string POS_GetString(object oObject, string sVarName);
// Set oObject's POS string variable sVarName to sValue
void POS_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE);

// Delete any POS variables from oObject that match sRegex
void POS_DeleteVarRegex(object oObject, string sRegex);

void POS_DeleteFloat(object oObject, string sVarName)
{
    NWNX_Object_DeleteFloat(oObject, "ES!FLT!" + sVarName);
}

void POS_DeleteFloatRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!FLT!)" + sRegex);
}

float POS_GetFloat(object oObject, string sVarName)
{
    return NWNX_Object_GetFloat(oObject, "ES!FLT!" + sVarName);
}

void POS_SetFloat(object oObject, string sVarName, float fValue, int bPersist = FALSE)
{
    NWNX_Object_SetFloat(oObject, "ES!FLT!" + sVarName, fValue, bPersist);
}

void POS_DeleteInt(object oObject, string sVarName)
{
    NWNX_Object_DeleteInt(oObject, "ES!INT!" + sVarName);
}

void POS_DeleteIntRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!INT!)" + sRegex);
}

int POS_GetInt(object oObject, string sVarName)
{
    return NWNX_Object_GetInt(oObject, "ES!INT!" + sVarName);
}

void POS_SetInt(object oObject, string sVarName, int nValue, int bPersist = FALSE)
{
    NWNX_Object_SetInt(oObject, "ES!INT!" + sVarName, nValue, bPersist);
}

void POS_DeleteLocation(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!LOC!" + sVarName);
}

void POS_DeleteLocationRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!LOC!)" + sRegex);
}

location POS_GetLocation(object oObject, string sVarName)
{
    return ES_Util_StringToLocation(NWNX_Object_GetString(oObject, "ES!LOC!" + sVarName));
}

void POS_SetLocation(object oObject, string sVarName, location locValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!LOC!" + sVarName, ES_Util_LocationToString(locValue), bPersist);
}

void POS_DeleteVector(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!VEC!" + sVarName);
}

void POS_DeleteVectorRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!VEC!)" + sRegex);
}

vector POS_GetVector(object oObject, string sVarName)
{
    return ES_Util_StringToVector(NWNX_Object_GetString(oObject, "ES!VEC!" + sVarName));
}

void POS_SetVector(object oObject, string sVarName, vector vValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!VEC!" + sVarName, ES_Util_VectorToString(vValue), bPersist);
}

void POS_DeleteObject(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!OBJ!" + sVarName);
}

void POS_DeleteObjectRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!OBJ!)" + sRegex);
}

object POS_GetObject(object oObject, string sVarName)
{
    return NWNX_Object_StringToObject(NWNX_Object_GetString(oObject, "ES!OBJ!" + sVarName));
}

void POS_SetObject(object oObject, string sVarName, object oValue)
{
    NWNX_Object_SetString(oObject, "ES!OBJ!" + sVarName, ObjectToString(oValue), FALSE);
}

void POS_DeleteString(object oObject, string sVarName)
{
    NWNX_Object_DeleteString(oObject, "ES!STR!" + sVarName);
}

void POS_DeleteStringRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!STR!)" + sRegex);
}

string POS_GetString(object oObject, string sVarName)
{
    return NWNX_Object_GetString(oObject, "ES!STR!" + sVarName);
}

void POS_SetString(object oObject, string sVarName, string sValue, int bPersist = FALSE)
{
    NWNX_Object_SetString(oObject, "ES!STR!" + sVarName, sValue, bPersist);
}

void POS_DeleteVarRegex(object oObject, string sRegex)
{
    NWNX_Object_DeleteVarRegex(oObject, "(?:ES!)((?:FLT!)|(?:INT!)|(?:LOC!)|(?:OBJ!)|(?:STR!))" + sRegex);
}

