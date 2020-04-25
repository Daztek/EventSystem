/*
    ScriptName: es_s_portrait.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player]

    Description: A Portrait Change Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_gui"
#include "es_srv_simdialog"
#include "es_srv_chatcom"

#include "nwnx_player"

const string PORTRAIT_LOG_TAG                   = "Portrait";
const string PORTRAIT_SCRIPT_NAME               = "es_s_portrait";
const string PORTRAIT_CHATCOMMAND_NAME          = "portrait";
const string PORTRAIT_CHATCOMMAND_DESCRIPTION   = "Change your portrait!";
const int PORTRAIT_GUI_NUM_IDS                  = 70;
const string PORTRAIT_FONT_TEXTURE_NAME         = "fnt_es_portrait";
const string PORTRAIT_GLYPH_NAME                = "a";

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

    ChatCommand_Register(sSubsystemScript, "Portrait_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + PORTRAIT_CHATCOMMAND_NAME, "", PORTRAIT_CHATCOMMAND_DESCRIPTION);

    GUI_ReserveIDs(sSubsystemScript, PORTRAIT_GUI_NUM_IDS);
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

void Portrait_DrawMainPortraitGUI(object oPlayer)
{
    int nID = GUI_GetEndID(PORTRAIT_SCRIPT_NAME);
    int nTextColor = GUI_COLOR_WHITE;
    int nPortraitColor = GUI_COLOR_WHITE;
    string sTextFont = GUI_FONT_TEXT_NAME;
    float fLifeTime = 0.0f;

    // Conversation Window
    nID -= GUI_DrawConversationWindow(oPlayer, nID, 51, 31, fLifeTime, FALSE);

    // Options Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 1, 5, 13, 8, fLifeTime, FALSE);

    // Portrait Texture
    PostString(oPlayer, PORTRAIT_GLYPH_NAME, 15, 2, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nID--, PORTRAIT_FONT_TEXTURE_NAME);

    // Header Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 14, 0, 32, 1, fLifeTime, FALSE);

    // Header Text
    string sHeader = GetName(oPlayer) + "'s Portrait";
    PostString(oPlayer, sHeader, GUI_CenterStringInWindow(sHeader, 14, 32), 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID--, sTextFont);

    // Portrait Name Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 14, 29, 32, 1, fLifeTime, FALSE);
}

void Portrait_UpdatePortraitGUI(object oPlayer, int nPortraitNumber, int nRace, int nGender)
{
    int nID = GUI_GetStartID(PORTRAIT_SCRIPT_NAME);
    int nTextColor = GUI_COLOR_WHITE;
    string sTextFont = GUI_FONT_TEXT_NAME;
    int nPortraitTextColor = GUI_COLOR_WHITE;
    float fLifeTime = 0.0f;

    string sRace = Get2DAString("racialtypes", "Label", nRace);
    string sGender = nGender ? "Female" : "Male";
    string sPortraitString = sRace + ", " + sGender + ": " + IntToString(nPortraitNumber);
    string sPortraitTexture = Portrait_GetPortraitTexture(nPortraitNumber, nRace, nGender) + "h";

    if (sPortraitTexture == "po_hu_m_99_h" || sPortraitTexture == "po_hu_f_99_h")
        nPortraitTextColor = GUI_COLOR_RED;

    // Portrait Name
    PostString(oPlayer, sPortraitString, GUI_CenterStringInWindow(sPortraitString, 14, 32), 30, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitTextColor, nPortraitTextColor, nID++, sTextFont);

    // Options
    int nOptionsX = 4, nOptionsY = 8;
    PostString(oPlayer, "Options", 4, 6,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "1.Select", nOptionsX, nOptionsY++,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "2.Next", nOptionsX, nOptionsY++, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "3.Previous", nOptionsX, nOptionsY++, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "4." + sRace, nOptionsX, nOptionsY++, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "5." + sGender, nOptionsX, nOptionsY++, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    GUI_Draw(oPlayer, GUI_FONT_GUI_GLYPH_ARROW, 2, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, nID++, fLifeTime);
    PostString(oPlayer, "6.End", nOptionsX, nOptionsY, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, sPortraitTexture, oPlayer);
}

void Portrait_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    if (SimpleDialog_IsInConversation(oPlayer, PORTRAIT_SCRIPT_NAME))
        SimpleDialog_AbortConversation(oPlayer);
    else
    {
        if (IsInConversation(oPlayer))
            SimpleDialog_AbortConversation(oPlayer);

        int nParams = StringToInt(sParams);
        int nPortraitNumber = (nParams != 0 ? nParams : 1);
        int nRace = GetRacialType(oPlayer);
        int nGender = GetGender(oPlayer);

        SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", nPortraitNumber);
        SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
        SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);

        NWNX_Player_PlaySound(oPlayer, "gui_select");

        Events_AddObjectToDispatchList(PORTRAIT_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
        Events_AddObjectToDispatchList(PORTRAIT_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_CONVERSATION_END, oPlayer);

        SimpleDialog_StartConversation(oPlayer, oPlayer, PORTRAIT_SCRIPT_NAME, 1, TRUE);

        Portrait_DrawMainPortraitGUI(oPlayer);
        Portrait_UpdatePortraitGUI(oPlayer, nPortraitNumber, nRace, nGender);
    }

    SetPCChatMessage("");
}

// @EventHandler
void Portrait_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oPlayer = OBJECT_SELF;
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        int nPortraitNumber = GetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber");
        int nRace = GetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
        int nGender = GetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

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
                SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", ++nPortraitNumber);
                break;
            }

            case 3: // Previous
            {
                if (nPortraitNumber > 1)
                    SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", --nPortraitNumber);
                break;
            }

            case 4: // Race
            {
                if (++nRace > 6)
                    nRace = 0;

                SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
                break;
            }

            case 5: // Gender
            {
                nGender = !nGender;
                SetLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);
                break;
            }

            case 6: // End
            {
                SimpleDialog_EndConversation(oPlayer);
                return;
            }
        }

        Portrait_UpdatePortraitGUI(oPlayer, nPortraitNumber, nRace, nGender);
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONVERSATION_END)
    {
        object oPlayer = OBJECT_SELF;

        DeleteLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber");
        DeleteLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
        DeleteLocalInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

        Events_RemoveObjectFromDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
        Events_RemoveObjectFromDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONVERSATION_END, oPlayer);

        SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, "", oPlayer);

        DelayCommand(0.1f, GUI_ClearBySubsystem(oPlayer, PORTRAIT_SCRIPT_NAME));
    }
}

