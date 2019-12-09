/*
    ScriptName: es_s_elc.nss
    Created by: Daz

    Description: A subsystem that allows subscribing to ELC events
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_elc"

const string ELC_EVENT  = "ELC_EVENT";

// @EventSystem_Init
void ELC_Init(string sEventHandlerScript);

// Subscribe sEventHandlerScript to the ELC event
void ELC_SubscribeEvent(string sEventHandlerScript);

void ELC_Init(string sEventHandlerScript)
{
    ES_Util_AddScript("es_elc", "nwnx_events", "NWNX_Events_SignalEvent(\"ELC_EVENT\", OBJECT_SELF);");
}

void ELC_SubscribeEvent(string sEventHandlerScript)
{
    NWNX_ELC_SetELCScript("es_elc");

    NWNX_Events_SubscribeEvent(ELC_EVENT, sEventHandlerScript);
}

