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
// sHelpParams: Optional parameter description for !help
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
void ChatCommand_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
}

// @EventSystem_EventHandler
void ChatCommand_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_MODULE_LOAD)
        ES_Util_ExecuteScriptChunk("es_s_chatcommand", "ChatCommand_CreateChatEventHandler(" + nssEscapeDoubleQuotes(sEventHandlerScript) + ");", GetModule());
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
    string sHelp = GetLocalString(oPlayer, CHATCOMMAND_HELP_TEXT);

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
                sHelp += "\n" + sCommand + (sParams != "" ? " " + sParams : "") + " - " + sDescription;
        }

        SetLocalString(oPlayer, CHATCOMMAND_HELP_TEXT, sHelp);
    }

    SendMessageToPC(oPlayer, sHelp);
    SetPCChatMessage("");
}

void ChatCommand_CreateChatEventHandler(string sEventHandlerScript)
{
    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    int nNumCommands = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

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
            sIncludes += nssInclude("es_s_chatcommand");
            sCommands += nssIfStatement("(sParams = ChatCommand_Parse(sMessage, " + nssEscapeDoubleQuotes(CHATCOMMAND_GLOBAL_PREFIX + "help") + "))", "!=", nssEscapeDoubleQuotes("[PARSE_ERROR]")) +
                         nssBrackets("ChatCommand_ShowHelp(oPlayer, sParams, nVolume);");
        }
        else
        {
            string sPermission, sCommandID = IntToString(nCommand);
            string sCommand = GetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandID);
            string sFunction = GetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID);

            sFunction += "(oPlayer, sParams, nVolume);";

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

            sCommands += nssElseIfStatement("(sParams = ChatCommand_Parse(sMessage, " + nssEscapeDoubleQuotes(sCommand) + "))", "!=", nssEscapeDoubleQuotes("[PARSE_ERROR]")) +
                         nssBrackets(sPermission != "" ? sPermission : sFunction);
        }
    }

    string sEventHandler = sIncludes + nssVoidMain(
                                          nssObject("oPlayer", "GetPCChatSpeaker()") +
                                          nssString("sMessage", "GetPCChatMessage()") +
                                          nssInt("nVolume", "GetPCChatVolume()") +
                                          nssString("sParams") +
                                          sCommands);

    string sReturn = NWNX_Util_AddScript(sEventHandlerScript, sEventHandler);

    if (sReturn != "")
        ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "  > FAILED: " + sReturn);
    else
        ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

int ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return -1;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    int nCommandID = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS) + 1;
    string sCommandID = IntToString(nCommandID);

    sSubsystemScript = "es_s_" + GetSubString(sSubsystemScript, 5, GetStringLength(sSubsystemScript) - 5);

    sCommand = GetStringLowerCase(sCommand);

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "* Registering chat command " + sCommandID + ": '" + sCommand + "' for subsystem '" + sSubsystemScript + "' with function: " + sFunction + "()");

    SetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS, nCommandID);

    SetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandID, sCommand);
    if (sHelpParams != "")
        SetLocalString(oDataObject, CHATCOMMAND_PARAMS + sCommandID, sHelpParams);
    SetLocalString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandID, sHelpDescription);
    SetLocalString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandID, sSubsystemScript);
    SetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandID, sFunction);

    return nCommandID;
}

void ChatCommand_SetPermission(int nCommandID, string sInclude, string sFunction, string sValue, string sComparison = "==")
{
    if (nCommandID <= 0) return;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    string sCommandID = IntToString(nCommandID);

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "  > Setting chat command permission: '" + sFunction + (sComparison != "" ? " " + sComparison + " " : "") + sValue + "'");

    if (sInclude != "")
        SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_INCLUDE + sCommandID, sInclude);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_FUNCTION + sCommandID, sFunction);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_VALUE + sCommandID, sValue);
    SetLocalString(oDataObject, CHATCOMMAND_PERMISSION_COMPARISON + sCommandID, sComparison);
}

