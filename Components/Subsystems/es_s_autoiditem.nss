/*
    ScriptName: es_s_autoiditem.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that automatically identifies the items a player acquires.
                 If es_s_iditem is enabled, it will use its identify item skill instead of Lore.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_mediator"

const string AUTOIDITEM_LOG_TAG         = "AutoIdentifyItem";
const string AUTOIDITEM_SCRIPT_NAME     = "es_s_autoiditem";

const string AUTOIDITEM_SKILL_NAME      = "AutoIdentifySkill";

// @Load
void AutoIDItem_Load(string sComponentScript)
{
    Events_SubscribeEvent_Object(sComponentScript, EVENT_SCRIPT_MODULE_ON_ACQUIRE_ITEM);
}

// @EventHandler
void AutoIDItem_EventHandler(string sComponentScript, string sEvent)
{
    object oPlayer = GetModuleItemAcquiredBy();
    object oItem = GetModuleItemAcquired();

    if (GetIsPC(oPlayer) && !GetIdentified(oItem))
    {
        int nIdentifySkill = GetLocalInt(ES_Util_GetDataObject(sComponentScript), AUTOIDITEM_SKILL_NAME);
        int nIdentifySkillRank = GetSkillRank(nIdentifySkill, oPlayer);
        int nMaxItemGPValue = StringToInt(Get2DAString("skillvsitemcost", "DeviceCostMax", nIdentifySkillRank == -1 ? 0 : nIdentifySkillRank > 55 ? 55 : nIdentifySkillRank));

        SetIdentified(oItem, TRUE);

        int nGoldPieceValue = GetGoldPieceValue(oItem);
        if (nGoldPieceValue > nMaxItemGPValue)
            SetIdentified(oItem, FALSE);
        else
            FloatingTextStringOnCreature("Identified '" + GetName(oItem) + "'!", oPlayer, FALSE);
    }
}

// @Post
void AutoIDItem_Post(string sComponentScript)
{
    if (Mediator_ExecuteFunction("es_s_iditem", "IdentifyItem_GetIdentifySkill", "", GetModule(), FALSE))
    {
        int nIdentifySkill = Mediator_GetReturnValueInt();

        SetLocalInt(ES_Util_GetDataObject(sComponentScript), AUTOIDITEM_SKILL_NAME, nIdentifySkill);

        ES_Util_Log(AUTOIDITEM_LOG_TAG, "Subsystem 'es_s_iditem' is enabled, using its Identify Skill: " + Get2DAString("skills", "Label", nIdentifySkill));
    }
    else
    {
        SetLocalInt(ES_Util_GetDataObject(sComponentScript), AUTOIDITEM_SKILL_NAME, SKILL_LORE);

        ES_Util_Log(AUTOIDITEM_LOG_TAG, "Subsystem 'es_s_iditem' is not enabled, using default Identify Skill: " + Get2DAString("skills", "Label", SKILL_LORE));
    }
}

