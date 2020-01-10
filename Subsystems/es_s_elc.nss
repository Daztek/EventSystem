/*
    ScriptName: es_s_elc.nss
    Created by: Daz

    Description: A subsystem that allows subscribing to ELC events
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_elc"

const string ELC_EVENT  = "ELC_EVENT";

// Subscribe sSubsystemScript to the ELC event
void ELC_SubscribeEvent(string sSubsystemScript);

// @EventSystem_Init
void ELC_Init(string sSubsystemScript)
{
    ES_Util_AddScript(sSubsystemScript, "nwnx_events", nssFunction("NWNX_Events_SignalEvent", nssEscapeDoubleQuotes(ELC_EVENT) + ", OBJECT_SELF"));
}

void ELC_SubscribeEvent(string sSubsystemScript)
{
    NWNX_ELC_SetELCScript("es_s_elc");

    NWNX_Events_SubscribeEvent(ELC_EVENT, sSubsystemScript);
}

