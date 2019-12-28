/*
    ScriptName: es_s_iditem.nss
    Created by: Daz

    Description: An EventSystem subsystem that replaces the skill needed to
                 identify an item with a custom one.
*/

//void main() {}

#include "es_inc_core"

const int ES_IDITEM_IDENTIFY_SKILL = SKILL_SPELLCRAFT;

// @EventSystem_Init
void InitIdentifyItemSubsystem(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_NWNX(sEventHandlerScript, "NWNX_ON_ITEM_USE_LORE_BEFORE");
}

// @EventSystem_EventHandler
void HandleLoreEvent(string sEventHandlerScript, string sEvent)
{
    if (sEvent == "NWNX_ON_ITEM_USE_LORE_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oItem = ES_Core_GetEventData_NWNX_Object("ITEM");

        int nIdentifySkill = GetSkillRank(ES_IDITEM_IDENTIFY_SKILL, oPlayer);
        int nMaxItemGPValue = StringToInt(Get2DAString("skillvsitemcost", "DeviceCostMax", nIdentifySkill == -1 ? 0 : nIdentifySkill > 55 ? 55 : nIdentifySkill));

        if (GetGoldPieceValue(oItem) > nMaxItemGPValue)
            NWNX_Events_SkipEvent();
        else
            SetIdentified(oItem, TRUE);
    }
}

