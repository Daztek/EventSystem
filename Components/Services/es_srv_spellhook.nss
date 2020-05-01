/*
    ScriptName: es_srv_spellhook.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Service that allows subsystems to subscribe to
                 module override spell script events
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "x2_inc_switches"

const string SPELLHOOK_LOG_TAG      = "Spellhook";
const string SPELLHOOK_SCRIPT_NAME  = "es_srv_spellhook";

const string SPELLHOOK_EVENT_PREFIX = "SPELL_EVENT_";

// Subscribe sEventHandlerScript to a spellcast event
void Spellhook_SubscribeEvent(string sSubsystemScript, int nSpellID, int bDispatchListMode = FALSE);
// Skip a spellhook event
void Spellhook_SkipEvent();
// Get the spell event name for nSpellID
string Spellhook_GetEventName(int nSpellID);

// @Load
void Spellhook_Load(string sServiceScript)
{
    ES_Util_AddScript(sServiceScript, sServiceScript, nssFunction("Spellhook_SignalEvent"));
}

void Spellhook_SignalEvent()
{
    string sSpellEvent = SPELLHOOK_EVENT_PREFIX + IntToString(GetSpellId());

    if (GetLocalInt(ES_Util_GetDataObject(SPELLHOOK_SCRIPT_NAME), sSpellEvent))
        Events_SignalEvent(sSpellEvent, OBJECT_SELF);
}

void Spellhook_SubscribeEvent(string sSubsystemScript, int nSpellID, int bDispatchListMode = FALSE)
{
    SetModuleOverrideSpellscript(SPELLHOOK_SCRIPT_NAME);

    SetLocalInt(ES_Util_GetDataObject(SPELLHOOK_SCRIPT_NAME), SPELLHOOK_EVENT_PREFIX + IntToString(nSpellID), TRUE);

    Events_SubscribeEvent(sSubsystemScript, SPELLHOOK_EVENT_PREFIX + IntToString(nSpellID), bDispatchListMode);
}

void Spellhook_SkipEvent()
{
    SetModuleOverrideSpellScriptFinished();
}

string Spellhook_GetEventName(int nSpellID)
{
    return SPELLHOOK_EVENT_PREFIX + IntToString(nSpellID);
}

