/*
    ScriptName: es_cc_concom.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Util]

    Description: An EventSystem Core Component that allows Services
                 and Subsystems to register server console commands
*/

//void main() {}

#include "es_inc_core"

const string CONSOLECOMMAND_LOG_TAG             = "ConsoleCommand";
const string CONSOLECOMMAND_SCRIPT_NAME         = "es_cc_concom";

const string CONSOLECOMMAND_BASE_COMMAND        = "BaseCommand";

const string CONSOLECOMMAND_NUM_COMMANDS        = "NumCommands";
const string CONSOLECOMMAND_REGISTERED_COMMAND  = "RegisteredCommand_";

const string CONSOLECOMMAND_COMMAND             = "Command_";
const string CONSOLECOMMAND_PARAMS              = "Params_";
const string CONSOLECOMMAND_DESCRIPTION         = "Description_";
const string CONSOLECOMMAND_SUBSYSTEM           = "Subsystem_";
const string CONSOLECOMMAND_FUNCTION            = "Function_";

// Register a console command
//
// sSubsystemScript: The subsystem the command is from, for example: es_s_example
// sFunction: The function name to execute when the administrator uses the console command.
//            The implementation must have the following signature: void <Name>(string sArgs)
//            Note: DelayCommand/AssignCommand will not work in the function.
// sCommand: The command the administrator must type
// sHelpParams: Optional parameter description for the 'help' console command
// sHelpDescription: A description of what the command does for the 'help' console command
//
// Returns: TRUE on success
void ConsoleCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription);

void ConsoleCommand_RegisterBaseCommand(string sCommand, string sHelpParams, string sHelpDescription)
{
    ConsoleCommand_Register(CONSOLECOMMAND_BASE_COMMAND, CONSOLECOMMAND_BASE_COMMAND, sCommand, sHelpParams, sHelpDescription);
}

// @Load
void ConsoleCommand_Load(string sCoreComponentScript)
{
    // Register Base Game Commands
    ConsoleCommand_RegisterBaseCommand("status",            "",                 "Show information about the server.");
    ConsoleCommand_RegisterBaseCommand("clientinfo",        "[Player]",         "Displays details on the client identified by ID, CDKey or PlayerName.");
    ConsoleCommand_RegisterBaseCommand("kick",              "[Player]",         "Remove a player from the game identified by ID, CDKey or PlayerName.");
    ConsoleCommand_RegisterBaseCommand("listbans",          "",                 "List all the current bans for IPs, CDKeys and PlayerNames.");
    ConsoleCommand_RegisterBaseCommand("banip",             "[IP Address]",     "Ban connections from an IP Address (may include *s).");
    ConsoleCommand_RegisterBaseCommand("bankey",            "[CDKey]",          "Ban connections using a CDKey.");
    ConsoleCommand_RegisterBaseCommand("banname",           "[PlayerName]",     "Ban connections from a PlayerName (may start and/or end with *s).");
    ConsoleCommand_RegisterBaseCommand("unbanip",           "[IP Address]",     "Remove an IP Address from the list of banned IP Addresses.");
    ConsoleCommand_RegisterBaseCommand("unbankey",          "[CDKey]",          "Remove a CDKey the list of banned CDKeys.");
    ConsoleCommand_RegisterBaseCommand("unbanname",         "[PlayerName]",     "Remove a PlayerName from the list of banned PlayerNames.");
    ConsoleCommand_RegisterBaseCommand("save",              "[Slot#] [Name]",   "Save the current running game as [Name] to [Slot#].");
    ConsoleCommand_RegisterBaseCommand("forcesave",         "[Slot#] [Name]",   "Save the current running game as [Name], overwriting [Slot#].");
    ConsoleCommand_RegisterBaseCommand("exit",              "",                 "Shut down the server.");
    ConsoleCommand_RegisterBaseCommand("quit",              "",                 "Shut down the server.");
    ConsoleCommand_RegisterBaseCommand("saveandexit",       "[Slot#] [Name]",   "Save the current running game as [Name] to [Slot#] and shut down the server.");
    ConsoleCommand_RegisterBaseCommand("module",            "[ModuleName]",     "Load the specified module.");
    ConsoleCommand_RegisterBaseCommand("load",              "[Slot#]",          "Load the specified saved game.");
    ConsoleCommand_RegisterBaseCommand("say",               "[Message]",        "Broadcast a message to all clients.");
    ConsoleCommand_RegisterBaseCommand("export",            "",                 "Causes all player characters in the game to be saved.");
    ConsoleCommand_RegisterBaseCommand("maxclients",        "[NumClients]",     "Set the maximum number of connections to the game server.");
    ConsoleCommand_RegisterBaseCommand("minlevel",          "[MinLevel]",       "Set the minimum character level required by the server.");
    ConsoleCommand_RegisterBaseCommand("maxlevel",          "[MaxLevel]",       "Set the maximum character level allowed by the server.");
    ConsoleCommand_RegisterBaseCommand("pauseandplay",      "[1|0]",            "0 = game can only be paused by DMs, 1 = game can by paused by players.");
    ConsoleCommand_RegisterBaseCommand("elc",               "[1|0]",            "0 = don't enforce legal characters, 1 = do enforce legal characters.");
    ConsoleCommand_RegisterBaseCommand("ilr",               "[1|0]",            "0 = don't enforce item level restrictions, 1 = do enforce item level restrictions.");
    ConsoleCommand_RegisterBaseCommand("oneparty",          "[1|0]",            "0 = allow only one party, 1 = allow multiple parties.");
    ConsoleCommand_RegisterBaseCommand("difficulty",        "[Level]",          "1 = easy, 2 = normal, 3 = D&D hardcore, 4 = very difficult.");
    ConsoleCommand_RegisterBaseCommand("autosaveinterval",  "[Minutes]",        "Set how frequently (in minutes) to autosave, 0 disables autosave.");
    ConsoleCommand_RegisterBaseCommand("playerpassword",    "[Password]",       "Change the player password, leave empty to remove.");
    ConsoleCommand_RegisterBaseCommand("dmpassword",        "[Password]",       "Change the DM password, leave empty to remove.");
    ConsoleCommand_RegisterBaseCommand("servername",        "[Name]",           "Set the server name.");
    ConsoleCommand_RegisterBaseCommand("help",              "",                 "Display all commands.");

    // Override the help command with our own
    ConsoleCommand_Register(sCoreComponentScript, "ConsoleCommand_ShowHelp", "help", "", "Display all commands.");
}

int ConsoleCommand_Register(string sSubsystemScript, string sFunction, string sCommand, string sHelpParams, string sHelpDescription)
{
    if (sSubsystemScript == "" || sFunction == "" || sCommand == "" || sHelpDescription == "")
        return FALSE;

    object oDataObject = ES_Util_GetDataObject(CONSOLECOMMAND_SCRIPT_NAME);
    int bReturn, nCommandID = GetLocalInt(oDataObject, CONSOLECOMMAND_NUM_COMMANDS) + 1;
    string sCommandID = IntToString(nCommandID);

    sCommand = GetStringLowerCase(sCommand);

    if (sSubsystemScript == CONSOLECOMMAND_BASE_COMMAND && sFunction == CONSOLECOMMAND_BASE_COMMAND)
    {
        SetLocalInt(oDataObject, CONSOLECOMMAND_REGISTERED_COMMAND + sCommand, nCommandID);
        SetLocalInt(oDataObject, CONSOLECOMMAND_NUM_COMMANDS, nCommandID);

        SetLocalString(oDataObject, CONSOLECOMMAND_COMMAND + sCommandID, sCommand);
        SetLocalString(oDataObject, CONSOLECOMMAND_PARAMS + sCommandID, sHelpParams);
        SetLocalString(oDataObject, CONSOLECOMMAND_DESCRIPTION + sCommandID, sHelpDescription);

        bReturn = TRUE;
    }
    else
    {
        int nCommandRegistered = GetLocalInt(oDataObject, CONSOLECOMMAND_REGISTERED_COMMAND + sCommand);
        string sRegisteredCommandID = IntToString(nCommandRegistered);

        if (nCommandRegistered)
        {
            if (GetLocalString(oDataObject, CONSOLECOMMAND_SUBSYSTEM + sRegisteredCommandID) == "" &&
                GetLocalString(oDataObject, CONSOLECOMMAND_FUNCTION + sRegisteredCommandID) == "")
            {
                SetLocalString(oDataObject, CONSOLECOMMAND_COMMAND + sRegisteredCommandID, sCommand);
                SetLocalString(oDataObject, CONSOLECOMMAND_PARAMS + sRegisteredCommandID, sHelpParams);
                SetLocalString(oDataObject, CONSOLECOMMAND_DESCRIPTION + sRegisteredCommandID, sHelpDescription);
                SetLocalString(oDataObject, CONSOLECOMMAND_SUBSYSTEM + sRegisteredCommandID, sSubsystemScript);
                SetLocalString(oDataObject, CONSOLECOMMAND_FUNCTION + sRegisteredCommandID, sFunction);

                bReturn = ES_Util_RegisterServerConsoleCommand(sCommand, sSubsystemScript, nssFunction(sFunction, "sArgs"), TRUE);

                if (bReturn)
                    ES_Util_Log(CONSOLECOMMAND_LOG_TAG, "* Overriding Base Game Console Command -> '" + sCommand + "' by '" +
                        sSubsystemScript + "' with Function: " + sFunction + "()");
                else
                    ES_Util_Log(CONSOLECOMMAND_LOG_TAG, "* ERROR: Failed to override Console Command -> '" + sCommand + "' by '" +
                        sSubsystemScript + "' with Function: " + sFunction + "()");
            }
            else
            {
                string sSubsystem = GetLocalString(oDataObject, CONSOLECOMMAND_SUBSYSTEM + sRegisteredCommandID);
                ES_Util_Log(CONSOLECOMMAND_LOG_TAG, "* ERROR: Console Command -> '" + sCommand + "' has already been registered by: " + sSubsystem);
            }
        }
        else
        {
            SetLocalInt(oDataObject, CONSOLECOMMAND_REGISTERED_COMMAND + sCommand, nCommandID);
            SetLocalInt(oDataObject, CONSOLECOMMAND_NUM_COMMANDS, nCommandID);

            SetLocalString(oDataObject, CONSOLECOMMAND_COMMAND + sCommandID, sCommand);
            SetLocalString(oDataObject, CONSOLECOMMAND_PARAMS + sCommandID, sHelpParams);
            SetLocalString(oDataObject, CONSOLECOMMAND_DESCRIPTION + sCommandID, sHelpDescription);
            SetLocalString(oDataObject, CONSOLECOMMAND_SUBSYSTEM + sCommandID, sSubsystemScript);
            SetLocalString(oDataObject, CONSOLECOMMAND_FUNCTION + sCommandID, sFunction);

            bReturn = ES_Util_RegisterServerConsoleCommand(sCommand, sSubsystemScript, nssFunction(sFunction, "sArgs"), TRUE);

            if (bReturn)
                ES_Util_Log(CONSOLECOMMAND_LOG_TAG, "* Registering Console Command -> '" + sCommand + "' for '" +
                    sSubsystemScript + "' with Function: " + sFunction + "()");
            else
                ES_Util_Log(CONSOLECOMMAND_LOG_TAG, "* ERROR: Failed to register Console Command -> '" + sCommand + "' for '" +
                    sSubsystemScript + "' with Function: " + sFunction + "()");
        }
    }

    return bReturn;
}

void ConsoleCommand_ShowHelp(string sArgs)
{
    object oDataObject = ES_Util_GetDataObject(CONSOLECOMMAND_SCRIPT_NAME);
    string sHelp = GetLocalString(oDataObject, "HelpString");

    if (sHelp == "" || sArgs != "")
    {
        int nNumCommands = GetLocalInt(oDataObject, CONSOLECOMMAND_NUM_COMMANDS);
        sHelp = "Available Console Commands: \n";

        int nCommandID;
        for (nCommandID = 1; nCommandID <= nNumCommands; nCommandID++)
        {
            string sCommandID = IntToString(nCommandID);
            string sCommand = GetLocalString(oDataObject, CONSOLECOMMAND_COMMAND + sCommandID);
            string sParams = GetLocalString(oDataObject, CONSOLECOMMAND_PARAMS + sCommandID);
            string sDescription = GetLocalString(oDataObject, CONSOLECOMMAND_DESCRIPTION + sCommandID);

            sHelp += "\n" + sCommand + (sParams != "" ? " " + sParams : "") + " - " + sDescription;

            SetLocalString(oDataObject, "HelpString", sHelp);
        }
    }

    PrintString(sHelp);
}

