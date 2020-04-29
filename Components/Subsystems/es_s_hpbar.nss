/*
    ScriptName: es_s_hpbar.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: A HealthBar Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_pos"
#include "es_srv_gui"
#include "es_srv_chatcom"
#include "es_srv_mediator"

const string HEALTHBAR_LOG_TAG                  = "HealthBar";
const string HEALTHBAR_SCRIPT_NAME              = "es_s_hpbar";

const string HEALTHBAR_CHATCOMMAND_NAME         = "hb";
const string HEALTHBAR_CHATCOMMAND_DESCRIPTION  = "Customize HealthBar Settings.";

const int HEALTHBAR_GUI_NUM_IDS                 = 15;
const string HEALTHBAR_PORTRAIT_FONT_NAME       = "fnt_es_hbport";
const string HEALTHBAR_PORTRAIT_GLYPH           = "a";

const float HEALTHBAR_TIMEOUT_DELAY             = 2.5f;
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

// Enable a HealthBar for oCreature
void HealthBar_EnableHealthBar(object oCreature);
// Set oCreature's HealthBar infoblurb
void HealthBar_SetInfoBlurb(object oCreature, string sInfoBlurb);

// @Load
void HealthBar_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DAMAGED, EVENTS_EVENT_FLAG_AFTER, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DEATH, EVENTS_EVENT_FLAG_AFTER, TRUE);

    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_ATTACK_OBJECT_AFTER", TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_CAST_SPELL_AFTER", TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_AFTER", TRUE);

    GUI_ReserveIDs(sSubsystemScript, HEALTHBAR_GUI_NUM_IDS);
    Mediator_RegisterFunction(sSubsystemScript, "HealthBar_EnableHealthBar", "o");
    Mediator_RegisterFunction(sSubsystemScript, "HealthBar_SetInfoBlurb", "os");
    ChatCommand_Register(sSubsystemScript, "HealthBar_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + HEALTHBAR_CHATCOMMAND_NAME, "", HEALTHBAR_CHATCOMMAND_DESCRIPTION);
}

void HealthBar_EnableHealthBar(object oCreature)
{
    if (GetObjectType(oCreature) != OBJECT_TYPE_CREATURE || GetIsPC(oCreature))
        return;

    SetLocalInt(oCreature, "HealthBar_Enabled", TRUE);

    string sDamagedEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DAMAGED, EVENTS_EVENT_FLAG_AFTER);
    string sDeathEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DEATH, EVENTS_EVENT_FLAG_AFTER);

    Events_SetObjectEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DAMAGED);
    Events_SetObjectEventScript(oCreature, EVENT_SCRIPT_CREATURE_ON_DEATH);

    Events_AddObjectToDispatchList(HEALTHBAR_SCRIPT_NAME, sDamagedEvent, oCreature);
    Events_AddObjectToDispatchList(HEALTHBAR_SCRIPT_NAME, sDeathEvent, oCreature);
}

void HealthBar_SetInfoBlurb(object oCreature, string sInfoBlurb)
{
    SetLocalString(oCreature, "HealthBar_Info", sInfoBlurb);
}

int HealthBar_GetWidth(object oCreature)
{
    int nOverrideWidth = GetLocalInt(oCreature, "HealthBar_Width");

    return nOverrideWidth ? nOverrideWidth : HEALTHBAR_DEFAULT_WIDTH;
}

void HealthBar_RemovePlayerFromHealthBarList(string sPlayerUUID, string sCreatureUUID)
{
    object oCreature = GetObjectByUUID(sCreatureUUID);

    if (GetIsObjectValid(oCreature))
        StringArray_DeleteByValue(oCreature, "HealthBarTargets", sPlayerUUID);

    DeleteLocalString(GetObjectByUUID(sPlayerUUID), HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");
}

void HealthBar_AddPlayerToHealthBarList(object oPlayer, object oCreature)
{
    string sCreatureUUID = GetObjectUUID(oCreature);
    string sCurrentHealthBarTarget = GetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");

    if (sCreatureUUID == sCurrentHealthBarTarget)
        return;
    else
    {
        string sPlayerUUID = GetObjectUUID(oPlayer);

        if (sCurrentHealthBarTarget != "")
            HealthBar_RemovePlayerFromHealthBarList(sPlayerUUID, sCurrentHealthBarTarget);

        StringArray_Insert(oCreature, "HealthBarTargets", sPlayerUUID);

        SetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar", sCreatureUUID);
    }
}

string HealthBar_GetHealthBarString(int nCurrentHitPoints, int nMaxHitPoints, int nWidth)
{
    if (nCurrentHitPoints <= 0)
        return "";
    else
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
    hbd.nX = POS_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_x");
    hbd.nY = POS_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_y");

    hbd.nNameColor = GUI_COLOR_ORANGE;
    hbd.nInfoColor = GUI_COLOR_SILVER;
    hbd.nHealthBarColor = GUI_COLOR_GREEN;
    hbd.nHurtBarColor = GUI_COLOR_MAROON;
    hbd.nHealthBarInfoColor = GUI_COLOR_WHITE;
    hbd.nPortraitDeadColor = GUI_COLOR_DARK_GRAY;

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
    GUI_DrawWindow(oPlayer, hbd.nID, SCREEN_ANCHOR_TOP_LEFT, hbd.nX, hbd.nY, hbd.nWidth + 1, 5, hbd.fLifeTime);

    SetTextureOverride(HEALTHBAR_PORTRAIT_FONT_NAME, hbd.sPortrait + "s", oPlayer);
}

// @EventHandler
void HealthBar_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_INPUT_ATTACK_OBJECT_AFTER" ||
        sEvent == "NWNX_ON_INPUT_CAST_SPELL_AFTER")
    {
        object oPlayer = OBJECT_SELF;
        object oCreature = Events_GetEventData_NWNX_Object("TARGET");

        if (!GetIsObjectValid(oCreature) ||
             GetObjectType(oCreature) != OBJECT_TYPE_CREATURE ||
            !GetIsEnemy(oCreature, oPlayer) ||
             GetIsPC(oCreature))
            return;

        int nHealthBarEnabled = GetLocalInt(oCreature, "HealthBar_Enabled");

        if (!nHealthBarEnabled)
        {
            HealthBar_EnableHealthBar(oCreature);
            nHealthBarEnabled = TRUE;
        }

        if (nHealthBarEnabled)
        {
            string sCurrentHealthBarTarget = GetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");
            string sCreatureUUID = GetObjectUUID(oCreature);

            if (sCurrentHealthBarTarget != sCreatureUUID)
            {
                Events_AddObjectToDispatchList(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_AFTER", oPlayer);

                HealthBar_AddPlayerToHealthBarList(oPlayer, oCreature);

                string sInfo = GetLocalString(oCreature, "HealthBar_Info");
                int nWidth = HealthBar_GetWidth(oCreature);

                HealthBar_Draw(oPlayer, HealthBar_Update(oCreature, sInfo, nWidth));
            }
        }
    }
    if (sEvent == "NWNX_ON_INPUT_WALK_TO_WAYPOINT_AFTER")
    {
        object oPlayer = OBJECT_SELF;
        string sCurrentHealthBarTarget = GetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");

        Events_RemoveObjectFromDispatchList(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_AFTER", oPlayer);

        if (sCurrentHealthBarTarget != "")
        {
            HealthBar_RemovePlayerFromHealthBarList(GetObjectUUID(oPlayer), sCurrentHealthBarTarget);

            object oCreature = GetObjectByUUID(sCurrentHealthBarTarget);

            if (GetIsObjectValid(oCreature))
            {
                string sInfo = GetLocalString(oCreature, "HealthBar_Info");
                int nWidth = HealthBar_GetWidth(oCreature);

                struct HealthBar_Data hbd = HealthBar_Update(oCreature, sInfo, nWidth);
                hbd.fLifeTime = HEALTHBAR_TIMEOUT_DELAY;

                HealthBar_Draw(oPlayer, hbd);
            }
        }
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
            {
                object oPlayer = GetEnteringObject();

                Events_AddObjectToDispatchList(sSubsystemScript, "NWNX_ON_INPUT_ATTACK_OBJECT_AFTER", oPlayer);
                Events_AddObjectToDispatchList(sSubsystemScript, "NWNX_ON_INPUT_CAST_SPELL_AFTER", oPlayer);

                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                object oPlayer = GetExitingObject();
                string sCurrentHealthBarTarget = GetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");

                Events_RemoveObjectFromDispatchList(sSubsystemScript, "NWNX_ON_INPUT_ATTACK_OBJECT_AFTER", oPlayer);
                Events_RemoveObjectFromDispatchList(sSubsystemScript, "NWNX_ON_INPUT_CAST_SPELL_AFTER",  oPlayer);
                Events_RemoveObjectFromDispatchList(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_AFTER", oPlayer);

                if (sCurrentHealthBarTarget != "")
                {
                    HealthBar_RemovePlayerFromHealthBarList(GetObjectUUID(oPlayer), sCurrentHealthBarTarget);
                }

                break;
            }

            case EVENT_SCRIPT_CREATURE_ON_DAMAGED:
            {
                object oCreature = OBJECT_SELF;
                object oLastDamager = GetLastDamager(oCreature);

                if (GetIsPC(oLastDamager))
                {
                    HealthBar_AddPlayerToHealthBarList(oLastDamager, oCreature);
                }

                int nNumTargets = StringArray_Size(oCreature, "HealthBarTargets");

                if (nNumTargets)
                {
                    string sInfo = GetLocalString(oCreature, "HealthBar_Info");
                    int nWidth = HealthBar_GetWidth(oCreature);

                    struct HealthBar_Data hbd = HealthBar_Update(oCreature, sInfo, nWidth);

                    int x;
                    for (x = 0; x < nNumTargets; x++)
                    {
                        object oPlayer = GetObjectByUUID(StringArray_At(oCreature, "HealthBarTargets", x));

                        if (GetIsObjectValid(oPlayer))
                        {
                            HealthBar_Draw(oPlayer, hbd);
                        }
                    }
                }

                break;
            }

            case EVENT_SCRIPT_CREATURE_ON_DEATH:
            {
                object oCreature = OBJECT_SELF;
                string sDamagedEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DAMAGED, EVENTS_EVENT_FLAG_AFTER);
                string sDeathEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DEATH, EVENTS_EVENT_FLAG_AFTER);

                Events_RemoveObjectFromDispatchList(sSubsystemScript, sDamagedEvent, oCreature);
                Events_RemoveObjectFromDispatchList(sSubsystemScript, sDeathEvent, oCreature);

                int nNumTargets = StringArray_Size(oCreature, "HealthBarTargets");

                if (nNumTargets)
                {
                    string sInfo = GetLocalString(oCreature, "HealthBar_Info");
                    int nWidth = HealthBar_GetWidth(oCreature);

                    struct HealthBar_Data hbd = HealthBar_Update(oCreature, sInfo, nWidth);
                    hbd.fLifeTime = HEALTHBAR_TIMEOUT_DELAY;

                    int x;
                    for (x = 0; x < nNumTargets; x++)
                    {
                        object oPlayer = GetObjectByUUID(StringArray_At(oCreature, "HealthBarTargets", x));

                        if (GetIsObjectValid(oPlayer))
                        {
                            HealthBar_Draw(oPlayer, hbd);
                            DeleteLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");
                        }
                    }
                }

                break;
            }
        }
    }
}

void HealthBar_SetHealthBarOption(object oPlayer, string sOption, string sValue)
{
    if (sValue == "")
    {
        int nValue = POS_GetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_" + sOption);

        ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Current " + sOption + " value: " + IntToString(nValue));
    }
    else
    {
        int nValue = StringToInt(sValue);

        if (nValue >= 0)
        {
            ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Setting " + sOption + " to: " + IntToString(nValue));

            POS_SetInt(oPlayer, HEALTHBAR_SCRIPT_NAME + "_" + sOption, nValue, TRUE);
        }
        else
            ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Value for " + sOption + " must be >= 0");
    }
}

void HealthBar_ChatCommand(object oPlayer, string sOption, int nVolume)
{
    string sParams, sHelp;

    if ((sParams = ChatCommand_Parse(sOption, "x")) != CHATCOMMAND_PARSE_ERROR)
        HealthBar_SetHealthBarOption(oPlayer, "x", sParams);
    else
    if ((sParams = ChatCommand_Parse(sOption, "y")) != CHATCOMMAND_PARSE_ERROR)
        HealthBar_SetHealthBarOption(oPlayer, "y", sParams);
    else
    if ((sParams = ChatCommand_Parse(sOption, "preview")) != CHATCOMMAND_PARSE_ERROR)
    {
        ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Preview");

        HealthBar_Draw(oPlayer, HealthBar_Update(oPlayer, "It's you, oh no!"));
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "clear")) != CHATCOMMAND_PARSE_ERROR)
    {
        ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Cleared");

        GUI_ClearBySubsystem(oPlayer, HEALTHBAR_SCRIPT_NAME);

        string sCurrentHealthBarTarget = GetLocalString(oPlayer, HEALTHBAR_SCRIPT_NAME + "_CurrentHealthBar");

        if (sCurrentHealthBarTarget != "")
            HealthBar_RemovePlayerFromHealthBarList(GetObjectUUID(oPlayer), sCurrentHealthBarTarget);
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "reset")) != CHATCOMMAND_PARSE_ERROR)
    {
        ChatCommand_SendInfoMessage(oPlayer, HEALTHBAR_LOG_TAG, "Reset");

        POS_DeleteVarRegex(oPlayer, HEALTHBAR_SCRIPT_NAME + "_.*");
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

