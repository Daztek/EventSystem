/*
    ScriptName: es_srv_spellhook.nss
    Created by: Daz

    Description: An EventSystem Service that allows subsystems to subscribe to
                 module override spell script events
*/

//void main() {}

#include "es_inc_core"
#include "x2_inc_switches"

const string SPELLHOOK_LOG_TAG      = "Spellhook";
const string SPELLHOOK_SCRIPT_NAME  = "es_srv_spellhook";

const string SPELLHOOK_EVENT_PREFIX = "SPELL_";

// Subscribe sEventHandlerScript to a SPELL_* cast event
void Spellhook_SubscribeEvent(string sSubsystemScript, int nSpell);
// Skip a spellhook event
void Spellhook_SkipEvent();

// @Load
void Spellhook_Load(string sServiceScript)
{
    ES_Util_AddScript(sServiceScript, sServiceScript, nssFunction("Spellhook_SignalEvent"));
}

void Spellhook_SignalEvent()
{
    string sSpellEvent = SPELLHOOK_EVENT_PREFIX + IntToString(GetSpellId());

    if (ES_Util_GetInt(ES_Util_GetDataObject(SPELLHOOK_SCRIPT_NAME), sSpellEvent))
        NWNX_Events_SignalEvent(sSpellEvent, OBJECT_SELF);
}

void Spellhook_SubscribeEvent(string sSubsystemScript, int nSpell)
{
    SetModuleOverrideSpellscript(SPELLHOOK_SCRIPT_NAME);

    ES_Util_SetInt(ES_Util_GetDataObject(SPELLHOOK_SCRIPT_NAME), SPELLHOOK_EVENT_PREFIX + IntToString(nSpell), TRUE);

    ES_Core_SubscribeEvent(sSubsystemScript, SPELLHOOK_EVENT_PREFIX + IntToString(nSpell), FALSE);
}

void Spellhook_SkipEvent()
{
    SetModuleOverrideSpellScriptFinished();
}

