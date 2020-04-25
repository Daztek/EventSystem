/*
    ScriptName: es_s_subsysman.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_concom"

const string SUBSYSTEM_MANAGER_LOG_TAG      = "SubsystemManager";
const string SUBSYSTEM_MANAGER_SCRIPT_NAME  = "es_s_subsysman";

const float SUBSYSTEM_MANAGER_IGNORE_TIME   = 2.5f;

// @Load
void SubsystemManager_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_RESOURCE_MODIFIED");
}

// @EventHandler
void SubsystemManager_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_RESOURCE_MODIFIED")
    {
        string sAlias = Events_GetEventData_NWNX_String("ALIAS");
        int nType = Events_GetEventData_NWNX_Int("TYPE");

        if (sAlias == "NWNX" && nType == NWNX_UTIL_RESREF_TYPE_NSS)
        {
            string sResRef = Events_GetEventData_NWNX_String("RESREF");

            if (ES_Core_Component_GetTypeFromScriptName(sResRef) == ES_CORE_COMPONENT_TYPE_SUBSYSTEM)
            {
                object oDataObject = ES_Util_GetDataObject(SUBSYSTEM_MANAGER_SCRIPT_NAME);
                object oComponent = ES_Core_GetComponentDataObject(sResRef, FALSE);

                if (GetIsObjectValid(oComponent))
                {
                    if (GetLocalInt(oDataObject, sResRef))
                        return;

                    SetLocalInt(oDataObject, sResRef, TRUE);
                    DelayCommand(SUBSYSTEM_MANAGER_IGNORE_TIME, DeleteLocalInt(oDataObject, sResRef));

                    string sScriptFlags = GetLocalString(oComponent, "Flags");

                    if (FindSubString(sScriptFlags, "HotSwap") != -1)
                    {
                        ES_Util_Log(SUBSYSTEM_MANAGER_LOG_TAG, "Detected changes for '" + sResRef + "', recompiling EventHandler", FALSE);

                        ES_Core_Component_ExecuteFunction(sResRef, "Unload");

                        ES_Util_SuppressLog(TRUE);
                        ES_Core_Component_Initialize(sResRef, ES_CORE_COMPONENT_TYPE_SUBSYSTEM);
                        ES_Core_Component_CheckHash(sResRef);
                        ES_Util_SuppressLog(FALSE);

                        ES_Core_Component_ExecuteFunction(sResRef, "Load");

                    }
                }
            }
        }
    }
}

