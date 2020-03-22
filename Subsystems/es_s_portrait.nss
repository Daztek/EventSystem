/*
    ScriptName: es_s_portrait.nss
    Created by: Daz

    Description: A Portrait Change Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_gui"
#include "es_srv_simdialog"
#include "es_srv_chatcom"

#include "nwnx_player"

const string PORTRAIT_LOG_TAG               = "Portrait";
const string PORTRAIT_SCRIPT_NAME           = "es_s_portrait";

const string PORTRAIT_CHATCOMMAND_NAME      = "portrait";
const int PORTRAIT_POSTSTRING_START_ID      = 100;
const string PORTRAIT_FONT_TEXTURE_NAME     = "fnt_portrait";

// @Load
void Portrait_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);

    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONVERSATION_END);

    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);
    SimpleDialog_AddPage(oConversation, "Portrait Change Menu.", TRUE);
        SimpleDialog_AddOption(oConversation, "[Select]");
        SimpleDialog_AddOption(oConversation, "[Next]");
        SimpleDialog_AddOption(oConversation, "[Previous]");
        SimpleDialog_AddOption(oConversation, "[Gender]");
        SimpleDialog_AddOption(oConversation, "[End]");

    ChatCommand_Register(sSubsystemScript, "Emote_PortraitChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + PORTRAIT_CHATCOMMAND_NAME, "", "Change your portrait!");
}

string Portrait_GetPortraitName(object oPlayer)
{
    int nPortrait = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait");
    int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

    string sNumber = nPortrait <= 9 ? "0" + IntToString(nPortrait) : IntToString(nPortrait);
    string sGender = nGender ? "f" : "m";

    return "po_hu_" + sGender + "_" + sNumber + "_";
}

int Portrait_DrawPortraitGUI(object oPlayer, string sPortrait)
{
    int nId = PORTRAIT_POSTSTRING_START_ID;
    string sOptionFont = "fnt_dialog16x16";

    SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, sPortrait, oPlayer);

    PostString(oPlayer, "Useless Portrait Changer", 13, 1, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++);
    PostString(oPlayer, "a", 12, 3, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, PORTRAIT_FONT_TEXTURE_NAME);
    PostString(oPlayer, sPortrait, (GUI_CalculateStringLength(sPortrait) / 2) + 10, 32, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++);

    PostString(oPlayer, "Options", 2, 6, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++);
    PostString(oPlayer, "[Select]", 3, 8, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, sOptionFont);
    PostString(oPlayer, "[Next]", 3, 9, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, sOptionFont);
    PostString(oPlayer, "[Previous]", 3, 10, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, sOptionFont);
    PostString(oPlayer, "[Gender]", 3, 11, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, sOptionFont);
    PostString(oPlayer, "[End]", 3, 12, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, nId++, sOptionFont);

    return GUI_DrawConversationWindow(oPlayer, nId, SCREEN_ANCHOR_TOP_LEFT, 0, 0, 46, 32, 0.0f);
}

void Emote_PortraitChatCommand(object oPlayer, string sEmote, int nVolume)
{
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait", 1);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", GetGender(oPlayer));

    SimpleDialog_StartConversation(oPlayer, oPlayer, PORTRAIT_SCRIPT_NAME);

    string sPortrait = Portrait_GetPortraitName(oPlayer) + "h";
    int nMaxPostStringId = Portrait_DrawPortraitGUI(oPlayer, sPortrait);

    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_MaxPostStringId", nMaxPostStringId);

    SetPCChatMessage("");
}

// @EventHandler
void Portrait_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oPlayer = OBJECT_SELF;
        int nOption = ES_Util_GetEventData_NWNX_Int("OPTION");

        int nPortrait = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait");
        int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

        NWNX_Player_PlaySound(oPlayer, "gui_dm_alert");

        switch (nOption)
        {
            case 1:
            {
                string sPortrait = Portrait_GetPortraitName(oPlayer);

                NWNX_Player_PlaySound(oPlayer, "gui_trapsetoff");

                SetPortraitResRef(oPlayer, sPortrait);
                break;
            }

            case 2:
            {
                nPortrait++;
                break;
            }

            case 3:
            {
                if (nPortrait > 1)
                    nPortrait--;
                break;
            }

            case 4:
            {
                nGender = !nGender;
                break;
            }

            case 5:
            {
                SimpleDialog_EndConversation(oPlayer);
                return;
            }
        }

        ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait", nPortrait);
        ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);

        string sPortrait = Portrait_GetPortraitName(oPlayer) + "h";
        Portrait_DrawPortraitGUI(oPlayer, sPortrait);
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONVERSATION_END)
    {
        object oPlayer = OBJECT_SELF;
        int nMaxPostStringId = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_MaxPostStringId");

        ES_Util_DeleteIntRegex(oPlayer, ".*" + PORTRAIT_SCRIPT_NAME + ".*");

        DelayCommand(0.1f, GUI_ClearIDRange(oPlayer, PORTRAIT_POSTSTRING_START_ID, nMaxPostStringId));
    }
    else
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER)
    {
        // Preload the portrait font
        PostString(GetEnteringObject(), "a", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.01f, 0xFFFFFFF00, 0xFFFFFF00, PORTRAIT_POSTSTRING_START_ID, PORTRAIT_FONT_TEXTURE_NAME);
    }
}

