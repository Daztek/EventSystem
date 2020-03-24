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

    ChatCommand_Register(sSubsystemScript, "Portrait_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + PORTRAIT_CHATCOMMAND_NAME, "", "Change your portrait!");

    GUI_PreloadFont(PORTRAIT_FONT_TEXTURE_NAME);
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

int Portrait_DrawPortraitGUI(object oPlayer, int nPortraitNumber, int nRace, int nGender)
{
    int nId = PORTRAIT_POSTSTRING_START_ID;
    string sOptionFont = "fnt_dialog16x16";
    int nTextColor = GUI_COLOR_WHITE;
    int nPortraitColor = GUI_COLOR_WHITE;
    float fLifeTime = 0.0f;
    string sRace = Get2DAString("racialtypes", "Label", nRace);
    string sGender = nGender ? "Female" : "Male";
    string sPortraitString = sRace + ", " + sGender + ": " + IntToString(nPortraitNumber);
    string sPortraitTexture = Portrait_GetPortraitTexture(nPortraitNumber, nRace, nGender) + "h";

    if (FindSubString(sPortraitTexture, "_99_") != -1)
        nPortraitColor = GUI_COLOR_RED;

    SetTextureOverride(PORTRAIT_FONT_TEXTURE_NAME, sPortraitTexture, oPlayer);

    PostString(oPlayer, "Fancy Portrait Changer", 14, 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);

    PostString(oPlayer, "a", 12, 3, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++, PORTRAIT_FONT_TEXTURE_NAME);
    PostString(oPlayer, sPortraitString, 27 - (GUI_CalculateStringLength(sPortraitString) / 2), 32, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nPortraitColor, nPortraitColor, nId++);

    PostString(oPlayer, "Options", 2, 6,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++);
    PostString(oPlayer, "1. [Select]", 3, 8,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "2. [Next]", 3, 9,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "3. [Previous]", 3, 10, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "4. [" + sRace + "]", 3, 11, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "5. [" + sGender + "]", 3, 12, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);
    PostString(oPlayer, "6. [End]", 3, 13, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nId++, sOptionFont);

    return GUI_DrawConversationWindow(oPlayer, nId, 46, 32, 0.0f);
}

void Portrait_ChatCommand(object oPlayer, string sEmote, int nVolume)
{
    int nPortraitNumber = StringToInt(GetSubString(GetPortraitResRef(oPlayer), 8, 2));
    int nRace = GetRacialType(oPlayer);
    int nGender = GetGender(oPlayer);

    if (nPortraitNumber == 99)
        nPortraitNumber = 1;

    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", nPortraitNumber);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);

    NWNX_Player_PlaySound(oPlayer, "gui_select");

    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, PORTRAIT_SCRIPT_NAME, oPlayer);
    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, PORTRAIT_SCRIPT_NAME, oPlayer);

    SimpleDialog_StartConversation(oPlayer, oPlayer, PORTRAIT_SCRIPT_NAME, 1, TRUE);

    int nMaxPostStringID = Portrait_DrawPortraitGUI(oPlayer, nPortraitNumber, nRace, nGender);

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

        int nPortraitNumber = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber");
        int nRace = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race");
        int nGender = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender");

        NWNX_Player_PlaySound(oPlayer, "gui_select");

        switch (nOption)
        {
            case 1:
            {
                string sPortrait = Portrait_GetPortraitTexture(nPortraitNumber, nRace, nGender);
                SetPortraitResRef(oPlayer, sPortrait);
                break;
            }

            case 2:
            {
                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", ++nPortraitNumber);
                break;
            }

            case 3:
            {
                if (nPortraitNumber > 1)
                    ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_PortraitNumber", --nPortraitNumber);
                break;
            }

            case 4:
            {
                if (++nRace > 6)
                    nRace = 0;

                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Race", nRace);
                break;
            }

            case 5:
            {
                nGender = !nGender;
                ES_Util_SetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_Gender", nGender);
                break;
            }

            case 6:
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
        int nMaxPostStringID = ES_Util_GetInt(oPlayer, PORTRAIT_SCRIPT_NAME + "_MaxPostStringID");

        ES_Util_DeleteIntRegex(oPlayer, ".*" + PORTRAIT_SCRIPT_NAME + ".*");

        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oPlayer);
        NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_CONVERSATION_END, sSubsystemScript, oPlayer);

        DelayCommand(0.1f, GUI_ClearRange(oPlayer, PORTRAIT_POSTSTRING_START_ID, nMaxPostStringID));
    }
}

