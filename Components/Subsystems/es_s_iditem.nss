/*
    ScriptName: es_s_iditem.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that replaces the skill needed to
                 identify an item with a custom one.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_mediator"

const string IDITEM_LOG_TAG         = "IdentifyItem";
const string IDITEM_SCRIPT_NAME     = "es_s_iditem";

const int IDITEM_IDENTIFY_SKILL     = SKILL_SPELLCRAFT;

// Returns the skill used to identify items
int IdentifyItem_GetIdentifySkill();

// @Load
void IdentifyItem_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_ITEM_USE_LORE_BEFORE");
    Mediator_RegisterFunction(sSubsystemScript, "IdentifyItem_GetIdentifySkill", "", "i");
}

// @EventHandler
void IdentifyItem_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_ITEM_USE_LORE_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oItem = Events_GetEventData_NWNX_Object("ITEM");

        SetIdentified(oItem, TRUE);

        int nIdentifySkillRank = GetSkillRank(IDITEM_IDENTIFY_SKILL, oPlayer);
        int nMaxItemGPValue = StringToInt(Get2DAString("skillvsitemcost", "DeviceCostMax", nIdentifySkillRank == -1 ? 0 : nIdentifySkillRank > 55 ? 55 : nIdentifySkillRank));
        int nGoldPieceValue = GetGoldPieceValue(oItem);

        if (nGoldPieceValue > nMaxItemGPValue)
        {
            SetIdentified(oItem, FALSE);
            Events_SkipEvent();
        }
    }
}

int IdentifyItem_GetIdentifySkill()
{
    return IDITEM_IDENTIFY_SKILL;
}

