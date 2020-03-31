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

const string MEDIATOR_FUNCTION_NAME             = "FunctionName_";
const string MEDIATOR_FUNCTION_PARAMETERS       = "FunctionParameters_";

struct Mediator_FunctionData
{
    string sParameters;
    string sArguments;
};

void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters);
int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****");
void Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF);

string Mediator_Object(object o);
string Mediator_String(string s);
string Mediator_Int(int n);
string Mediator_Float(float f);
string Mediator_Location(location l);

// *** INTERNAL FUNCTION
struct Mediator_FunctionData Mediator_GetFunctionData(string sArguments);

void Mediator_RegisterFunction(string sSubsystemScript, string sFunctionName, string sParameters)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    if (!ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_NAME + sSubsystemScript + "_" + sFunctionName))
    {
        ES_Util_SetInt(oDataObject, MEDIATOR_FUNCTION_NAME + sSubsystemScript + "_" + sFunctionName, TRUE);
        ES_Util_SetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + sSubsystemScript + "_" + sFunctionName, sParameters);

        ES_Util_Log(MEDIATOR_LOG_TAG, "Subsystem '" + sSubsystemScript + "' registered function '" + sFunctionName + "(" + sParameters + ")'");
    }
}

int Mediator_GetIsFunctionRegistered(string sSubsystem, string sFunctionName, string sParameters = "****")
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    int bRegistered = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_NAME + sSubsystem + "_" + sFunctionName);
    int bParametersMatch = sParameters == "****" ? TRUE :
        sParameters == ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + sSubsystem + "_" + sFunctionName);

    return bRegistered && bParametersMatch;
}

void Mediator_ExecuteFunction(string sSubsystem, string sFunctionName, string sArguments, object oTarget = OBJECT_SELF)
{
    object oDataObject = ES_Util_GetDataObject(MEDIATOR_SCRIPT_NAME);

    int bFunctionRegistered = ES_Util_GetInt(oDataObject, MEDIATOR_FUNCTION_NAME + sSubsystem + "_" + sFunctionName);

    if (bFunctionRegistered)
    {
        string sParameters = ES_Util_GetString(oDataObject, MEDIATOR_FUNCTION_PARAMETERS + sSubsystem + "_" + sFunctionName);

        struct Mediator_FunctionData fd = Mediator_GetFunctionData(sArguments);

        if (sParameters == fd.sParameters)
        {
            string sFunction = nssFunction(sFunctionName, fd.sArguments);
            string sError = ES_Util_ExecuteScriptChunk(sSubsystem, sFunction, oTarget);

            if (sError != "")
            {
                ES_Util_Log(MEDIATOR_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Failed to Execute Function: '" + sFunction + "' -> ERROR: '" + sError + "'");
            }
        }
        else
        {
            ES_Util_Log(MEDIATOR_LOG_TAG, "ERROR: (" + NWNX_Util_GetCurrentScriptName() + ") Parameter Mismatch: EXPECTED: '" +
                        sFunctionName + "(" + sParameters + ")' -> GOT: '" + sFunctionName + "(" + fd.sParameters + ")'");
        }
    }
    else
    {
        ES_Util_Log(MEDIATOR_LOG_TAG, "WARNING: (" + NWNX_Util_GetCurrentScriptName() + ") Function Not Registered: '" + sFunctionName + "()'");
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

struct Mediator_FunctionData Mediator_GetFunctionData(string sArguments)
{
    struct Mediator_FunctionData fd;

    int nArgumentStart = 0;
    int nArgumentEnd = FindSubString(sArguments, "~", nArgumentStart);

    while (nArgumentEnd != -1)
    {
        string sArgument = GetSubString(sArguments, nArgumentStart, nArgumentEnd - nArgumentStart);
        string sType = GetSubString(sArgument, 0, 2);
        string sValue = GetSubString(sArgument, 2, GetStringLength(sArgument) - 2);

        if (sType == "o:")
        {
            fd.sParameters += "o";
            fd.sArguments += nssFunction("NWNX_Object_StringToObject", nssEscapeDoubleQuotes(sValue), FALSE) + ",";
        }
        else
        if (sType == "s:")
        {
            fd.sParameters += "s";
            fd.sArguments += nssEscapeDoubleQuotes(sValue) + ",";
        }
        else
        if (sType == "i:")
        {
            fd.sParameters += "i";
            fd.sArguments += sValue + ",";
        }
        else
        if (sType == "f:")
        {
            fd.sParameters += "f";
            fd.sArguments += sValue + "f,";
        }
        else
        if (sType == "l:")
        {
            fd.sParameters += "l";
            fd.sArguments += nssFunction("ES_Util_StringToLocation", nssEscapeDoubleQuotes(sValue), FALSE) + ",";
        }

        nArgumentStart = nArgumentEnd + 1;
        nArgumentEnd = FindSubString(sArguments, "~", nArgumentStart);
    }

    fd.sArguments = GetSubString(fd.sArguments, 0, GetStringLength(fd.sArguments) - 1);

    return fd;
}

