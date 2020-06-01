/*
    ScriptName: es_inc_effects.nss
    Created by: Daz

    Description: Event System Effects Include
*/

// Remove effects with sTag from oObject
void Effects_RemoveEffectsWithTag(object oObject, string sTag, int bFirstOnly = FALSE);
// Toggle CutsceneInvisibility and CutsceneGhost on oObject
void Effects_ToggleCutsceneInvisibility(object oObject, int bInvisible);

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
