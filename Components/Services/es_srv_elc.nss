/*
    ScriptName: es_srv_elc.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[ELC]

    Description: An EventSystem Service that allows subscribing to ELC events
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_elc"

const string ELC_LOG_TAG        = "ELC";
const string ELC_SCRIPT_NAME    = "es_srv_elc";

const string ELC_EVENT          = "ELC_EVENT";

// Subscribe sSubsystemScript to the ELC event
void ELC_SubscribeEvent(string sSubsystemScript);

// @Load
void ELC_Load(string sServiceScript)
{
    ES_Util_AddScript(sServiceScript, ELC_SCRIPT_NAME, nssFunction("Events_SignalEvent", nssEscapeDoubleQuotes(ELC_EVENT) + ", OBJECT_SELF"));
}

void ELC_SubscribeEvent(string sSubsystemScript)
{
    NWNX_ELC_SetELCScript(ELC_SCRIPT_NAME);

    Events_SubscribeEvent(sSubsystemScript, ELC_EVENT, FALSE);
}

