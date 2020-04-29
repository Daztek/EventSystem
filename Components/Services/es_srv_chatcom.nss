/*
    ScriptName: es_srv_chatcom.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Service that allows registering of
                 chat commands by subsystems
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"

const string CHATCOMMAND_LOG_TAG                = "ChatCommand";
const string CHATCOMMAND_SCRIPT_NAME            = "es_srv_chatcom";

const string CHATCOMMAND_PARSE_ERROR            = "[PARSE_ERROR]";

const string CHATCOMMAND_GLOBAL_PREFIX          = "/";
const string CHATCOMMAND_HELP_COMMAND           = "help";

const string CHATCOMMAND_NUM_COMMANDS           = "NumCommands";
const string CHATCOMMAND_REGISTERED_COMMAND     = "RegisteredCommand_";

const string CHATCOMMAND_COMMAND                = "Command_";
const string CHATCOMMAND_PARAMS                 = "Params_";
const string CHATCOMMAND_DESCRIPTION            = "Description_";
const string CHATCOMMAND_SUBSYSTEM              = "Subsystem_";
const string CHATCOMMAND_FUNCTION               = "Function_";

const string CHATCOMMAND_PERMISSION_INCLUDE     = "PermissionInclude_";
const string CHATCOMMAND_PERMISSION_FUNCTION    = "PermissionFunction_";
const string CHATCOMMAND_PERMISSION_VALUE       = "PermissionValue_";
const string CHATCOMMAND_PERMISSION_COMPARISON  = "PermissionComparison_";

const string CHATCOMMAND_HELP_TEXT              = "HelpText_";

// Register a chat command
//
// sSubsystemScript: The subsystem the command is from, for example: es_s_example
// sFunction: The function name to execute when the player uses the chat command.
//            The implementation must have the following signature: void <Name>(object oPlayer, string sParams, int nVolume)
// sCommand: The command the player must type
// sHelpParams: Optional parameter description for /help
// sHelpDescription: A description of what the command does for /help
//
// Returns: the CommandId or -1 on error
int ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription);

// Set the permission of a chat command
//
// nCommandID: A CommandID from ChatCommand_Register()
// sInclude: The include file with the permission function or ""
// sFunction: The function to run, `oPlayer` can be used as argument
// sValue: The value to check
// sComparison: The comparison type, ==, !=, >= etc
void ChatCommand_SetPermission(int nCommandID, string sInclude, string sFunction, string sValue, string sComparison = "==");

// Send oPlayer an info message in the format of "sCommandName: sMessage"
void ChatCommand_SendInfoMessage(object oPlayer, string sCommandName, string sMessage);

// @Load
void ChatCommand_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    SetLocalString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + CHATCOMMAND_GLOBAL_PREFIX + CHATCOMMAND_HELP_COMMAND, sServiceScript);
}

// @Post
void ChatCommand_Post(string sServiceScript)
{
    ES_Util_ExecuteScriptChunk(sServiceScript, nssFunction("ChatCommand_CreateChatEventHandler", nssEscapeDoubleQuotes(sServiceScript)), GetModule());
}

string ChatCommand_Parse(string sMessage, string sCommand)
{
    int nLength = GetStringLength(sCommand);

    if (GetStringLeft(sMessage, nLength) == sCommand)
        return GetSubString(sMessage, nLength + 1, GetStringLength(sMessage) - nLength - 1);
    else
        return CHATCOMMAND_PARSE_ERROR;
}

void ChatCommand_ShowHelp(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    string sHelp = GetLocalString(oDataObject, CHATCOMMAND_HELP_TEXT + GetObjectUUID(oPlayer));

    if (sHelp == "")
    {
        int nNumCommands = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

        sHelp = "Available Chat Commands:\n";

        int nCommand;
        for (nCommand = 1; nCommand <= nNumCommands; nCommand++)
        {
            int bPermission;
            string sCommandID = IntToString(nCommand);

            string sPermissionFunction = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID);

            if (sPermissionFunction != "")
            {
                string sPermissionInclude = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID);
                string sPermissionValue = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID);
                string sPermissionComparison = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID);
                string sPermission = sPermissionFunction + " " + sPermissionComparison + " " + sPermissionValue;

                bPermission = ES_Util_ExecuteScriptChunkAndReturnInt(sPermissionInclude, sPermission, oPlayer, "oPlayer");
            }
            else
                bPermission = TRUE;

            string sCommand = GetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandID);
            string sParams = GetLocalString(oDataObject, CHATCOMMAND_PARAMS + sCommandID);
            string sDescription = GetLocalString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandID);

            if (bPermission)
                sHelp += "\n" + ES_Util_ColorString(sCommand + (sParams != "" ? " " + sParams : ""), "070") + " - " + sDescription;
        }

        SetLocalString(oDataObject, CHATCOMMAND_HELP_TEXT + GetObjectUUID(oPlayer), sHelp);
    }

    SendMessageToPC(oPlayer, sHelp);
    SetPCChatMessage("");
}

void ChatCommand_CreateChatEventHandler(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(sServiceScript);
    int nNumCommands = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

    if (!nNumCommands)
    {
        ES_Util_Log(CHATCOMMAND_LOG_TAG, "* No Chat Commands Registered");
        return;
    }

    ES_Util_Log(CHATCOMMAND_LOG_TAG, "* Registered '" + IntToString(nNumCommands) + "' Chat Command" + (nNumCommands > 1 ? "s" : ""));

    string sIncludes, sCommands;

    int nCommand;
    for (nCommand = 0; nCommand <= nNumCommands; nCommand++)
    {
        if (!nCommand)
        {
            sIncludes += nssInclude(sServiceScript);
            sCommands += nssIfStatement("(sParams = " + nssFunction("ChatCommand_Parse", "sMessage, " +
                         nssEscapeDoubleQuotes(CHATCOMMAND_GLOBAL_PREFIX + CHATCOMMAND_HELP_COMMAND), FALSE) + ")", "!=", nssEscapeDoubleQuotes(CHATCOMMAND_PARSE_ERROR)) +
                         nssBrackets(nssFunction("ChatCommand_ShowHelp", "oPlayer, sParams, nVolume"));
        }
        else
        {
            string sPermission, sCommandID = IntToString(nCommand);
            string sCommand = GetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandID);
            string sFunction = nssFunction(GetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID), "oPlayer, sParams, nVolume");

            string sInclude = GetLocalString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandID);

            if (FindSubString(sIncludes, sInclude) == -1)
                sIncludes += nssInclude(sInclude);

            string sPermissionFunction = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID);

            if (sPermissionFunction != "")
            {
                string sPermissionInclude = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID);

                if (sPermissionInclude != "" && FindSubString(sIncludes, sPermissionInclude) == -1)
                    sIncludes += nssInclude(sPermissionInclude);

                string sPermissionValue = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID);
                string sPermissionComparison = GetLocalString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID);

                sPermission = nssIfStatement(sPermissionFunction, sPermissionComparison, sPermissionValue) + nssBrackets(sFunction);
            }

            sCommands += nssElseIfStatement("(sParams = " + nssFunction("ChatCommand_Parse" , "sMessage, " +
                         nssEscapeDoubleQuotes(sCommand), FALSE) + ")", "!=", nssEscapeDoubleQuotes("[PARSE_ERROR]")) +
                         nssBrackets(sPermission != "" ? sPermission : sFunction);
        }
    }

    string sEventHandler = sIncludes + nssVoidMain(
                                          nssObject("oPlayer", nssFunction("GetPCChatSpeaker")) +
                                          nssString("sMessage", nssFunction("GetPCChatMessage")) +
                                          nssInt("nVolume", nssFunction("GetPCChatVolume")) +
                                          nssString("sParams") +
                                          sCommands);

    string sReturn = NWNX_Util_AddScript(sServiceScript, sEventHandler);

    if (sReturn != "")
        ES_Util_Log(CHATCOMMAND_LOG_TAG, "  > ERROR: Failed to compile Event Handler with error: " + sReturn);
    else
        Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

int ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return -1;

    sCommand = GetStringLowerCase(sCommand);
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);

    ES_Util_Log(CHATCOMMAND_LOG_TAG, "* Registering Chat Command -> '" + sCommand + "' for Subsystem '" + sSubsystemScript + "' with Function: " + sFunction + "()");

    string sCommandRegisteredBy = GetLocalString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + sCommand);
    if (sCommandRegisteredBy != "")
    {
        ES_Util_Log(CHATCOMMAND_LOG_TAG, "  > ERROR: Chat Command -> '" + sCommand + "' has already been registered by: " + sCommandRegisteredBy);
        return -1;
    }

    int nCommandID = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS) + 1;
    string sCommandID = IntToString(nCommandID);

    SetLocalString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + sCommand, sSubsystemScript);
    SetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS, nCommandID);

    SetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandID, sCommand);
    SetLocalString(oDataObject, CHATCOMMAND_PARAMS + sCommandID, sHelpParams);
    SetLocalString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandID, sHelpDescription);
    SetLocalString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandID, sSubsystemScript);
    SetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID, sFunction);

    return nCommandID;
}

void ChatCommand_SetPermission(int nCommandID, string sInclude, string sFunction, string sValue, string sComparison = "==")
{
    if (nCommandID <= 0) return;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    string sCommandID = IntToString(nCommandID);

    ES_Util_Log(CHATCOMMAND_LOG_TAG, "  > Setting Permission for Chat Command -> '" + sFunction + (sComparison != "" ? " " + sComparison + " " : "") + sValue + "'");

    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID, sInclude);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID, sFunction);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID, sValue);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID, sComparison);
}

void ChatCommand_SendInfoMessage(object oPlayer, string sCommandName, string sMessage)
{
    SendMessageToPC(oPlayer, ES_Util_ColorString(sCommandName + ": ", "070") + sMessage);
}

