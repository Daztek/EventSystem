/*
    ScriptName: es_srv_concom.nss
    Created by: Daz

    Description: An EventSystem Service that allows registering of
                 server console commands by subsystems
*/

//void main() {}

#include "es_inc_core"

const string CONSOLECOMMAND_LOG_TAG         = "ConsoleCommand";
const string CONSOLECOMMAND_SCRIPT_NAME     = "es_srv_concom";


// @Load
void ConsoleCommand_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(CONSOLECOMMAND_SCRIPT_NAME);
}

/*
    PrintString("\n\n" +
    "status - Show information about the server. \n" +
    "clientinfo <player> - Displays details on the client identified by ID, CD Key, or Player Name. \n" +
    "kick <player> - Remove a player from the game identified by ID, CD Key, or Player Name. \n" +
    "listbans - List all the current bans for Name, IP, and Public CD Key. \n" +
    "banip <ip address> - Ban connections from an ip address (may include *s) \n" +
    "bankey <key> - Ban connections using a cd key. \n" +
    "banname <player name> - Ban connections from a player name (may start and/or end with *s). \n" +
    "unbanip <ip address> - Remove an ip address from the list of banned ip addresses. \n" +
    "unbankey <key> - Remove a cd key the list of banned cd keys. \n" +
    "unbanname <player name> - Remove a player name from the list of banned player names. \n" +
    "save <slot#> <name> - Save the current running game as <name> to <slot#>. \n" +
    "forcesave <slot#> <name> - Save the current running game as <name>, overwriting <slot#>. \n" +
    "exit/quit - Shut down the server. \n" +
    "saveandexit <slot#> <name> - Save the current running game as <name> and shut down the server. \n" +
    "module <module name> - Load the specified module. \n" +
    "load <slot#> - Load the specified saved game. \n" +
    "say <message> - Broadcast a message to all clients. \n" +
    "export - Causes all player characters in the game to be saved. \n" +
    "maxclients <number of clients> - Set the maximum number of connections to the game server. \n" +
    "minlevel <minlevel> - Set the minimum character level required by the server. \n" +
    "maxlevel <maxlevel> - Set the maximum character level allowed by the server. \n" +
    "pauseandplay <0/1> - 0 = game can only be paused by DM, 1 = game can by paused by players \n" +
    "elc <0/1> - 0 = don't enforce legal characters, 1 = do enforce legal characters \n" +
    "ilr <0/1> - 0 = don't enforce item level restrictions, 1 = do enforce item level restrictions \n" +
    "oneparty <0/1> - 0 = allow only one party, 1 = allow multiple parties \n" +
    "difficulty <level> - 1 = easy, 2 = normal, 3 = D&D hardcore, 4 = very difficult \n" +
    "autosaveinterval <time> - Set how frequently (in minutes) to autosave. 0 disables autosave. \n" +
    "playerpassword <password> - Change the player password, leave empty to remove. \n" +
    "dmpassword <password> - Change the DM password, leave empty to remove. \n" +
    "servername <name> - Set the server name. \n" +
    "\n" +
    "help - Display all commands. \n" +
    "\n" +
    "Notes: \n" +
    " - Saved game slots 0 and 1 are reserved \n" +
    " - Commas between parameters to interactive commands are optional \n");
*/

