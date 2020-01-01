/*
    ScriptName: es_s_iditem.nss
    Created by: Daz

    Description: An EventSystem subsystem that replaces the skill needed to
                 identify an item with a custom one.
*/

//void main() {}

#include "es_inc_core"

const int IDITEM_IDENTIFY_SKILL = SKILL_SPELLCRAFT;

// @EventSystem_Init
void IdentifyItem_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_NWNX(sEventHandlerScript, "NWNX_ON_ITEM_USE_LORE_BEFORE");
}

// @EventSystem_EventHandler
void IdentifyItem_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == "NWNX_ON_ITEM_USE_LORE_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oItem = ES_Core_GetEventData_NWNX_Object("ITEM");

        SetIdentified(oItem, TRUE);

        int nIdentifySkill = GetSkillRank(IDITEM_IDENTIFY_SKILL, oPlayer);
        int nMaxItemGPValue = StringToInt(Get2DAString("skillvsitemcost", "DeviceCostMax", nIdentifySkill == -1 ? 0 : nIdentifySkill > 55 ? 55 : nIdentifySkill));
        int nGoldPieceValue = GetGoldPieceValue(oItem);

        if (nGoldPieceValue > nMaxItemGPValue)
        {
            SetIdentified(oItem, FALSE);
            NWNX_Events_SkipEvent();
        }
    }
}

