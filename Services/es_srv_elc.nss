/*
    ScriptName: es_srv_elc.nss
    Created by: Daz

    Description: An EventSystem Service that allows subscribing to ELC events
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_elc"

const string ELC_LOG_TAG        = "ELC";
const string ELC_SCRIPT_NAME    = "es_srv_elc";

const string ELC_EVENT          = "ELC_EVENT";

// Subscribe sSubsystemScript to the ELC event
void ELC_SubscribeEvent(string sSubsystemScript);

// @Init
void ELC_Init(string sServiceScript)
{
    ES_Util_AddScript(sServiceScript, "nwnx_events", nssFunction("NWNX_Events_SignalEvent", nssEscapeDoubleQuotes(ELC_EVENT) + ", OBJECT_SELF"));
}

void ELC_SubscribeEvent(string sSubsystemScript)
{
    NWNX_ELC_SetELCScript(ELC_SCRIPT_NAME);

    NWNX_Events_SubscribeEvent(ELC_EVENT, sSubsystemScript);
}

