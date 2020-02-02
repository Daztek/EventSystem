/*
    ScriptName: es_s_dumplocals.nss
    Created by: Daz

    Description: An EventSystem Subsystem that replaces the dm_dumplocals
                 console command with a NWScript implementation
*/

//void main() {}

#include "es_inc_core"

// @Init
void DumpLocals_Init(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_DM_DUMP_LOCALS_BEFORE");
}

// @EventHandler
void DumpLocals_EventHandler(string sSubsystemScript, string sEvent)
{
    object oDM = OBJECT_SELF;
    object oTarget = ES_Util_GetEventData_NWNX_Object("TARGET");
    int nType = ES_Util_GetEventData_NWNX_Int("TYPE");
    string sMessage;

    NWNX_Events_SkipEvent();

    switch (nType)
    {
        case 0: // dm_dumplocals
        {
            sMessage = "*** Variable Dump *** [Object] Tag: " + GetTag(oTarget);
            break;
        }
        case 1: // dm_dumparealocals
        {
            oTarget = GetArea(oTarget);
            sMessage = "*** Variable Dump *** [Area] Tag: " + GetTag(oTarget);
            break;
        }
        case 2: // dm_dumpmodulelocals
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

    SendMessageToPC(oDM, sMessage);
}

