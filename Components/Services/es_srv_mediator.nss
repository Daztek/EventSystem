/*
    ScriptName: es_srv_mediator.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Object]

    Description: An EventSystem Service that allows subsystems to call functions
                 from other subsystems without having to include them.
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_object"

const string MEDIATOR_LOG_TAG                       = "Mediator";
const string MEDIATOR_SCRIPT_NAME                   = "es_srv_mediator";

const string MEDIATOR_ARGUMENT_DELIMITER            = "~!?^";

const string MEDIATOR_NUM_FUNCTIONS                 = "NumFunctions";

const string MEDIATOR_FUNCTION_ID                   = "FunctionID_";
const string MEDIATOR_FUNCTION_NAME                 = "FunctionName_";
const string MEDIATOR_FUNCTION_SUBSYSTEM            = "FunctionSubsystem_";
const string MEDIATOR_FUNCTION_RETURN_TYPE          = "FunctionReturnType_";
const string MEDIATOR_FUNCTION_PARAMETERS           = "FunctionParameters_";

const string MEDIATOR_FUNCTION_SCRIPT_NAME          = "mediator_";
const string MEDIATOR_FUNCTION_SCRIPT_VARIABLE      = "MEDIATOR_VARIABLE_";
const string MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE  = "MEDIATOR_RETURN_VALUE";

// Register sFunctionName with sParameters from sSubsystemScript with the Mediator
// so it can be called by other subsystems without the subsystem script needing to be included.
//
// - sSubsystemScript: The subsystem the function is from
// - sFunctionName: The function name without returntype and parameters
// - sParameters: The first letter of the function's parameters, must match the function's definition
//                Only supports the following types: (o)bject, (s)tring, (i)nt, (f)loat, (l)ocation, (v)ector
// - sReturnType: The first letter of the function's return type, must match the function's definition
//                Only supports the following types: (o)bject, (s)tring, (i)nt, (f)loat, (l)ocation, (v)ector
//                Leave empty for void functions.
//
// Example:
//  string MySubsystemFunction(int nFoo, object oBar, string sBaz);
//  Mediator_RegisterFunction("es_s_subsystem", "MySubsystemFunction", "ios", "s");
void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters, string sReturnType = "");
// Returns TRUE if sSubsystem has registered sFunctionName, with an optional parameter check.
int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****");
// Execute sFunctionName from sSubsystem with sArguments on oTarget
//
// - bWarn: Write a warning to the log if parameters don't match or function is not registered
//
// Example:
//   Mediator_ExecuteFunction("es_s_subsystem", "MySubsystemFunction", Mediator_Int(1337) + Mediator_Object(GetModule()) + Mediator_String("Test"));
//
// Returns: TRUE on success
int Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments = "", object oTarget = OBJECT_SELF, int bWarn = TRUE);

// Get a float return value from a function executed with Mediator_ExecuteFunction()
float Mediator_GetReturnValueFloat();
// Get an int return value from a function executed with Mediator_ExecuteFunction()
int Mediator_GetReturnValueInt();
// Get a location return value from a function executed with Mediator_ExecuteFunction()
location Mediator_GetReturnValueLocation();
// Get an object return value from a function executed with Mediator_ExecuteFunction()
object Mediator_GetReturnValueObject();
// Get a string return value from a function executed with Mediator_ExecuteFunction()
string Mediator_GetReturnValueString();
// Get a vector return value from a function executed with Mediator_ExecuteFunction()
vector Mediator_GetReturnValueVector();

// Convert an object to a Mediator_ExecuteFunction() argument
string Mediator_Object(object o);
// Convert a string to a Mediator_ExecuteFunction() argument
string Mediator_String(string s);
// Convert an int to a Mediator_ExecuteFunction() argument
string Mediator_Int(int n);
// Convert a float to a Mediator_ExecuteFunction() argument
string Mediator_Float(float f);
// Convert a location to a Mediator_ExecuteFunction() argument
string Mediator_Location(location l);
// Convert a vector to a Mediator_ExecuteFunction() argument
string Mediator_Vector(vector v);

// @Post
void Mediator_Post(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nFunctionID, nNumFunctions = GetLocalInt(oDataObject, MEDIATOR_NUM_FUNCTIONS);

    for (nFunctionID = 1; nFunctionID <= nNumFunctions; nFunctionID++)
    {
        string sFunctionName = GetLocalString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nFunctionID));
        string sSubsystem = GetLocalString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nFunctionID));
        string sReturnType = nssConvertShortType(GetLocalString(oDataObject, MEDIATOR_FUNCTION_RETURN_TYPE + IntToString(nFunctionID)));
        string sParameters = GetLocalString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));
        string sScriptName = MEDIATOR_FUNCTION_SCRIPT_NAME + IntToString(nFunctionID);
        string sFunction, sArguments, sVariables = nssObject("oDataObject", nssFunction("ES_Util_GetDataObject", nssEscapeDoubleQuotes(MEDIATOR_SCRIPT_NAME)));
        int nParameter, nNumParameters = GetStringLength(sParameters);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Compiling Script '" + sScriptName + "' for Function '" +
            (sReturnType == "" ? "void" : GetStringLowerCase(sReturnType)) + " " + sSubsystem + "::" + sFunctionName + "(" + sParameters + ")'");

        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            string sParameter = GetSubString(sParameters, nParameter, 1);
            string sVarName = sParameter + "Variable" + IntToString(nParameter);
            string sType = nssConvertShortType(sParameter);

            if (sType != "")
            {
                sArguments += sVarName + ",";
                sVariables += nssVariable(GetStringLowerCase(sType), sVarName, nssFunction("GetLocal" + sType, "oDataObject, " +
                              nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_VARIABLE + IntToString(nParameter))));
            }
        }

        sArguments = GetSubString(sArguments, 0, GetStringLength(sArguments) - 1);

        if (sReturnType != "")
        {
            sFunction = nssFunction("SetLocal" + sReturnType, "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction(sFunctionName, sArguments, FALSE));
        }
        else
        {
            sFunction = nssFunction(sFunctionName, sArguments);
        }

        string sScript = sVariables + sFunction;
        string sError = ES_Util_AddScript(sScriptName, sSubsystem, sScript);

        if (sError != "")
        {
            ES_Util_Log(MEDIATOR_LOG_TAG, "  > ERROR: Failed to compile '" + sScriptName + "' with error: " + sError);
        }
    }
}

void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters, string sReturnType = "void")
{
    if (sSubsystemScript == "" || sFunctionName == "")
        return;

    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    if (!GetLocalInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName))
    {
        int nFunctionID = GetLocalInt(oDataObject, MEDIATOR_NUM_FUNCTIONS) + 1;

        sParameters = GetStringLowerCase(sParameters);
        sReturnType = GetStringLowerCase(sReturnType);

        SetLocalInt(oDataObject, MEDIATOR_NUM_FUNCTIONS, nFunctionID);
        SetLocalInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName, nFunctionID);

        SetLocalString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nFunctionID), sFunctionName);
        SetLocalString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nFunctionID), sSubsystemScript);
        SetLocalString(oDataObject, MEDIATOR_FUNCTION_RETURN_TYPE + IntToString(nFunctionID), sReturnType);
        SetLocalString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID), sParameters);

        sReturnType = nssConvertShortType(sReturnType);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Subsystem '" + sSubsystemScript + "' registered function '" +
            (sReturnType == "" ? "void" : GetStringLowerCase(sReturnType)) + " " + sFunctionName + "(" + sParameters + ")'");
    }
}

int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****")
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nFunctionID = GetLocalInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);
    int bParametersMatch = sParameters == "****" ? TRUE :
        sParameters == GetLocalString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));

    return nFunctionID && bParametersMatch;
}

string Mediator_SetFunctionVariables(string sArguments)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nArgumentDelimiterLength = GetStringLength(MEDIATOR_ARGUMENT_DELIMITER);
    int nCount, nArgumentStart, nArgumentEnd = FindSubString(sArguments, MEDIATOR_ARGUMENT_DELIMITER, nArgumentStart);
    string sParameters;

    while (nArgumentEnd != -1)
    {
        string sArgument = GetSubString(sArguments, nArgumentStart, nArgumentEnd - nArgumentStart);
        string sType = GetSubString(sArgument, 0, 2);
        string sValue = GetSubString(sArgument, 2, GetStringLength(sArgument) - 2);

        string sVarName = MEDIATOR_FUNCTION_SCRIPT_VARIABLE + IntToString(nCount);

        if (sType == "o:")
        {
            sParameters += "o";
            SetLocalObject(oDataObject, sVarName, StringToObject(sValue));
        }
        else
        if (sType == "s:")
        {
            sParameters += "s";
            SetLocalString(oDataObject, sVarName, sValue);
        }
        else
        if (sType == "i:")
        {
            sParameters += "i";
            SetLocalInt(oDataObject, sVarName, StringToInt(sValue));
        }
        else
        if (sType == "f:")
        {
            sParameters += "f";
            SetLocalFloat(oDataObject, sVarName, StringToFloat(sValue));
        }
        else
        if (sType == "l:")
        {
            sParameters += "l";
            SetLocalLocation(oDataObject, sVarName, ES_Util_StringToLocation(sValue));
        }
        else
        if (sType == "v:")
        {
            sParameters += "v";
            SetLocalVector(oDataObject, sVarName, ES_Util_StringToVector(sValue));
        }

        nCount++;
        nArgumentStart = nArgumentEnd + nArgumentDelimiterLength;
        nArgumentEnd = FindSubString(sArguments, MEDIATOR_ARGUMENT_DELIMITER, nArgumentStart);
    }

    return sParameters;
}

void Mediator_ClearReturnValue(object oDataObject, string sReturnType)
{
    if (sReturnType == "f")
        DeleteLocalFloat(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
    else
    if (sReturnType == "i")
        DeleteLocalInt(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
    else
    if (sReturnType == "l")
        DeleteLocalLocation(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
    else
    if (sReturnType == "o")
        DeleteLocalObject(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
    else
    if (sReturnType == "s")
        DeleteLocalString(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
    else
    if (sReturnType == "v")
        DeleteLocalVector(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

void Mediator_ClearFunctionVariables(object oDataObject, string sParameters)
{
    int nIndex, nLength = GetStringLength(sParameters);

    for (nIndex = 0; nIndex < nLength; nIndex++)
    {
        string sParameter = GetSubString(sParameters, nIndex, 1);
        string sVarName = MEDIATOR_FUNCTION_SCRIPT_VARIABLE + IntToString(nIndex);

        if (sParameter == "f")
            DeleteLocalFloat(oDataObject, sVarName);
        else
        if (sParameter == "i")
            DeleteLocalInt(oDataObject, sVarName);
        else
        if (sParameter == "l")
            DeleteLocalLocation(oDataObject, sVarName);
        else
        if (sParameter == "o")
            DeleteLocalObject(oDataObject, sVarName);
        else
        if (sParameter == "s")
            DeleteLocalString(oDataObject, sVarName);
        else
        if (sParameter == "v")
            DeleteLocalVector(oDataObject, sVarName);
    }
}

int Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments = "", object oTarget = OBJECT_SELF, int bWarn = TRUE)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int bReturn, nFunctionID = GetLocalInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);

    if (nFunctionID)
    {
        string sExpectedParameters = GetLocalString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));
        string sActualParameters = Mediator_SetFunctionVariables(sArguments);

        if (sExpectedParameters == sActualParameters)
        {
            string sReturnType = GetLocalString(oDataObject, MEDIATOR_FUNCTION_RETURN_TYPE + IntToString(nFunctionID));
            if (sReturnType != "")
                Mediator_ClearReturnValue(oDataObject, sReturnType);

            ExecuteScript(MEDIATOR_FUNCTION_SCRIPT_NAME + IntToString(nFunctionID), oTarget);

            bReturn = TRUE;
        }
        else
        {
            if (bWarn)
                ES_Util_Log(MEDIATOR_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Parameter Mismatch: EXPECTED: '" + sSubsystem + ":" +
                        sFunctionName + "(" + sExpectedParameters + ")' -> GOT: '" + sSubsystem + "::" + sFunctionName + "(" + sActualParameters + ")'");
        }

        Mediator_ClearFunctionVariables(oDataObject, sActualParameters);
    }
    else
    {
        if (bWarn)
            ES_Util_Log(MEDIATOR_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Function Not Registered: '" + sSubsystem + "::" + sFunctionName + "()'");
    }

    return bReturn;
}

float Mediator_GetReturnValueFloat()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalFloat(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

int Mediator_GetReturnValueInt()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalInt(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

location Mediator_GetReturnValueLocation()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalLocation(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

object Mediator_GetReturnValueObject()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalObject(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

string Mediator_GetReturnValueString()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalString(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

vector Mediator_GetReturnValueVector()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    return GetLocalVector(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
}

string Mediator_Object(object o)
{
    return "o:" + ObjectToString(o) + MEDIATOR_ARGUMENT_DELIMITER;
}

string Mediator_String(string s)
{
    return "s:" + s + MEDIATOR_ARGUMENT_DELIMITER;
}

string Mediator_Int(int i)
{
    return "i:" + IntToString(i) + MEDIATOR_ARGUMENT_DELIMITER;
}

string Mediator_Float(float f)
{
    return "f:" + FloatToString(f, 0) + MEDIATOR_ARGUMENT_DELIMITER;
}

string Mediator_Location(location l)
{
    return "l:" + ES_Util_LocationToString(l) + MEDIATOR_ARGUMENT_DELIMITER;
}

string Mediator_Vector(vector v)
{
    return "v:" + ES_Util_VectorToString(v) + MEDIATOR_ARGUMENT_DELIMITER;
}

