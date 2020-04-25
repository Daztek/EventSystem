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
#include "es_srv_mediator"

const string DUMPLOCALS_LOG_TAG         = "DumpLocals";
const string DUMPLOCALS_SCRIPT_NAME     = "es_s_dumplocals";

const int DUMPLOCALS_TYPE_OBJECT        = 0;
const int DUMPLOCALS_TYPE_AREA          = 1;
const int DUMPLOCALS_TYPE_MODULE        = 2;

// Dump the locals of oTarget, depending on nType
void DumpLocals_DumpLocals(object oPlayer, int nType, object oTarget = OBJECT_INVALID);

// @Load
void DumpLocals_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_DM_DUMP_LOCALS_BEFORE");

    Mediator_RegisterFunction(sSubsystemScript, "DumpLocals_DumpLocals", "oio");
}

// @EventHandler
void DumpLocals_EventHandler(string sSubsystemScript, string sEvent)
{
    object oDM = OBJECT_SELF;
    object oTarget = Events_GetEventData_NWNX_Object("TARGET");
    int nType = Events_GetEventData_NWNX_Int("TYPE");

    Events_SkipEvent();

    DumpLocals_DumpLocals(oDM, nType, oTarget);
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

    SendMessageToPC(oPlayer, sMessage);
}

