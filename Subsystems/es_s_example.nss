/*
    ScriptName: es_s_example.nss
    Created by: Daz

    Description: Example Subsystem showing an Example Simple Dialog Conversation
*/

//void main() {}

#include "es_inc_core"
#include "es_s_toolbox"
#include "es_s_simdialog"
#include "es_s_randomnpc"
#include "es_s_simai"
#include "es_s_chatcommand"

#include "nwnx_player"
#include "nwnx_admin"

const string EXAMPLE_SYSTEM_TAG = "Example";

// @EventSystem_Init
void Example_Init(string sEventHandlerScript)
{
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_PLACEABLE_ON_USED);

    SimpleDialog_SubscribeEvent(sEventHandlerScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN);
    SimpleDialog_SubscribeEvent(sEventHandlerScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE);
    SimpleDialog_SubscribeEvent(sEventHandlerScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION);
    SimpleDialog_SubscribeEvent(sEventHandlerScript, SIMPLE_DIALOG_EVENT_CONVERSATION_END);

    ChatCommand_Register(sEventHandlerScript, "Example_TestCommand", CHATCOMMAND_GLOBAL_PREFIX + "test", "[vfx]", "A test chat command!");
}

void Example_TestCommand(object oPlayer, string sParams, int nVolume)
{
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(StringToInt(sParams)), oPlayer);

    effect eDamage = EffectDamage(Random(10) + 1, DAMAGE_TYPE_DIVINE);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDamage, oPlayer);

    SetPCChatMessage("");
}

// @EventSystem_EventHandler
void Example_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_CONVERSATION_END)
    {
        string sConversationTag = ES_Core_GetEventData_NWNX_String("CONVERSATION_TAG");

        if (sConversationTag == "PottedPlantConversation")
        {
            object oPlayer = ES_Core_GetEventData_NWNX_Object("PLAYER");
            int bAborted = ES_Core_GetEventData_NWNX_Int("ABORTED");

            SendMessageToPC(oPlayer, "You " + (bAborted ?  "aborted" : "ended") + " the conversation with " + GetName(OBJECT_SELF));
        }
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE)
    {
        string sConversationTag = ES_Core_GetEventData_NWNX_String("CONVERSATION_TAG");

        if (sConversationTag == "PottedPlantConversation")
        {
            int nPage = ES_Core_GetEventData_NWNX_Int("PAGE");

            if (nPage == 1)
            {
                object oPlayer = ES_Core_GetEventData_NWNX_Object("PLAYER");

                if (Random(2))
                    SimpleDialog_SetOverrideText("Hello " + GetName(oPlayer) + ", I'm " + GetName(OBJECT_SELF) + ", what can I do for you?");
                else
                    SimpleDialog_SetOverrideText("Oi, what'cha want?");
            }
        }
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION)
    {
        string sConversationTag = ES_Core_GetEventData_NWNX_String("CONVERSATION_TAG");

        if (sConversationTag == "PottedPlantConversation")
        {
            object oPlayer = ES_Core_GetEventData_NWNX_Object("PLAYER");
            int nPage = ES_Core_GetEventData_NWNX_Int("PAGE");
            int nOption = ES_Core_GetEventData_NWNX_Int("OPTION");
            int bResult;

            if (nPage == 2)
            {
                if (nOption == 1)
                {
                    bResult = TRUE;

                    if (Random(2))
                        SimpleDialog_SetOverrideText("Gimme a beer, quick!");
                }
                else
                if (nOption == 2)
                {
                    bResult = GetGold(oPlayer) >= 50;
                 }
                else
                if (nOption == 4)
                {
                    int nCount;
                    object oItem = GetFirstItemInInventory(oPlayer);

                    while (GetIsObjectValid(oItem))
                    {
                        if (GetTag(oItem) == "NW_IT_MPOTION001")
                            nCount += GetItemStackSize(oItem);

                        oItem = GetNextItemInInventory(oPlayer);
                    }

                    bResult = nCount < 3;
                }
            }

            SimpleDialog_SetResult(bResult);
        }
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        string sConversationTag = ES_Core_GetEventData_NWNX_String("CONVERSATION_TAG");

        if (sConversationTag == "PottedPlantConversation")
        {
            object oPlayer = ES_Core_GetEventData_NWNX_Object("PLAYER");
            int nPage = ES_Core_GetEventData_NWNX_Int("PAGE");
            int nOption = ES_Core_GetEventData_NWNX_Int("OPTION");

            if (nPage == 1)
            {
                switch (nOption)
                {
                    case 1:
                        AssignCommand(oPlayer, ActionRest());
                        break;
                    case 2:
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;
                    case 3:
                        SimpleDialog_SetCurrentPage(oPlayer, 3);
                        break;
                    case 4:
                        GiveXPToCreature(oPlayer, StringToInt(Get2DAString("exptable", "XP", GetHitDice(oPlayer))) - GetXP(oPlayer));
                        break;
                    case 5:
                        SimpleDialog_SetCurrentPage(oPlayer, 4);
                        break;
                    case 6:
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                }
            }
            else
            if (nPage == 2)
            {
                switch (nOption)
                {
                    case 1:
                    {
                        CreateItemOnObject("nw_it_mpotion021", oPlayer);
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                    }
                    case 2:
                    {
                        CreateItemOnObject("nw_it_mpotion023", oPlayer);
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                    }
                    case 3:
                    {
                        CreateItemOnObject("nw_it_mpotion022", oPlayer);
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                    }
                    case 4:
                    {
                        CreateItemOnObject("nw_it_mpotion001", oPlayer);
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                    }
                    case 5:
                    {
                        SimpleDialog_SetCurrentPage(oPlayer, 1);
                        break;
                    }
                }
            }
            else
            if (nPage == 3)
            {
                if (nOption == 1)
                {
                    SimpleDialog_EndConversation(oPlayer);
                    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
                }
                else
                if (nOption == 2)
                    SimpleDialog_SetCurrentPage(oPlayer, 1);
            }
            else
            if (nPage == 4)
            {
                switch (nOption)
                {
                    case 1:
                    {
                        object oNPC = RandomNPC_GetRandomPregeneratedNPC("RandomNPC", ES_Util_GetRandomLocationAroundPoint(GetStartingLocation(), 2.5f));

                        string sBehavior = Random(2) ? "Wander" : "SitOnChair";

                        SendMessageToPC(oPlayer, "> " + GetName(oNPC) + " -> " + sBehavior);

                        SimpleAI_SetAIBehavior(oNPC, sBehavior);

                        break;
                    }

                    case 2:
                    {
                        object oArea = GetArea(oPlayer);
                        object oNPC = GetFirstObjectInArea(oArea);

                        while (GetIsObjectValid(oNPC))
                        {
                            if (GetTag(oNPC) == "RandomNPC")
                                DestroyObject(oNPC);

                            oNPC = GetNextObjectInArea(oArea);
                        }

                        break;
                    }

                    case 3:
                        SimpleDialog_SetCurrentPage(oPlayer, 1);
                        break;
                }
            }
        }
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_MODULE_ON_MODULE_LOAD:
            {
                // *** Create a placeable
                struct Toolbox_PlaceableData pd;

                pd.nModel = 83;
                pd.sName = "Potted Plant";
                pd.sDescription = "Just a talking plant?";
                pd.sTag = "ConvoTest";
                pd.bPlot = TRUE;
                pd.bUseable = TRUE;

                pd.scriptOnUsed = TRUE;

                object oPlaceable = Toolbox_CreatePlaceable(Toolbox_GeneratePlaceable(pd), ES_Util_GetRandomLocationAroundPoint(GetStartingLocation(), 5.0f));
                // ***

                // *** Create a Conversation
                object oConversation = SimpleDialog_CreateConversation("PottedPlantConversation");

                SimpleDialog_AddPage(oConversation, "Hello! What can I do for you?", TRUE);
                    SimpleDialog_AddOption(oConversation, "I would like to rest here.");
                    SimpleDialog_AddOption(oConversation, "I'm thirsty! Show me your drinks?");
                    SimpleDialog_AddOption(oConversation, "Know any secrets..?");
                    SimpleDialog_AddOption(oConversation, "One level up, please!");
                    SimpleDialog_AddOption(oConversation, "Give me the Random NPC Menu.");
                    SimpleDialog_AddOption(oConversation, "Oh, nothing, sorry...");

                SimpleDialog_AddPage(oConversation, "Sure! What would you like?");
                    SimpleDialog_AddOption(oConversation, "A beer, please.", TRUE);
                    SimpleDialog_AddOption(oConversation, "Some wine would be nice.", TRUE);
                    SimpleDialog_AddOption(oConversation, "Give me your strongest spirits!");
                    SimpleDialog_AddOption(oConversation, "Actually, I'd like a healing potion?", TRUE);
                    SimpleDialog_AddOption(oConversation, "On second thought... I'm not thirsty.");

                SimpleDialog_AddPage(oConversation, "I know many secrets, but if I told you I'd have to kill you.");
                    SimpleDialog_AddOption(oConversation, "Kill me anyway, you ...plant!");
                    SimpleDialog_AddOption(oConversation, "Err, forget I asked.");

                 SimpleDialog_AddPage(oConversation, "What would you like to do?");
                    SimpleDialog_AddOption(oConversation, "Spawn me a random NPC!");
                    SimpleDialog_AddOption(oConversation, "Destroy all random NPCs!");
                    SimpleDialog_AddOption(oConversation, "Nevermind.");
                /// ***
                break;
            }

            case EVENT_SCRIPT_PLACEABLE_ON_USED:
            {
                object oPlayer = GetLastUsedBy();
                object oPlaceable = OBJECT_SELF;

                if (GetTag(oPlaceable) != "ConvoTest")
                    return;

                NWNX_Player_SetPlaceableNameOverride(oPlayer, oPlaceable, "Cool Plant");

                SimpleDialog_StartConversation(oPlayer, oPlaceable, "PottedPlantConversation");
                break;
            }
        }
    }
}

