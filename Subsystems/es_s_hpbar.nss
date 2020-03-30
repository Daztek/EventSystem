/*
    ScriptName: es_s_hpbar.nss
    Created by: Daz

    Description: A HealthBar Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_gui"
#include "es_srv_chatcom"

const string HEALTHBAR_LOG_TAG                  = "HealthBar";
const string HEALTHBAR_SCRIPT_NAME              = "es_s_hpbar";

const string HEALTHBAR_CHATCOMMAND_NAME         = "hb";
const string HEALTHBAR_CHATCOMMAND_DESCRIPTION  = "Customize HealthBar Settings.";

const int HEALTHBAR_GUI_NUM_IDS                 = 15;
const string HEALTHBAR_PORTRAIT_FONT_NAME       = "fnt_es_hbport";
const string HEALTHBAR_PORTRAIT_GLYPH           = "a";

const int HEALTHBAR_DEFAULT_WIDTH               = 30;

struct HealthBar_Data
{
    string sName;
    string sInfo;
    string sPortrait;

    string sHealthBar;
    string sHurtBar;
    string sHealthBarInfo;

    int nID;
    int nX;
    int nY;
    int nWidth;

    int nNameColor;
    int nInfoColor;
    int nHealthBarColor;
    int nHurtBarColor;
    int nHealthBarInfoColor;
    int nPortraitDeadColor;

    float fLifeTime;
};

string HealthBar_GetHealthBarString(int nCurrentHitPoints, int nMaxHitPoints, int nWidth);
string HealthBar_GetHurtBarString(int nWidth);
string HealthBar_GetHealthBarInfoString(int nCurrentHitPoints, int nMaxHitPoints);
struct HealthBar_Data HealthBar_Update(object oCreature = OBJECT_SELF, string sInfo = "", int nWidth = HEALTHBAR_DEFAULT_WIDTH);
struct HealthBar_Data HealthBar_AddCustomPlayerSettings(object oPlayer, struct HealthBar_Data hbd);
void HealthBar_Draw(object oPlayer, struct HealthBar_Data hbd);

// @Load
void HealthBar_Load(string sSubsystemScript)
{
    GUI_ReserveIDs(sSubsystemScript, HEALTHBAR_GUI_NUM_IDS);

    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DAMAGED, ES_CORE_EVENT_FLAG_AFTER, TRUE);

    ChatCommand_Register(sSubsystemScript, "HealthBar_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + HEALTHBAR_CHATCOMMAND_NAME, "[option] [value]", HEALTHBAR_CHATCOMMAND_DESCRIPTION);

    // TESTING
    object oDeer = GetObjectByTag("TestDeer");
    ES_Core_SetObjectEventScript(oDeer, EVENT_SCRIPT_CREATURE_ON_DAMAGED, FALSE);
    NWNX_Events_AddObjectToDispatchList(ES_Core_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DAMAGED, ES_CORE_EVENT_FLAG_AFTER), sSubsystemScript, oDeer);
    // ***
}

// @EventHandler
void HealthBar_EventHandler(string sSubsystemScript, string sEvent)
{
    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_CREATURE_ON_DAMAGED:
        {
            object oCreature = OBJECT_SELF;
            object oDamager = GetLastDamager(oCreature);

            // TESTING
            string sInfo = GetLocalString(oCreature, "HealthBar_Info");
            int nOverrideWidth = GetLocalInt(oCreature, "HealthBar_Width");
            int nWidth = nOverrideWidth ? nOverrideWidth : HEALTHBAR_DEFAULT_WIDTH;

            struct HealthBar_Data hbd = HealthBar_Update(oCreature, sInfo, nWidth);

            HealthBar_Draw(oDamager, hbd);
            // ***

            break;
        }
    }
}

void HealthBar_SendInfoChatMessage(object oPlayer, string sMessage)
{
    SendMessageToPC(oPlayer, ES_Util_ColorString(HEALTHBAR_LOG_TAG + ": ", "070") + sMessage);
}

void HealthBar_SetIntegerOption(object oPlayer, string sOption, string sValue)
{
    if (sValue == "")
    {
        int nValue = ES_Util_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_" + sOption);

        HealthBar_SendInfoChatMessage(oPlayer, "Current " + sOption + " value: " + IntToString(nValue));
    }
    else
    {
        int nValue = StringToInt(sValue);

        if (nValue >= 0)
        {
            HealthBar_SendInfoChatMessage(oPlayer, "Setting " + sOption + " to: " + IntToString(nValue));

            ES_Util_SetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_" + sOption, nValue, TRUE);
        }
        else
            HealthBar_SendInfoChatMessage(oPlayer, "" + sOption + " value must be >= 0");
    }
}

void HealthBar_ChatCommand(object oPlayer, string sOption, int nVolume)
{
    string sParams, sHelp;

    if ((sParams = ChatCommand_Parse(sOption, "x")) != CHATCOMMAND_PARSE_ERROR)
        HealthBar_SetIntegerOption(oPlayer, "X", sParams);
    else
    if ((sParams = ChatCommand_Parse(sOption, "y")) != CHATCOMMAND_PARSE_ERROR)
        HealthBar_SetIntegerOption(oPlayer, "Y", sParams);
    else
    if ((sParams = ChatCommand_Parse(sOption, "preview")) != CHATCOMMAND_PARSE_ERROR)
    {
        HealthBar_SendInfoChatMessage(oPlayer, "Preview");

        HealthBar_Draw(oPlayer, HealthBar_Update(oPlayer, "It's you, oh no!"));
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "clear")) != CHATCOMMAND_PARSE_ERROR)
    {
        HealthBar_SendInfoChatMessage(oPlayer, "Cleared");

        GUI_ClearBySubsystem(oPlayer, HEALTHBAR_SCRIPT_NAME);
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "reset")) != CHATCOMMAND_PARSE_ERROR)
    {
        HealthBar_SendInfoChatMessage(oPlayer, "Reset");

        ES_Util_DeleteVarRegex(oPlayer, HEALTHBAR_SCRIPT_NAME + "_.*");
    }
    else
    {
        sHelp += "Available " + ES_Util_ColorString(HEALTHBAR_LOG_TAG, "070") + " Settings:\n";
        sHelp += "\n" + ES_Util_ColorString("x [value]", "070") + " - Set the X Position of the " + HEALTHBAR_LOG_TAG;
        sHelp += "\n" + ES_Util_ColorString("y [value]", "070") + " - Set the Y Position of the " + HEALTHBAR_LOG_TAG;
        sHelp += "\n" + ES_Util_ColorString("preview", "070") + " - Preview the " + HEALTHBAR_LOG_TAG;
        sHelp += "\n" + ES_Util_ColorString("clear", "070") + " - Remove the " + HEALTHBAR_LOG_TAG + " from your screen";
        sHelp += "\n" + ES_Util_ColorString("reset", "070") + " - Reset all " + HEALTHBAR_LOG_TAG + " Settings";

        SendMessageToPC(oPlayer, sHelp);
    }

    SetPCChatMessage("");
}

string HealthBar_GetHealthBarString(int nCurrentHitPoints, int nMaxHitPoints, int nWidth)
{
    float fHealthPerWidth = (nMaxHitPoints / IntToFloat(nWidth));
    int nNumHealthy = ceil(nCurrentHitPoints / fHealthPerWidth);
    string sHealthBar;

    int x;
    for (x = 0; x < nNumHealthy; x++)
    {
        sHealthBar += GUI_FONT_GUI_GLYPH_BLANK_WHITE;
    }

    return sHealthBar;
}

string HealthBar_GetHurtBarString(int nWidth)
{
    string sHurtBar;
    int x;
    for (x = 0; x < nWidth; x++)
    {
        sHurtBar += GUI_FONT_GUI_GLYPH_BLANK_WHITE;
    }

    return sHurtBar;
}

string HealthBar_GetHealthBarInfoString(int nCurrentHitPoints, int nMaxHitPoints)
{
    if (nCurrentHitPoints <= 0)
        return "Dead";
    else
    {
        int nPercentage = ceil(((IntToFloat(nCurrentHitPoints) / IntToFloat(nMaxHitPoints)) * 100.0f));
        return IntToString(nCurrentHitPoints) + "/" + IntToString(nMaxHitPoints) + " - " + IntToString(nPercentage) + "%";
    }
}

struct HealthBar_Data HealthBar_Update(object oCreature = OBJECT_SELF, string sInfo = "", int nWidth = HEALTHBAR_DEFAULT_WIDTH)
{
    int nCurrentHitPoints = GetCurrentHitPoints(oCreature);
    int nMaxHitPoints = GetMaxHitPoints(oCreature);
    struct HealthBar_Data hbd;

    hbd.sName = GetName(oCreature);
    hbd.sInfo = sInfo;
    hbd.sPortrait = GetPortraitResRef(oCreature);

    hbd.sHealthBar = HealthBar_GetHealthBarString(nCurrentHitPoints, nMaxHitPoints, nWidth);
    hbd.sHurtBar = HealthBar_GetHurtBarString(nWidth);
    hbd.sHealthBarInfo = HealthBar_GetHealthBarInfoString(nCurrentHitPoints, nMaxHitPoints);

    hbd.nID = GUI_GetStartID(HEALTHBAR_SCRIPT_NAME);
    hbd.nWidth = nWidth;

    return hbd;
}

struct HealthBar_Data HealthBar_AddCustomPlayerSettings(object oPlayer, struct HealthBar_Data hbd)
{
    hbd.nX = ES_Util_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_X");
    hbd.nY = ES_Util_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_Y");

    hbd.nNameColor = GUI_COLOR_ORANGE;
    hbd.nInfoColor = GUI_COLOR_SILVER;
    hbd.nHealthBarColor = GUI_COLOR_GREEN;
    hbd.nHurtBarColor = GUI_COLOR_MAROON;
    hbd.nHealthBarInfoColor = GUI_COLOR_WHITE;
    hbd.nPortraitDeadColor = GUI_COLOR_RED;

    return hbd;
}

void HealthBar_Draw(object oPlayer, struct HealthBar_Data hbd)
{
    hbd = HealthBar_AddCustomPlayerSettings(oPlayer, hbd);

    // Portrait
    int nPortraitColor = hbd.sHealthBarInfo == "Dead" ? hbd.nPortraitDeadColor : GUI_COLOR_WHITE;
    PostString(oPlayer, HEALTHBAR_PORTRAIT_GLYPH, hbd.nX + 1, hbd.nY + 1, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, nPortraitColor, nPortraitColor, hbd.nID++, HEALTHBAR_PORTRAIT_FONT_NAME);

    // Name
    PostString(oPlayer, hbd.sName, hbd.nX + 5, hbd.nY + 2, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, hbd.nNameColor, hbd.nNameColor, hbd.nID++, GUI_FONT_TEXT_NAME);
    // Info Text
    PostString(oPlayer, hbd.sInfo, hbd.nX + 5, hbd.nY + 3, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, hbd.nInfoColor, hbd.nInfoColor, hbd.nID++, GUI_FONT_TEXT_NAME);

    // HealthBar Info
    int nHealthBarInfoX = GUI_CenterStringInWindow(hbd.sHealthBarInfo, hbd.nX, hbd.nWidth);
    PostString(oPlayer, hbd.sHealthBarInfo, nHealthBarInfoX, hbd.nY + 5, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, hbd.nHealthBarInfoColor, hbd.nHealthBarInfoColor, hbd.nID++, GUI_FONT_TEXT_NAME);

    // HealthBar
    PostString(oPlayer, hbd.sHealthBar, hbd.nX + 1, hbd.nY + 5, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, hbd.nHealthBarColor, hbd.nHealthBarColor, hbd.nID++, GUI_FONT_GUI_NAME);
    PostString(oPlayer, hbd.sHurtBar, hbd.nX + 1, hbd.nY + 5, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, hbd.nHurtBarColor, hbd.nHurtBarColor, hbd.nID++, GUI_FONT_GUI_NAME);

    // Window
    GUI_DrawWindow(oPlayer, hbd.nID, SCREEN_ANCHOR_TOP_LEFT, hbd.nX, hbd.nY, hbd.nWidth + 1, 5);

    SetTextureOverride(HEALTHBAR_PORTRAIT_FONT_NAME, hbd.sPortrait + "s", oPlayer);
}

