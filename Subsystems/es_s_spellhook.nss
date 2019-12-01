/*
    ScriptName: es_s_spellhook.nss
    Created by: Daz

    Description: A subsystem that allows subscribing to module override spell script events
*/

//void main() {}

#include "es_inc_core"
#include "x2_inc_switches"

const string SPELL_HOOK_EVENT_PREFIX        = "SPELL_";

// @EventSystem_Init
void Spellhook_Init(string sEventHandlerScript);

// Subscribe sEventHandlerScript to a SPELL_* cast event
void Spellhook_SubscribeEvent(string sEventHandlerScript, int nSpell);
// Skip a spellhook event
void Spellhook_SkipEvent();

void Spellhook_Init(string sEventHandlerScript)
{
    ES_Util_AddScript("es_spellhook", "nwnx_events", "NWNX_Events_SignalEvent(\"SPELL_\" + IntToString(GetSpellId()), OBJECT_SELF);");
    SetModuleOverrideSpellscript("es_spellhook");
}

void Spellhook_SubscribeEvent(string sEventHandlerScript, int nSpell)
{
    NWNX_Events_SubscribeEvent(SPELL_HOOK_EVENT_PREFIX + IntToString(nSpell), sEventHandlerScript);
}

void Spellhook_SkipEvent()
{
    SetModuleOverrideSpellScriptFinished();
}

