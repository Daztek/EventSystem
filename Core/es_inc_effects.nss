/*
    ScriptName: es_inc_effects.nss
    Created by: Daz

    Description: Event System Effects Include
*/

// Remove effects with sTag from oObject
void Effects_RemoveEffectsWithTag(object oObject, string sTag, int bFirstOnly = FALSE);
// Toggle CutsceneInvisibility and CutsceneGhost on oObject
void Effects_ToggleCutsceneInvisibility(object oObject, int bInvisible);
// Get a visual effect of oCreature's blood color
effect Effects_GetBloodEffect(object oCreature);
// Apply eImpactVisualEffect nNumImpacts times with fDelay
void Effects_ApplyImpactVisualEffects(object oObject, effect eImpactVisualEffect, int nNumImpacts, float fInitialDelay = 0.0f, float fDelay = 0.5f);

void Effects_RemoveEffectsWithTag(object oObject, string sTag, int bFirstOnly = FALSE)
{
    effect eEffect = GetFirstEffect(oObject);

    while (GetIsEffectValid(eEffect))
    {
        if (GetEffectTag(eEffect) == sTag)
        {
            RemoveEffect(oObject, eEffect);

            if (bFirstOnly)
                break;
        }

        eEffect = GetNextEffect(oObject);
    }
}

void Effects_ToggleCutsceneInvisibility(object oObject, int bInvisible)
{
    if (bInvisible)
    {
        effect eCutsceneInvisibility = TagEffect(
            SupernaturalEffect(
                EffectLinkEffects(EffectVisualEffect(VFX_DUR_CUTSCENE_INVISIBILITY), EffectCutsceneGhost())),
                "EFFECTS_CUTSCENE_INVISIBILITY");

        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCutsceneInvisibility, oObject);
    }
    else
    {
        Effects_RemoveEffectsWithTag(oObject, "EFFECTS_CUTSCENE_INVISIBILITY");
    }
}

effect Effects_GetBloodEffect(object oCreature)
{
    int nBloodColor;
    string sBloodColor = Get2DAString("appearance", "BLOODCOLR", GetAppearanceType(oCreature));

    if (sBloodColor == "R")
        nBloodColor = VFX_COM_BLOOD_CRT_RED;
    else
    if (sBloodColor == "W")
        nBloodColor = VFX_COM_BLOOD_CRT_WIMP;
    else
    if (sBloodColor == "G")
        nBloodColor = VFX_COM_BLOOD_CRT_GREEN;
    else
    if (sBloodColor == "Y")
        nBloodColor = VFX_COM_BLOOD_CRT_YELLOW;
    else
        nBloodColor = VFX_COM_BLOOD_CRT_RED;

    return EffectVisualEffect(nBloodColor);
}

void Effects_ApplyImpactVisualEffects(object oObject, effect eImpactVisualEffect, int nNumImpacts, float fInitialDelay = 0.0f, float fDelay = 0.5f)
{
    int nImpact;
    for (nImpact = 0; nImpact < nNumImpacts; nImpact++)
    {
        DelayCommand(fInitialDelay + (fDelay * nImpact), ApplyEffectToObject(DURATION_TYPE_INSTANT, eImpactVisualEffect, oObject));
    }
}

