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

const int PORTRAIT_GUI_NUM_IDS              = 50;

const string PORTRAIT_FONT_TEXTURE_NAME     = "fnt_portrait";
const string PORTRAIT_GLYPH_NAME            = "a";

// @Load
void Portrait_Load(string sSubsystemScript)
{
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONVERSATION_END, TRUE);

    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);

    SimpleDialog_AddPage(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Portrait Change Menu
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Select
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Next
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Previous
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Race
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // Gender
        SimpleDialog_AddOption(oConversation, SIMPLE_DIALOG_BLANK_ENTRY_TEXT); // End

    ChatCommand_Register(sSubsystemScript, "Portrait_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + PORTRAIT_CHATCOMMAND_NAME, "", "Change your portrait!");

    GUI_RequestSubsystemIDs(sSubsystemScript, PORTRAIT_GUI_NUM_IDS);
    GUI_PreloadFontTexture(PORTRAIT_FONT_TEXTURE_NAME);
}

string Portrait_GetPortraitTexture(int nPortraitNumber, int nRace, int nGender)
{
    string sNumber = nPortraitNumber < 10 ? "0" + IntToString(nPortraitNumber) : IntToString(nPortraitNumber);
    string sRace = GetSubString("dwelgnhahuorhu", 2 * nRace, 2);
    string sGender = !nGender ? "m" : "f";

    string sPortrait = "po_" + sRace + "_" + sGender + "_" + sNumber + "_";

    if (NWNX_Util_IsValidResRef(sPortrait + "h", 3/* TGA */))
        return sPortrait;
    else
        return "po_hu_" + sGender + "_99_";
}

void Portrait_DrawPortraitGUI(object oPlayer, int nPortraitNumber, int nRace, int nGender)
{
    int nId = GUI_GetSubsystemStartID(PORTRAIT_SCRIPT_NAME);
    string sOptionFont = "fnt_dialog16x16";
    int nTextColor = GUI_COLOR_WHITE;
    int nPortraitColor = GUI_COLOR_WHITE;
    float fLifeTime = 0.0f;
    string sRace = Get2DAString("racialtypes", "Label", nRace);
    string sGender = nGender ? "Female" : "Male";
    string sPortraitString = sRace + ", " + sGender + ": " + IntToString(nPortraitNumber);
    string sPortraitTexture = Portrait_GetPortraitTexture(nPortraitNumber, nRace, nGender) + "h";

    if (sPortraitTexture == "po_hu_m_99_h" || sPortraitTexture == "po_hu_f_99_h")
        nPortraitColor = GUI_COLOR_RED;

    SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, sPortraitTexture, oPlayer);

    PostString(oPlayer, "Fancy Portrait Changer", 14, 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);

    PostString(oPlayer, PORTRAIT_GLYPH_NAME, 12, 3, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++, PORTRAIT_FONT_TEXTURE_NAME);
    PostString(oPlayer, sPortraitString, 27 - (GUI_CalculateStringLength(sPortraitString) / 2), 32, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++);

    PostString(oPlayer, "Options", 2, 6,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);
    PostString(oPlayer, "1. [Select]", 3, 8,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "2. [Next]", 3, 9,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "3. [Previous]", 3, 10, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "4. [" + sRace + "]", 3, 11, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "5. [" + sGender + "]", 3, 12, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "6. [End]", 3, 13, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);

    GUI_DrawConversationWindow(oPlayer, nId, 46, 32, 0.0f);
}

void Portrait_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    int nPortraitNumber = 1;
    int nRace = GetRacialType(oPlayer);
    int nGender = GetGender(oPlayer);

    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", nPortraitNumber);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);

    NWNX_Player_PlaySound(oPlayer, "gui_select");

    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, PORTRAIT_SCRIPT_NAME, oPlayer);
    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, PORTRAIT_SCRIPT_NAME, oPlayer);

    SimpleDialog_StartConversation(oPlayer, oPlayer, PORTRAIT_SCRIPT_NAME, 1, TRUE);

    Portrait_DrawPortraitGUI(oPlayer, nPortraitNumber, nRace, nGender);

    SetPCChatMessage("");
}

// @EventHandler
void Portrait_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oPlayer = OBJECT_SELF;
        int nOption = ES_Util_GetEventData_NWNX_Int("OPTION");

        int nPortraitNumber = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber");
        int nRace = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
        int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

        NWNX_Player_PlaySound(oPlayer, "gui_select");

        switch (nOption)
        {
            case 1: // Select
            {
                string sPortrait = Portrait_GetPortraitTexture(nPortraitNumber, nRace, nGender);
                SetPortraitResRef(oPlayer, sPortrait);
                break;
            }

            case 2: // Next
            {
                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", ++nPortraitNumber);
                break;
            }

            case 3: // Previous
            {
                if (nPortraitNumber > 1)
                    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", --nPortraitNumber);
                break;
            }

            case 4: // Race
            {
                if (++nRace > 6)
                    nRace = 0;

                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
                break;
            }

            case 5: // Gender
            {
                nGender = !nGender;
                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);
                break;
            }

            case 6: // End
            {
                SimpleDialog_EndConversation(oPlayer);
                return;
            }
        }

        Portrait_DrawPortraitGUI(oPlayer, nPortraitNumber, nRace, nGender);
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONVERSATION_END)
    {
        object oPlayer = OBJECT_SELF;

        ES_Util_DeleteIntRegex(oPlayer, ".*" + PORTRAIT_SCRIPT_NAME + ".*");

        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oPlayer);
        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, sSubsystemScript, oPlayer);

        DelayCommand(0.1f, GUI_ClearBySubsystem(oPlayer, PORTRAIT_SCRIPT_NAME));
    }
}

