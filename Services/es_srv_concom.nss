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

// @Post
void ConsoleCommand_Post(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(CONSOLECOMMAND_SCRIPT_NAME);
}

