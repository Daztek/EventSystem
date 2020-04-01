/*
    ScriptName: es_srv_mediator.nss
    Created by: Daz

    Description: An EventSystem Service that allows subsystems to call functions
                 from other subsystems without having to include them.
*/

//void main() {}

#include "es_inc_core"

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
// - sReturnType: The return type of the function, must match the function's definition
//                Only supports the following types: void, object, string, int, float, location, vector
//
// Example:
//  string MySubsystemFunction(int nFoo, object oBar, string sBaz);
//  Mediator_RegisterFunction("es_s_subsystem", "MySubsystemFunction", "ios", "string");
void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters, string sReturnType = "void");
// Returns TRUE if sSubsystem has registered sFunctionName, with an optional parameter check.
int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****");
// Execute sFunctionName from sSubsystem with sArguments on oTarget
//
// Example:
//   Mediator_ExecuteFunction("es_s_subsystem", "MySubsystemFunction", Mediator_Object(GetModule()) + Mediator_Int(1337) + Mediator_String("Test"));
//
// Returns: TRUE on success
int Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF);
// Get the return value as string from the last function executed with Mediator_ExecuteFunction()
// You'll have to convert it to the right type yourself.
string Mediator_GetLastReturnValue();

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
    int nFunctionID, nNumFunctions = ES_Util_GetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS);

    for (nFunctionID = 1; nFunctionID <= nNumFunctions; nFunctionID++)
    {
        string sFunctionName = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nFunctionID));
        string sSubsystem = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nFunctionID));
        string sReturnType = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_RETURN_TYPE + IntToString(nFunctionID));
        string sParameters = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));
        string sScriptName = MEDIATOR_FUNCTION_SCRIPT_NAME + IntToString(nFunctionID);
        string sFunction, sArguments, sVariables = nssObject("oDataObject", nssFunction("ES_Util_GetDataObject", nssEscapeDoubleQuotes(MEDIATOR_SCRIPT_NAME)));
        int nParameter, nNumParameters = GetStringLength(sParameters);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Compiling Script '" + sScriptName + "' for Function '" + sReturnType + " " + sSubsystem + "::" + sFunctionName + "(" + sParameters + ")'");

        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            string sParameter = GetSubString(sParameters, nParameter, 1);
            string sVarName = sParameter + "Variable" + IntToString(nParameter);
            string sType = nssConvertShortType(sParameter);

            if (sType != "")
            {
                sArguments += sVarName + ",";
                sVariables += nssVariable(GetStringLowerCase(sType), sVarName, nssFunction("ES_Util_Get" + sType, "oDataObject, " +
                              nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_VARIABLE + IntToString(nParameter))));
            }
        }

        sArguments = GetSubString(sArguments, 0, GetStringLength(sArguments) - 1);

        if (sReturnType == "object")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction("ObjectToString",nssFunction(sFunctionName, sArguments, FALSE), FALSE));
        }
        else
        if (sReturnType == "string")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction(sFunctionName, sArguments, FALSE));
        }
        else
        if (sReturnType == "int")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction("IntToString", nssFunction(sFunctionName, sArguments, FALSE), FALSE));
        }
        else
        if (sReturnType == "float")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction("FloatToString", "0, " + nssFunction(sFunctionName, sArguments, FALSE), FALSE));
        }
        else
        if (sReturnType == "location")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction("ES_Util_LocationToString", nssFunction(sFunctionName, sArguments, FALSE), FALSE));
        }
        else
        if (sReturnType == "vector")
        {
            sFunction = nssFunction("ES_Util_SetString", "oDataObject, " + nssEscapeDoubleQuotes(MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE) + ", " +
                        nssFunction("ES_Util_VectorToString", nssFunction(sFunctionName, sArguments, FALSE), FALSE));
        }
        else
        {// Assume void for everything else
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

    if (!ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName))
    {
        int nFunctionID = ES_Util_GetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS) + 1;

        sParameters = GetStringLowerCase(sParameters);
        sReturnType = GetStringLowerCase(sReturnType);

        ES_Util_SetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS, nFunctionID);
        ES_Util_SetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName, nFunctionID);

        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nFunctionID), sFunctionName);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nFunctionID), sSubsystemScript);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_RETURN_TYPE + IntToString(nFunctionID), sReturnType);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID), sParameters);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Subsystem '" + sSubsystemScript + "' registered function '" + sReturnType + " " + sFunctionName + "(" + sParameters + ")'");
    }
}

int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****")
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nFunctionID = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);
    int bParametersMatch = sParameters == "****" ? TRUE :
        sParameters == ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));

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
            ES_Util_SetObject(oDataObject, sVarName, NWNX_Object_StringToObject(sValue));
        }
        else
        if (sType == "s:")
        {
            sParameters += "s";
            ES_Util_SetString(oDataObject, sVarName, sValue);
        }
        else
        if (sType == "i:")
        {
            sParameters += "i";
            ES_Util_SetInt(oDataObject, sVarName, StringToInt(sValue));
        }
        else
        if (sType == "f:")
        {
            sParameters += "f";
            ES_Util_SetFloat(oDataObject, sVarName, StringToFloat(sValue));
        }
        else
        if (sType == "l:")
        {
            sParameters += "l";
            ES_Util_SetLocation(oDataObject, sVarName, ES_Util_StringToLocation(sValue));
        }
        else
        if (sType == "v:")
        {
            sParameters += "v";
            ES_Util_SetVector(oDataObject, sVarName, ES_Util_StringToVector(sValue));
        }

        nCount++;
        nArgumentStart = nArgumentEnd + nArgumentDelimiterLength;
        nArgumentEnd = FindSubString(sArguments, MEDIATOR_ARGUMENT_DELIMITER, nArgumentStart);
    }

    return sParameters;
}

int Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int bReturn, nFunctionID = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);

    if (nFunctionID)
    {
        string sExpectedParameters = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));
        string sActualParameters = Mediator_SetFunctionVariables(sArguments);

        ES_Util_DeleteString(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);

        if (sExpectedParameters == sActualParameters)
        {
            ExecuteScript(MEDIATOR_FUNCTION_SCRIPT_NAME + IntToString(nFunctionID), oTarget);
            bReturn = TRUE;
        }
        else
        {
            ES_Util_Log(MEDIATOR_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Parameter Mismatch: EXPECTED: '" + sSubsystem + ":" +
                        sFunctionName + "(" + sExpectedParameters + ")' -> GOT: '" + sSubsystem + "::" + sFunctionName + "(" + sActualParameters + ")'");
        }

        ES_Util_DeleteVarRegex(oDataObject, MEDIATOR_FUNCTION_SCRIPT_VARIABLE + ".*");
    }
    else
    {
        ES_Util_Log(MEDIATOR_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Function Not Registered: '" + sSubsystem + "::" + sFunctionName + "()'");
    }

    return bReturn;
}

string Mediator_GetLastReturnValue()
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    return ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_SCRIPT_RETURN_VALUE);
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

