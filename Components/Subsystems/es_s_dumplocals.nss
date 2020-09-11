/*
    ScriptName: es_s_dumplocals.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that replaces the dm_dumplocals
                 console command with a NWScript implementation
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_chatcom"
#include "es_srv_mediator"

const string DUMPLOCALS_LOG_TAG                     = "DumpLocals";
const string DUMPLOCALS_SCRIPT_NAME                 = "es_s_dumplocals";

const string DUMPLOCALS_CHATCOMMAND_NAME            = "dumplocals";
const string DUMPLOCALS_CHATCOMMAND_DESCRIPTION     = "Dump the locals of the targeted object.";

const int DUMPLOCALS_TYPE_OBJECT                    = 0;
const int DUMPLOCALS_TYPE_AREA                      = 1;
const int DUMPLOCALS_TYPE_MODULE                    = 2;
const int DUMPLOCALS_TYPE_CHAT_COMMAND              = 3;

// Dump the locals of oTarget, depending on nType
void DumpLocals_DumpLocals(object oPlayer, int nType, object oTarget = OBJECT_INVALID);

// @Load
void DumpLocals_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_DM_DUMP_LOCALS_BEFORE");
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET);

    Mediator_RegisterFunction(sSubsystemScript, "DumpLocals_DumpLocals", "oio");

    ChatCommand_Register(sSubsystemScript, "DumpLocals_ChatCommand", CHATCOMMAND_GLOBAL_PREFIX + DUMPLOCALS_CHATCOMMAND_NAME, "", DUMPLOCALS_CHATCOMMAND_DESCRIPTION);
}

// @EventHandler
void DumpLocals_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_DM_DUMP_LOCALS_BEFORE")
    {
        object oDM = OBJECT_SELF;
        object oTarget = Events_GetEventData_NWNX_Object("TARGET");
        int nType = Events_GetEventData_NWNX_Int("TYPE");

        DumpLocals_DumpLocals(oDM, nType, oTarget);

        Events_SkipEvent();
    }
    else
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET)
    {
        object oPlayer = GetLastPlayerToSelectTarget();

        if (Events_GetCurrentTargetingMode(oPlayer) == DUMPLOCALS_SCRIPT_NAME)
        {
            DumpLocals_DumpLocals(oPlayer, DUMPLOCALS_TYPE_CHAT_COMMAND, GetTargetingModeSelectedObject());
        }
    }
}

void DumpLocals_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    Events_EnterTargetingMode(oPlayer, DUMPLOCALS_SCRIPT_NAME);
    SetPCChatMessage("");
}

void DumpLocals_DumpLocals(object oPlayer, int nType, object oTarget = OBJECT_INVALID)
{
    string sMessage;

    switch (nType)
    {
        case DUMPLOCALS_TYPE_OBJECT: // dm_dumplocals
        {
            sMessage = "*** Variable Dump *** [Object] Tag: " + GetTag(oTarget);
            break;
        }
        case DUMPLOCALS_TYPE_AREA: // dm_dumparealocals
        {
            oTarget = GetArea(oTarget);
            sMessage = "*** Variable Dump *** [Area] Tag: " + GetTag(oTarget);
            break;
        }
        case DUMPLOCALS_TYPE_MODULE: // dm_dumpmodulelocals
        {
            oTarget = GetModule();
            sMessage = "*** Variable Dump *** [Module]";
            break;
        }
        case DUMPLOCALS_TYPE_CHAT_COMMAND:
        {
            sMessage = "*** Variable Dump *** [" + GetName(oTarget) + "] Tag: " + GetTag(oTarget);
            break;
        }
    }

    if (!GetIsObjectValid(oTarget)) return;

    int nCount = NWNX_Object_GetLocalVariableCount(oTarget);

    if (!nCount)
    {
        sMessage += "\nNone defined.";
    }
    else
    {
        int i;
        for(i = 0; i < nCount; i++)
        {
            struct NWNX_Object_LocalVariable var = NWNX_Object_GetLocalVariable(oTarget, i);

            switch (var.type)
            {
                case NWNX_OBJECT_LOCALVAR_TYPE_UNKNOWN:
                    sMessage += "\n[UNKNOWN] " + var.key + " = ?";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_INT:
                    sMessage += "\n[INT] " + var.key + " = " + IntToString(GetLocalInt(oTarget, var.key));
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_FLOAT:
                    sMessage += "\n[FLT] " + var.key + " = " + FloatToString(GetLocalFloat(oTarget, var.key), 0);
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_STRING:
                    sMessage += "\n[STR] " + var.key + " = \"" + GetLocalString(oTarget, var.key) + "\"";
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_OBJECT:
                    sMessage += "\n[OID] " + var.key + " = " + ObjectToString(GetLocalObject(oTarget, var.key));
                    break;

                case NWNX_OBJECT_LOCALVAR_TYPE_LOCATION:
                {
                    location locLocation = GetLocalLocation(oTarget, var.key);
                    object oArea = GetAreaFromLocation(locLocation);
                    vector vPos = GetPositionFromLocation(locLocation);

                    sMessage += "\n[LOC] " + var.key + " = (" + GetTag(oArea) + ")(" + FloatToString(vPos.x, 0, 3) + ", " + FloatToString(vPos.y, 0, 3) + ", " + FloatToString(vPos.z, 0, 3) + ")";
                    break;
                }
            }
        }
    }

    if (oPlayer == OBJECT_INVALID)
        PrintString(sMessage);
    else
        SendMessageToPC(oPlayer, sMessage);
}

