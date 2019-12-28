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

const string CHATCOMMAND_HELP_TEXT              = "ChatCommandHelpText";

// Register a chat command
//
// sSubsystemScript: The subsystem the command is from, for example: es_s_chatcommand
// sFunction: The function name to execute when the player uses the chat command.
//            The implementation must have the following signature: void <Name>(object oPlayer, string sParams, int nVolume)
// sCommand: The command the player must type
// sHelpParams: Optional parameter description for !help
// sHelpDescription: A description of what the command does for /help
void ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription);

// @EventSystem_Init
void ChatCommand_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
}

// @EventSystem_EventHandler
void ChatCommand_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_MODULE_LOAD)
        ES_Util_ExecuteScriptChunk("es_s_chatcommand", "ChatCommand_CreateChatEventHandler(\"" + sEventHandlerScript + "\");", GetModule());
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
    string sHelp = GetLocalString(oDataObject, CHATCOMMAND_HELP_TEXT);

    if (sHelp == "")
    {
        int nNumCommands = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS);

        sHelp = "Available Chat Commands:\n";

        int nCommand;
        for (nCommand = 1; nCommand <= nNumCommands; nCommand++)
        {
            string sCommand = GetLocalString(oDataObject, CHATCOMMAND_COMMAND + IntToString(nCommand));
            string sParams = GetLocalString(oDataObject, CHATCOMMAND_PARAMS + IntToString(nCommand));
            string sDescription = GetLocalString(oDataObject, CHATCOMMAND_DESCRIPTION + IntToString(nCommand));

            sHelp += "\n" + sCommand + (sParams != "" ? " " + sParams : "") + " - " + sDescription;
        }

        SetLocalString(oDataObject, CHATCOMMAND_HELP_TEXT, sHelp);
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
            sIncludes += "#" + "include \"es_s_chatcommand\" ";
            sCommands += "if ((sParams = ChatCommand_Parse(sMessage, \"" + CHATCOMMAND_GLOBAL_PREFIX + "help\")) != \"[PARSE_ERROR]\") { ChatCommand_ShowHelp(oPlayer, sParams, nVolume); } ";
        }
        else
        {
            string sCommandNum = IntToString(nCommand);

            string sCommand = GetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandNum);
            string sFunction = GetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandNum);
            string sInclude = GetLocalString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandNum);

            if (FindSubString(sIncludes, sInclude) == -1)
                sIncludes += "#" + "include \"" + sInclude + "\" ";

            sCommands += "else if ((sParams = ChatCommand_Parse(sMessage, \"" + sCommand + "\")) != \"[PARSE_ERROR]\") { " +sFunction + "(oPlayer, sParams, nVolume); } ";
        }
    }

    string sEventHandler = sIncludes + " void main() { object oPlayer = GetPCChatSpeaker(); string sMessage = GetPCChatMessage(); " +
        "int nVolume = GetPCChatVolume(); string sParams; " + sCommands + " }";

    string sReturn = NWNX_Util_AddScript(sEventHandlerScript, sEventHandler);

    if (sReturn != "")
        ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "  > FAILED: " + sReturn);
    else
        ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

void ChatCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return;

    object oDataObject = ES_Util_GetDataObject(CHATCOMMAND_SYSTEM_TAG);
    int nCommandNumber = GetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS) + 1;
    string sCommandNumber = IntToString(nCommandNumber);

    sSubsystemScript = "es_s_" + GetSubString(sSubsystemScript, 5, GetStringLength(sSubsystemScript) - 5);

    sCommand = GetStringLowerCase(sCommand);

    ES_Util_Log(CHATCOMMAND_SYSTEM_TAG, "* Registering chat command '" + sCommand + "' for subsystem '" + sSubsystemScript + "' with function: " + sFunction + "()");

    SetLocalInt(oDataObject, CHATCOMMAND_NUM_COMMANDS, nCommandNumber);

    SetLocalString(oDataObject, CHATCOMMAND_COMMAND + sCommandNumber, sCommand);
    if (sHelpParams != "")
        SetLocalString(oDataObject, CHATCOMMAND_PARAMS + sCommandNumber, sHelpParams);
    SetLocalString(oDataObject, CHATCOMMAND_DESCRIPTION + sCommandNumber, sHelpDescription);
    SetLocalString(oDataObject, CHATCOMMAND_SUBSYSTEM + sCommandNumber, sSubsystemScript);
    SetLocalString(oDataObject, CHATCOMMAND_FUNCTION + sCommandNumber, sFunction);
}

