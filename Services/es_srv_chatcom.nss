/*
    ScriptName: es_srv_chatcom.nss
    Created by: Daz

    Description: An EventSystem Service that allows registering of
                 chat commands by subsystems
*/

//void main() {}

#include "es_inc_core"

const string CHATCOMMAND_LOG_TAG                = "ChatCommand";
const string CHATCOMMAND_SCRIPT_NAME            = "es_srv_chatcom";

const string CHATCOMMAND_GLOBAL_PREFIX          = "/";
const string CHATCOMMAND_HELP_COMMAND           = "help";

const string CHATCOMMAND_NUM_COMMANDS           = "ChatCommandNumCommands";
const string CHATCOMMAND_REGISTERED_COMMAND     = "ChatCommandRegisteredCommand_";

const string CHATCOMMAND_COMMAND                = "ChatCommandCommand_";
const string CHATCOMMAND_PARAMS                 = "ChatCommandParams_";
const string CHATCOMMAND_DESCRIPTION            = "ChatCommandDescription_";
const string CHATCOMMAND_SUBSYSTEM              = "ChatCommandSubsystem_";
const string CHATCOMMAND_FUNCTION               = "ChatCommandFunction_";

const string CHATCOMMAND_PERMISSION_INCLUDE     = "ChatCommandPermissionInclude_";
const string CHATCOMMAND_PERMISSION_FUNCTION    = "ChatCommandPermissionFunction_";
const string CHATCOMMAND_PERMISSION_VALUE       = "ChatCommandPermissionValue_";
const string CHATCOMMAND_PERMISSION_COMPARISON  = "ChatCommandPermissionComparison_";

const string CHATCOMMAND_HELP_TEXT              = "ChatCommandHelpText_";

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

// @Load
void ChatCommand_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    ES_Util_SetString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + CHATCOMMAND_GLOBAL_PREFIX + CHATCOMMAND_HELP_COMMAND, sServiceScript);
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
        return "[PARSE_ERROR]";
}

void ChatCommand_ShowHelp(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    string sHelp = ES_Util_GetString(oDataObject, CHATCOMMAND_HELP_TEXT + GetObjectUUID(oPlayer));

    if (sHelp == "")
    {
        int nNumCommands = ES_Util_GetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

        sHelp = "Available Chat Commands:\n";

        int nCommand;
        for (nCommand = 1; nCommand <= nNumCommands; nCommand++)
        {
            int bPermission;
            string sCommandID = IntToString(nCommand);

            string sPermissionFunction = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID);

            if (sPermissionFunction != "")
            {
                string sPermissionInclude = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID);
                string sPermissionValue = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID);
                string sPermissionComparison = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID);
                string sPermission = sPermissionFunction + " " + sPermissionComparison + " " + sPermissionValue;

                bPermission = ES_Util_ExecuteScriptChunkAndReturnInt(sPermissionInclude, sPermission, oPlayer, "oPlayer");
            }
            else
                bPermission = TRUE;

            string sCommand = ES_Util_GetString(oDataObject, CHATCOMMAND_COMMAND + sCommandID);
            string sParams = ES_Util_GetString(oDataObject, CHATCOMMAND_PARAMS + sCommandID);
            string sDescription = ES_Util_GetString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandID);

            if (bPermission)
                sHelp += "\n" + ES_Util_ColorString(sCommand + (sParams != "" ? " " + sParams : ""), "070") + " - " + sDescription;
        }

        ES_Util_SetString(oDataObject, CHATCOMMAND_HELP_TEXT + GetObjectUUID(oPlayer), sHelp);
    }

    SendMessageToPC(oPlayer, sHelp);
    SetPCChatMessage("");
}

void ChatCommand_CreateChatEventHandler(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(sServiceScript);
    int nNumCommands = ES_Util_GetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

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
                         nssEscapeDoubleQuotes(CHATCOMMAND_GLOBAL_PREFIX + CHATCOMMAND_HELP_COMMAND), FALSE) + ")", "!=", nssEscapeDoubleQuotes("[PARSE_ERROR]")) +
                         nssBrackets(nssFunction("ChatCommand_ShowHelp", "oPlayer, sParams, nVolume"));
        }
        else
        {
            string sPermission, sCommandID = IntToString(nCommand);
            string sCommand = ES_Util_GetString(oDataObject, CHATCOMMAND_COMMAND + sCommandID);
            string sFunction = nssFunction(ES_Util_GetString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID), "oPlayer, sParams, nVolume");

            string sInclude = ES_Util_GetString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandID);

            if (FindSubString(sIncludes, sInclude) == -1)
                sIncludes += nssInclude(sInclude);

            string sPermissionFunction = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID);

            if (sPermissionFunction != "")
            {
                string sPermissionInclude = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID);

                if (sPermissionInclude != "" && FindSubString(sIncludes, sPermissionInclude) == -1)
                    sIncludes += nssInclude(sPermissionInclude);

                string sPermissionValue = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID);
                string sPermissionComparison = ES_Util_GetString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID);

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
        ES_Core_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

int ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return -1;

    sCommand = GetStringLowerCase(sCommand);
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);

    ES_Util_Log(CHATCOMMAND_LOG_TAG, "* Registering Chat Command -> '" + sCommand + "' for Subsystem '" + sSubsystemScript + "' with Function: " + sFunction + "()");

    string sCommandRegisteredBy = ES_Util_GetString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + sCommand);
    if (sCommandRegisteredBy != "")
    {
        ES_Util_Log(CHATCOMMAND_LOG_TAG, "  > ERROR: Chat Command -> '" + sCommand + "' has already been registered by: " + sCommandRegisteredBy);
        return -1;
    }

    int nCommandID = ES_Util_GetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS) + 1;
    string sCommandID = IntToString(nCommandID);

    ES_Util_SetString(oDataObject, CHATCOMMAND_REGISTERED_COMMAND + sCommand, sSubsystemScript);
    ES_Util_SetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS, nCommandID);

    ES_Util_SetString(oDataObject, CHATCOMMAND_COMMAND + sCommandID, sCommand);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PARAMS + sCommandID, sHelpParams);
    ES_Util_SetString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandID, sHelpDescription);
    ES_Util_SetString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandID, sSubsystemScript);
    ES_Util_SetString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID, sFunction);

    return nCommandID;
}

void ChatCommand_SetPermission(int nCommandID, string sInclude, string sFunction, string sValue, string sComparison = "==")
{
    if (nCommandID <= 0) return;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SCRIPT_NAME);
    string sCommandID = IntToString(nCommandID);

    ES_Util_Log(CHATCOMMAND_LOG_TAG, "  > Setting Permission for Chat Command -> '" + sFunction + (sComparison != "" ? " " + sComparison + " " : "") + sValue + "'");

    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID, sInclude);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID, sFunction);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID, sValue);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID, sComparison);
}

