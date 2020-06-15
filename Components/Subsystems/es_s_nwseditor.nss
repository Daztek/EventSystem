/*
    ScriptName: es_s_nwseditor.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Util]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_chatcom"

const string NWSEDITOR_LOG_TAG                  = "NWScriptEditor";
const string NWSEDITOR_SCRIPT_NAME              = "es_s_nwseditor";

const string NWSEDITOR_EDITABLE_SCRIPT_NAME     = "nwseditor_script";

// @Load
void NWSEditor_Load(string sComponentScript)
{
    Events_SubscribeEvent_NWNX(sComponentScript, "NWNX_ON_MAP_PIN_ADD_PIN_AFTER");
    Events_SubscribeEvent_NWNX(sComponentScript, "NWNX_ON_MAP_PIN_CHANGE_PIN_AFTER");
    Events_SubscribeEvent_NWNX(sComponentScript, "NWNX_ON_MAP_PIN_DESTROY_PIN_AFTER");

    ChatCommand_Register(sComponentScript, "NWSEditor_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + "nws", "", "Execute the " + NWSEDITOR_LOG_TAG + " script!");
}

// @EventHandler
void NWSEditor_EventHandler(string sComponentScript, string sEvent)
{
    if (sEvent == "NWNX_ON_MAP_PIN_DESTROY_PIN_AFTER")
    {
        NWNX_Util_RemoveNWNXResourceFile(NWSEDITOR_EDITABLE_SCRIPT_NAME, NWNX_UTIL_RESREF_TYPE_NCS);
    }
    else
    {
        object oPlayer = OBJECT_SELF;
        string sScriptContents = Events_GetEventData_NWNX_String("PIN_NOTE");

        int bWrapIntoVoidMain = FindSubString(sScriptContents, "void main()") == -1;

        string sResult = NWNX_Util_AddScript(NWSEDITOR_EDITABLE_SCRIPT_NAME, sScriptContents, bWrapIntoVoidMain);

        if (sResult == "")
        {
            ExecuteScript(NWSEDITOR_EDITABLE_SCRIPT_NAME, oPlayer);
            SendMessageToPC(oPlayer, NWSEDITOR_LOG_TAG + ": compiling and executing script...");
        }
        else
            SendMessageToPC(oPlayer, NWSEDITOR_LOG_TAG + ": failed to compile script: " + sResult);
    }
}

void NWSEditor_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    if (NWNX_Util_IsValidResRef(NWSEDITOR_EDITABLE_SCRIPT_NAME, NWNX_UTIL_RESREF_TYPE_NCS))
    {
        ExecuteScript(NWSEDITOR_EDITABLE_SCRIPT_NAME, oPlayer);
        SendMessageToPC(oPlayer, NWSEDITOR_LOG_TAG + ": executing script...");
    }

    SetPCChatMessage("");
}

