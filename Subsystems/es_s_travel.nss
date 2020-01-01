/*
    ScriptName: es_s_travel.nss
    Created by: Daz

    Description: A subsystem that gives players a movement speed increase when
                 they're travelling on roads and a movement speed decrease while
                 in water.
*/

//void main() {}

#include "es_inc_core"

const string TRAVEL_EFFECT_TAG                      = "TravelEffectTag";
const int TRAVEL_SPEED_INCREASE_PERCENTAGE          = 75;
const int TRAVEL_SPEED_DECREASE_PERCENTAGE          = 50;
const float TRAVEL_IMPACT_DELAY_TIMER               = 0.5f;

void ApplyTravelEffect(object oPlayer, int nVFX, int nMaterial, effect eEffect);

// @EventSystem_Init
void Travel_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_NWNX(sEventHandlerScript, "NWNX_ON_MATERIALCHANGE_AFTER");
}

// @EventSystem_EventHandler
void Travel_EventHandler(string sEventHandlerScript, string sEvent)
{
    object oPlayer = OBJECT_SELF;
    int nMaterial = ES_Core_GetEventData_NWNX_Int("MATERIAL_TYPE");

    ES_Util_RemoveAllEffectsWithTag(oPlayer, TRAVEL_EFFECT_TAG);

    switch (nMaterial)
    {
        case 1: // Dirt
        {
            effect eEffect = EffectLinkEffects(
                EffectVisualEffect(VFX_DUR_CESSATE_POSITIVE),
                EffectMovementSpeedIncrease(TRAVEL_SPEED_INCREASE_PERCENTAGE));

            DelayCommand(TRAVEL_IMPACT_DELAY_TIMER, ApplyTravelEffect(oPlayer, VFX_IMP_HASTE, nMaterial, eEffect));
            break;
        }

        case 6: // Water
        {
            effect eEffect = EffectLinkEffects(
                EffectVisualEffect(VFX_DUR_CESSATE_NEGATIVE),
                EffectMovementSpeedDecrease(TRAVEL_SPEED_DECREASE_PERCENTAGE));

            DelayCommand(TRAVEL_IMPACT_DELAY_TIMER, ApplyTravelEffect(oPlayer, VFX_IMP_SLOW, nMaterial, eEffect));
            break;
        }
    }
}

void ApplyTravelEffect(object oPlayer, int nVFX, int nMaterial, effect eEffect)
{
    if (GetSurfaceMaterial(GetLocation(oPlayer)) == nMaterial)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(nVFX), oPlayer);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, TagEffect(SupernaturalEffect(eEffect), TRAVEL_EFFECT_TAG), oPlayer);
    }
}

