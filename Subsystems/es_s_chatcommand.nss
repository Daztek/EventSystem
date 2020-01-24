/*
    ScriptName: es_s_chatcommand.nss
    Created by: Daz

    Description: A subsystem that allows registering of chat commands by other subsystems

    @EventSystem_ForceRecompile
*/

//void main() {}

#include "es_inc_core"

const string CHATCOMMAND_SYSTEM_TAG             = "ChatCommand";

const string CHATCOMMAND_GLOBAL_PREFIX          = "/";

const string CHATCOMMAND_NUM_COMMANDS           = "ChatHandlerNumCommands";

const string CHATCOMMAND_COMMAND                = "ChatCommandCommand_";
const string CHATCOMMAND_PARAMS                 = "ChatCommandParams_";
const string CHATCOMMAND_DESCRIPTION            = "ChatCommandDescription_";
const string CHATCOMMAND_SUBSYSTEM              = "ChatCommandSubsystem_";
const string CHATCOMMAND_FUNCTION               = "ChatCommandFunction_";

const string CHATCOMMAND_PERMISSION_INCLUDE     = "ChatCommandPermissionInclude_";
const string CHATCOMMAND_PERMISSION_FUNCTION    = "ChatCommandPermissionFunction_";
const string CHATCOMMAND_PERMISSION_VALUE       = "ChatCommandPermissionValue_";
const string CHATCOMMAND_PERMISSION_COMPARISON  = "ChatCommandPermissionComparison_";

const string CHATCOMMAND_HELP_TEXT              = "ChatCommandHelpText";

// Register a chat command
//
// sSubsystemScript: The subsystem the command is from, for example: es_s_chatcommand
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

// @EventSystem_Init
void ChatCommand_Init(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
}

// @EventSystem_EventHandler
void ChatCommand_EventHandler(string sSubsystemScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_MODULE_LOAD)
        ES_Util_ExecuteScriptChunk(sSubsystemScript, nssFunction("ChatCommand_CreateChatEventHandler", nssEscapeDoubleQuotes(sSubsystemScript)), GetModule());
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
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    string sHelp = ES_Util_GetString(oPlayer, CHATCOMMAND_HELP_TEXT);

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
                sHelp += "\n" + sCommand + (sParams != "" ? " " + sParams : "") + " - " + sDescription;
        }

        ES_Util_SetString(oPlayer, CHATCOMMAND_HELP_TEXT, sHelp);
    }

    SendMessageToPC(oPlayer, sHelp);
    SetPCChatMessage("");
}

void ChatCommand_CreateChatEventHandler(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    int nNumCommands = ES_Util_GetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

    if (!nNumCommands)
    {
        ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "* No Chat Commands Registered");
        return;
    }

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "* Registered '" + IntToString(nNumCommands) + "' Chat Command" + (nNumCommands > 1 ? "s" : ""));

    string sIncludes, sCommands;

    int nCommand;
    for (nCommand = 0; nCommand <= nNumCommands; nCommand++)
    {
        if (!nCommand)
        {
            sIncludes += nssInclude(sSubsystemScript);
            sCommands += nssIfStatement("(sParams = " + nssFunction("ChatCommand_Parse", "sMessage, " +
                         nssEscapeDoubleQuotes(CHATCOMMAND_GLOBAL_PREFIX + "help"), FALSE) + ")", "!=", nssEscapeDoubleQuotes("[PARSE_ERROR]")) +
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

    string sReturn = NWNX_Util_AddScript(sSubsystemScript, sEventHandler);

    if (sReturn != "")
        ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "  > ERROR: Failed to compile Event Handler with error: " + sReturn);
    else
        ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

int ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return -1;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    int nCommandID = ES_Util_GetInt(oDataObject, CHATCOMMAND_NUM_COMMANDS) + 1;
    string sCommandID = IntToString(nCommandID);

    sSubsystemScript = "es_s_" + GetSubString(sSubsystemScript, 5, GetStringLength(sSubsystemScript) - 5);

    sCommand = GetStringLowerCase(sCommand);

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "* Registering Chat Command -> '" + sCommand + "' for Subsystem '" + sSubsystemScript + "' with Function: " + sFunction + "()");

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

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    string sCommandID = IntToString(nCommandID);

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "  > Setting Permission for Chat Command -> '" + sFunction + (sComparison != "" ? " " + sComparison + " " : "") + sValue + "'");

    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID, sInclude);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID, sFunction);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID, sValue);
    ES_Util_SetString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID, sComparison);
}

