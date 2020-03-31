/*
    ScriptName: es_srv_mediator.nss
    Created by: Daz

    Description: An EventSystem Service that allows subsystems to call functions
                 from other subsystems without having to include them.
*/

//void main() {}

#include "es_inc_core"

const string MEDIATOR_LOG_TAG                   = "Mediator";
const string MEDIATOR_SCRIPT_NAME               = "es_srv_mediator";

const string MEDIATOR_NUM_FUNCTIONS             = "NumFunctions";

const string MEDIATOR_FUNCTION_ID               = "FunctionID_";
const string MEDIATOR_FUNCTION_NAME             = "FunctionName_";
const string MEDIATOR_FUNCTION_SUBSYSTEM        = "FunctionSubsystem_";
const string MEDIATOR_FUNCTION_PARAMETERS       = "FunctionParameters_";

const string MEDIATOR_TEMP_SCRIPT_NAME          = "srv_mediator_";
const string MEDIATOR_TEMP_VARIABLE             = "MEDIATOR_TEMP_VARIABLE_";

void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters);
int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****");
void Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF);

string Mediator_Object(object o);
string Mediator_String(string s);
string Mediator_Int(int n);
string Mediator_Float(float f);
string Mediator_Location(location l);

// *** INTERNAL FUNCTION
string Mediator_SetFunctionVariables(string sArguments);
// *** INTERNAL FUNCTION
string Mediator_ConvertShortType(string sShortType);

// @Post
void Mediator_Post(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nNumFunctions = ES_Util_GetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS);

    int nID;
    for (nID = 1; nID <= nNumFunctions; nID++)
    {
        string sFunctionName = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nID));
        string sSubsystem = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nID));
        string sParameters = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nID));
        string sScriptName = MEDIATOR_TEMP_SCRIPT_NAME + IntToString(nID);
        int nNumParameters = GetStringLength(sParameters);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Compiling '" + sScriptName + "' for function '" + sSubsystem + ":" + sFunctionName + "(" + sParameters + ")'");

        int nParameter;
        string sArguments, sVariables = nssObject("oModule", nssFunction("GetModule"));
        for (nParameter = 0; nParameter < nNumParameters; nParameter++)
        {
            string sParameter = GetSubString(sParameters, nParameter, 1);
            string sVarName = sParameter + "Variable" + IntToString(nParameter);
            string sType = Mediator_ConvertShortType(sParameter);

            sArguments += sVarName + ",";
            sVariables += nssVariable(GetStringLowerCase(sType), sVarName, nssFunction("ES_Util_Get" + sType, "oModule, " + nssEscapeDoubleQuotes(MEDIATOR_TEMP_VARIABLE + IntToString(nParameter))));
        }

        sArguments = GetSubString(sArguments, 0, GetStringLength(sArguments) - 1);

        string sError = ES_Util_AddScript(sScriptName, sSubsystem, sVariables + nssFunction(sFunctionName, sArguments));

        if (sError != "")
        {
            ES_Util_Log(MEDIATOR_LOG_TAG, "  > ERROR: Failed to compile '" + sScriptName + "' with error: " + sError);
        }
    }
}

void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    if (!ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName))
    {
        int nID = ES_Util_GetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS) + 1;

        ES_Util_SetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystemScript + "_" + sFunctionName, nID);

        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_NAME + IntToString(nID), sFunctionName);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_SUBSYSTEM + IntToString(nID), sSubsystemScript);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nID), sParameters);

        ES_Util_SetInt(oDataObject, MEDIATOR_NUM_FUNCTIONS, nID);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Subsystem '" + sSubsystemScript + "' registered function '" + sFunctionName + "(" + sParameters + ")'");
    }
}

int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****")
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    int nID = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);
    int bParametersMatch = sParameters == "****" ? TRUE :
        sParameters == ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nID));

    return nID && bParametersMatch;
}

void Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);
    int nFunctionID = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_ID + sSubsystem + "_" + sFunctionName);

    if (nFunctionID)
    {
        string sExpectedParameters = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + IntToString(nFunctionID));
        string sActualParameters = Mediator_SetFunctionVariables(sArguments);

        if (sExpectedParameters == sActualParameters)
        {
            ExecuteScript(MEDIATOR_TEMP_SCRIPT_NAME + IntToString(nFunctionID), oTarget);
        }
        else
        {
            ES_Util_Log(MEDIATOR_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Parameter Mismatch: EXPECTED: '" + sSubsystem + ":" +
                        sFunctionName + "(" + sExpectedParameters + ")' -> GOT: '" + sSubsystem + ":" + sFunctionName + "(" + sActualParameters + ")'");
        }

        ES_Util_DeleteVarRegex(GetModule(), MEDIATOR_TEMP_VARIABLE + ".*");
    }
    else
    {
        ES_Util_Log(MEDIATOR_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Function Not Registered: '" + sSubsystem + ":" + sFunctionName + "()'");
    }
}

string Mediator_Object(object o)
{
    return "o:" + ObjectToString(o) + "~";
}

string Mediator_String(string s)
{
    return "s:" + s + "~";
}

string Mediator_Int(int i)
{
    return "i:" + IntToString(i) + "~";
}

string Mediator_Float(float f)
{
    return "f:" + FloatToString(f, 0) + "~";
}

string Mediator_Location(location l)
{
    return "l:" + ES_Util_LocationToString(l) + "~";
}

string Mediator_SetFunctionVariables(string sArguments)
{
    object oModule = GetModule();
    string sParameters;
    int nArgumentStart = 0;
    int nArgumentEnd = FindSubString(sArguments, "~", nArgumentStart);
    int nCount = 0;

    while (nArgumentEnd != -1)
    {
        string sArgument = GetSubString(sArguments, nArgumentStart, nArgumentEnd - nArgumentStart);
        string sType = GetSubString(sArgument, 0, 2);
        string sValue = GetSubString(sArgument, 2, GetStringLength(sArgument) - 2);
        string sVarName = MEDIATOR_TEMP_VARIABLE + IntToString(nCount);

        if (sType == "o:")
        {
            sParameters += "o";
            ES_Util_SetObject(oModule, sVarName, NWNX_Object_StringToObject(sValue));
        }
        else
        if (sType == "s:")
        {
            sParameters += "s";
            ES_Util_SetString(oModule, sVarName, sValue);
        }
        else
        if (sType == "i:")
        {
            sParameters += "i";
            ES_Util_SetInt(oModule, sVarName, StringToInt(sValue));
        }
        else
        if (sType == "f:")
        {
            sParameters += "f";
            ES_Util_SetFloat(oModule, sVarName, StringToFloat(sValue));
        }
        else
        if (sType == "l:")
        {
            sParameters += "l";
            ES_Util_SetLocation(oModule, sVarName, ES_Util_StringToLocation(sValue));
        }

        nCount++;
        nArgumentStart = nArgumentEnd + 1;
        nArgumentEnd = FindSubString(sArguments, "~", nArgumentStart);
    }

    return sParameters;
}

string Mediator_ConvertShortType(string sShortType)
{
    if (sShortType == "o") return "Object";
    else
    if (sShortType == "s") return "String";
    else
    if (sShortType == "i") return "Int";
    else
    if (sShortType == "f") return "Float";
    else
    if (sShortType == "l") return "Location";
    else
    return "";
}

