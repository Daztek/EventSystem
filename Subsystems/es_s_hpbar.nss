/*
    ScriptName: es_s_hpbar.nss
    Created by: Daz

    Description: A HealthBar Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_gui"

const string HEALTHBAR_LOG_TAG                  = "HealthBar";
const string HEALTHBAR_SCRIPT_NAME              = "es_s_hpbar";

const int HEALTHBAR_GUI_NUM_IDS                 = 15;
const string HEALTHBAR_PORTRAIT_FONT_NAME       = "fnt_es_hbport";

const int HEALTHBAR_NAME_COLOR                  = 0xF99414FF;

struct HealthBar_Data
{
    string sName;
    string sInfo;
    string sPortrait;

    string sHealthBar;
    string sHealthBarInfo;

    int nID;
    int nX;
    int nY;
    int nWidth;

    float fLifeTime;
};

string HealthBar_GetHealthBarString(int nCurrentHitPoints, int nMaxHitPoints, int nWidth);
string HealthBar_GetHealthBarInfoString(int nCurrentHitPoints, int nMaxHitPoints);
void HealthBar_Draw(object oPlayer, struct HealthBar_Data hbd);

// @Load
void HealthBar_Load(string sSubsystemScript)
{
    GUI_ReserveIDs(sSubsystemScript, HEALTHBAR_GUI_NUM_IDS);

    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DAMAGED, ES_CORE_EVENT_FLAG_AFTER, TRUE);

    // TESTING
    object oDeer = GetObjectByTag("TestDeer");
    ES_Core_SetObjectEventScript(oDeer, EVENT_SCRIPT_CREATURE_ON_DAMAGED, FALSE);
    NWNX_Events_AddObjectToDispatchList(ES_Core_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DAMAGED, ES_CORE_EVENT_FLAG_AFTER), sSubsystemScript, oDeer);
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
            int nCurrentHitPoints = GetCurrentHitPoints(oCreature);
            int nMaxHitPoints = GetMaxHitPoints(oCreature);
            int nWidth = GetLocalInt(oCreature, "HealthBar_Width");

            struct HealthBar_Data hbd;

            hbd.sName = GetName(oCreature);
            hbd.sInfo = GetLocalString(oCreature, "HealthBar_Info");
            hbd.sPortrait = GetStringLowerCase(GetPortraitResRef(oCreature));

            hbd.sHealthBar = HealthBar_GetHealthBarString(nCurrentHitPoints, nMaxHitPoints, nWidth);
            hbd.sHealthBarInfo = HealthBar_GetHealthBarInfoString(nCurrentHitPoints, nMaxHitPoints);

            hbd.nID = GUI_GetStartID(sSubsystemScript);
            hbd.nX = 50;
            hbd.nY = 0;
            hbd.nWidth = nWidth;

            if (GetIsPC(oDamager))
                HealthBar_Draw(oDamager, hbd);

            break;
        }
    }
}

string HealthBar_GetHealthBarString(int nCurrentHitPoints, int nMaxHitPoints, int nWidth)
{
    float fHealthPerWidth = (nMaxHitPoints / IntToFloat(nWidth));
    int nNumHealthy = ceil(nCurrentHitPoints / fHealthPerWidth);
    string sHealthBar;

    int x;
    for (x = 0; x < nWidth; x++)
    {
        if (x < nNumHealthy)
            sHealthBar += GUI_FONT_GUI_GLYPH_HEALTHBAR_GREEN;
        else
            sHealthBar += GUI_FONT_GUI_GLYPH_HEALTHBAR_RED;
    }

    return sHealthBar;
}

string HealthBar_GetHealthBarInfoString(int nCurrentHitPoints, int nMaxHitPoints)
{
    int nPercentage = ceil(((IntToFloat(nCurrentHitPoints) / IntToFloat(nMaxHitPoints)) * 100.0f));
    return IntToString(nCurrentHitPoints) + "/" + IntToString(nMaxHitPoints) + " - " + IntToString(nPercentage) + "%";
}

void HealthBar_Draw(object oPlayer, struct HealthBar_Data hbd)
{
    // Portrait
    PostString(oPlayer, "a", hbd.nX + 1, hbd.nY + 1, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, hbd.nID++, HEALTHBAR_PORTRAIT_FONT_NAME);

    // Name
    PostString(oPlayer, hbd.sName, hbd.nX + 5, hbd.nY + 2, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, HEALTHBAR_NAME_COLOR, HEALTHBAR_NAME_COLOR, hbd.nID++, GUI_FONT_TEXT_NAME);
    // Info Text
    PostString(oPlayer, hbd.sInfo, hbd.nX + 5, hbd.nY + 3, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, hbd.nID++, GUI_FONT_TEXT_NAME);

    // HealthBar Info
    int nHealthBarInfoX = GUI_CenterStringInWindow(hbd.sHealthBarInfo, hbd.nX, hbd.nWidth);
    PostString(oPlayer, hbd.sHealthBarInfo, nHealthBarInfoX, hbd.nY + 5, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, hbd.nID++, GUI_FONT_TEXT_NAME);

    // HealthBar
    PostString(oPlayer, hbd.sHealthBar, hbd.nX + 1, hbd.nY + 5, SCREEN_ANCHOR_TOP_LEFT, hbd.fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, hbd.nID++, GUI_FONT_GUI_NAME);

    // Window
    GUI_DrawWindow(oPlayer, hbd.nID, SCREEN_ANCHOR_TOP_LEFT, hbd.nX, hbd.nY, hbd.nWidth + 1, 5);

    SetTextureOverride(HEALTHBAR_PORTRAIT_FONT_NAME, hbd.sPortrait + "s", oPlayer);
}

