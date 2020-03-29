/*
    ScriptName: es_s_subsysman.nss
    Created by: Daz

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_concom"

const string SUBSYSTEM_MANAGER_LOG_TAG      = "SubsystemManager";
const string SUBSYSTEM_MANAGER_SCRIPT_NAME  = "es_s_subsysman";

// @Load
void SubsystemManager_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_RESOURCE_MODIFIED");
}

// @EventHandler
void SubsystemManager_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_RESOURCE_MODIFIED")
    {
        string sAlias = ES_Util_GetEventData_NWNX_String("ALIAS");
        int nType = ES_Util_GetEventData_NWNX_Int("TYPE");

        if (sAlias == "NWNX" && nType == NWNX_UTIL_RESREF_TYPE_NSS)
        {
            string sResRef = ES_Util_GetEventData_NWNX_String("RESREF");

            if (GetStringLeft(sResRef, 5) == "es_s_")
            {
                object oDataObject = ES_Util_GetDataObject(SUBSYSTEM_MANAGER_SCRIPT_NAME);
                object oSubsystem = ES_Core_GetSystemDataObject(sResRef, FALSE);

                if (GetIsObjectValid(oSubsystem))
                {
                    if (ES_Util_GetInt(oDataObject, sResRef))
                        return;

                    ES_Util_SetInt(oDataObject, sResRef, TRUE);
                    DelayCommand(2.0f, ES_Util_DeleteInt(oDataObject, sResRef));

                    string sScriptFlags = ES_Util_GetString(oSubsystem, "Flags");

                    if (FindSubString(sScriptFlags, "HotSwap") != -1)
                    {
                        ES_Util_SuppressLog(TRUE);

                        ES_Util_Log(SUBSYSTEM_MANAGER_LOG_TAG, "Detected changes for Subsystem '" + sResRef + "', recompiling EventHandler", FALSE);

                        ES_Core_ExecuteFunction(sResRef, "Unload");

                        ES_Core_Subsystem_Initialize(sResRef);

                        ES_Core_CheckHash(sResRef);

                        ES_Core_ExecuteFunction(sResRef, "Load");

                        ES_Util_SuppressLog(FALSE);
                    }
                }
            }
        }
    }
}

