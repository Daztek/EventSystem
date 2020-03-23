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
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONVERSATION_END, TRUE);

    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);
    SimpleDialog_AddPage(oConversation, "Portrait Change Menu.", TRUE);
        SimpleDialog_AddOption(oConversation, "[Select]");
        SimpleDialog_AddOption(oConversation, "[Next]");
        SimpleDialog_AddOption(oConversation, "[Previous]");
        SimpleDialog_AddOption(oConversation, "[Race]");
        SimpleDialog_AddOption(oConversation, "[Gender]");
        SimpleDialog_AddOption(oConversation, "[End]");

    ChatCommand_Register(sSubsystemScript, "Emote_PortraitChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + PORTRAIT_CHATCOMMAND_NAME, "", "Change your portrait!");

    GUI_PreloadFont(PORTRAIT_FONT_TEXTURE_NAME);
}

string Portrait_GetPortraitName(object oPlayer)
{
    int nPortrait = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait");
    int nRace = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
    int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

    string sNumber = nPortrait < 10 ? "0" + IntToString(nPortrait) : IntToString(nPortrait);
    string sRace = GetSubString("dwelgnhahuorhu", 2 * nRace, 2);
    string sGender = !nGender ? "m" : "f";

    string sPortrait = "po_" + sRace + "_" + sGender + "_" + sNumber + "_";

    if (NWNX_Util_IsValidResRef(sPortrait + "h", 3/* TGA */))
        return sPortrait;
    else
        return "po_hu_" + sGender + "_99_";
}

string Portrait_GetPrettyPortraitString(object oPlayer)
{
    int nPortrait = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait");
    int nRace = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
    int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

    return Get2DAString("racialtypes", "Label", nRace) + ", " + (nGender ? "Female" : "Male") + ": " + IntToString(nPortrait);
}

int Portrait_DrawPortraitGUI(object oPlayer, string sPortrait)
{
    int nId = PORTRAIT_POSTSTRING_START_ID;
    string sOptionFont = "fnt_dialog16x16";
    int nTextColor = GUI_COLOR_WHITE;
    int nPortraitColor = GUI_COLOR_WHITE;
    float fLifeTime = 0.0f;
    string sPrettyPortraitString = Portrait_GetPrettyPortraitString(oPlayer);
    int nPrettyLength = GUI_CalculateStringLength(sPrettyPortraitString);

    SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, sPortrait, oPlayer);

    if (FindSubString(sPortrait, "_99_") != -1)
        nPortraitColor = GUI_COLOR_RED;

    PostString(oPlayer, "Fancy Portrait Changer", 14, 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);

    PostString(oPlayer, "a", 12, 3, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++, PORTRAIT_FONT_TEXTURE_NAME);
    PostString(oPlayer, sPrettyPortraitString, 27 - (GUI_CalculateStringLength(sPrettyPortraitString) / 2), 32, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++);

    PostString(oPlayer, "Options",          2, 6,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);
    PostString(oPlayer, "1. [Select]",      3, 8,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "2. [Next]",        3, 9,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "3. [Previous]",    3, 10, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "4. [Race]",        3, 11, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "5. [Gender]",      3, 12, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "6. [End]",         3, 13, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);

    return GUI_DrawConversationWindow(oPlayer, nId, 46, 32, 0.0f);
}

void Emote_PortraitChatCommand(object oPlayer, string sEmote, int nVolume)
{
    int nCurrentPortraitNum = StringToInt(GetSubString(GetPortraitResRef(oPlayer), 8, 2));

    if (nCurrentPortraitNum == 99)
        nCurrentPortraitNum = 1;

    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait", nCurrentPortraitNum);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", GetRacialType(oPlayer));
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", GetGender(oPlayer));

    NWNX_Player_PlaySound(oPlayer, "gui_select");

    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, PORTRAIT_SCRIPT_NAME, oPlayer);
    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, PORTRAIT_SCRIPT_NAME, oPlayer);

    SimpleDialog_StartConversation(oPlayer, oPlayer, PORTRAIT_SCRIPT_NAME, 1, TRUE);

    string sPortrait = Portrait_GetPortraitName(oPlayer) + "h";
    int nMaxPostStringID = Portrait_DrawPortraitGUI(oPlayer, sPortrait);

    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_MaxPostStringID", nMaxPostStringID);

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
        int nRace = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
        int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

        NWNX_Player_PlaySound(oPlayer, "gui_select");

        switch (nOption)
        {
            case 1:
            {
                string sPortrait = Portrait_GetPortraitName(oPlayer);
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

                nRace++;

                if (nRace > 6)
                    nRace = 0;

                break;
            }

            case 5:
            {
                nGender = !nGender;
                break;
            }

            case 6:
            {
                SimpleDialog_EndConversation(oPlayer);
                return;
            }
        }

        ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Portrait", nPortrait);
        ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
        ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);

        string sPortrait = Portrait_GetPortraitName(oPlayer) + "h";
        Portrait_DrawPortraitGUI(oPlayer, sPortrait);
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONVERSATION_END)
    {
        object oPlayer = OBJECT_SELF;
        int nMaxPostStringID = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_MaxPostStringID");

        ES_Util_DeleteIntRegex(oPlayer, ".*" + PORTRAIT_SCRIPT_NAME + ".*");

        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oPlayer);
        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, sSubsystemScript, oPlayer);

        DelayCommand(0.1f, GUI_ClearRange(oPlayer, PORTRAIT_POSTSTRING_START_ID, nMaxPostStringID));
    }
}

