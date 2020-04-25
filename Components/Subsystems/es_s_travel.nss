/*
    ScriptName: es_s_travel.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player]

    Flags:
        @HotSwap

    Description: A subsystem that gives players a movement speed increase when
                 they're travelling on roads and a movement speed decrease while
                 in water.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_player"

const string TRAVEL_EFFECT_TAG                  = "TravelEffectTag";
const float  TRAVEL_EFFECT_DURATION             = 300.0f;
const int    TRAVEL_SPEED_INCREASE_PERCENTAGE   = 75;
const int    TRAVEL_SPEED_DECREASE_PERCENTAGE   = 50;
const float  TRAVEL_IMPACT_DELAY_TIMER          = 0.5f;

void Travel_ApplyEffect(object oPlayer, int nVFX, int nMaterial, effect eEffect);

// @Load
void Travel_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_MATERIALCHANGE_AFTER");
}

// @Unload
void Travel_Unload(string sSubsystemScript)
{
    Events_UnsubscribeAllEvents(sSubsystemScript);

    object oPlayer = GetFirstPC();
    while (GetIsObjectValid(oPlayer))
    {
        effect eEffect = GetFirstEffect(oPlayer);
        while (GetIsEffectValid(eEffect))
        {
            if (GetEffectTag(eEffect) == TRAVEL_EFFECT_TAG)
                RemoveEffect(oPlayer, eEffect);

            eEffect = GetNextEffect(oPlayer);
        }

        oPlayer = GetNextPC();
    }
}

// @EventHandler
void Travel_EventHandler(string sSubsystemScript, string sEvent)
{
    object oPlayer = OBJECT_SELF;

    if (!GetIsPC(oPlayer) || GetIsDM(oPlayer)) return;

    int nMaterial = Events_GetEventData_NWNX_Int("MATERIAL_TYPE");

    effect eEffect = GetFirstEffect(oPlayer);
    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == TRAVEL_EFFECT_TAG)
            RemoveEffect(oPlayer, eEffect);

        eEffect = GetNextEffect(oPlayer);
    }

    switch (nMaterial)
    {
        case 1: // Dirt
        {
            effect eEffect = EffectLinkEffects(
                EffectVisualEffect(VFX_DUR_CESSATE_POSITIVE),
                EffectMovementSpeedIncrease(TRAVEL_SPEED_INCREASE_PERCENTAGE));

            DelayCommand(TRAVEL_IMPACT_DELAY_TIMER, Travel_ApplyEffect(oPlayer, VFX_IMP_HASTE, nMaterial, eEffect));
            break;
        }

        case 6: // Water
        {
            effect eEffect = EffectLinkEffects(
                EffectVisualEffect(VFX_DUR_CESSATE_NEGATIVE),
                EffectMovementSpeedDecrease(TRAVEL_SPEED_DECREASE_PERCENTAGE));

            DelayCommand(TRAVEL_IMPACT_DELAY_TIMER, Travel_ApplyEffect(oPlayer, VFX_IMP_SLOW, nMaterial, eEffect));
            break;
        }
    }
}

void Travel_ApplyEffect(object oPlayer, int nVFX, int nMaterial, effect eEffect)
{
    if (GetSurfaceMaterial(GetLocation(oPlayer)) == nMaterial)
    {
        NWNX_Player_ApplyInstantVisualEffectToObject(oPlayer, oPlayer, nVFX);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, TagEffect(SupernaturalEffect(eEffect), TRAVEL_EFFECT_TAG), oPlayer, TRAVEL_EFFECT_DURATION);
    }
}

