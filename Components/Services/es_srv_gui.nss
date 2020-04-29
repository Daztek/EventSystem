/*
    ScriptName: es_srv_gui.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Object]

    Description: An EventSystem Service that provides various GUI functionality
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_object"

const string GUI_LOG_TAG                                = "GUI";
const string GUI_SCRIPT_NAME                            = "es_srv_gui";

const int GUI_ID_START                                  = 1000;

const string GUI_FONT_TEXT_NAME                         = "fnt_es_text";

const string GUI_FONT_GUI_NAME                          = "fnt_es_gui";
const string GUI_FONT_GUI_GLYPH_WINDOW_TOP_LEFT         = "a";
const string GUI_FONT_GUI_GLYPH_WINDOW_TOP_RIGHT        = "c";
const string GUI_FONT_GUI_GLYPH_WINDOW_TOP_MIDDLE       = "b";
const string GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_LEFT      = "d";
const string GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_RIGHT     = "f";
const string GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK     = "i";
const string GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_LEFT      = "h";
const string GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_RIGHT     = "g";
const string GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_MIDDLE    = "e";
const string GUI_FONT_GUI_GLYPH_ARROW                   = "j";
const string GUI_FONT_GUI_GLYPH_BLANK_WHITE             = "k";

const int GUI_COLOR_TRANSPARENT                         = 0xFFFFFF00;
const int GUI_COLOR_WHITE                               = 0xFFFFFFFF;
const int GUI_COLOR_SILVER                              = 0xC0C0C0FF;
const int GUI_COLOR_GRAY                                = 0x808080FF;
const int GUI_COLOR_DARK_GRAY                           = 0x303030FF;
const int GUI_COLOR_BLACK                               = 0x000000FF;
const int GUI_COLOR_RED                                 = 0xFF0000FF;
const int GUI_COLOR_MAROON                              = 0x800000FF;
const int GUI_COLOR_ORANGE                              = 0xFFA500FF;
const int GUI_COLOR_YELLOW                              = 0xFFFF00FF;
const int GUI_COLOR_OLIVE                               = 0x808000FF;
const int GUI_COLOR_LIME                                = 0x00FF00FF;
const int GUI_COLOR_GREEN                               = 0x008000FF;
const int GUI_COLOR_AQUA                                = 0x00FFFFFF;
const int GUI_COLOR_TEAL                                = 0x008080FF;
const int GUI_COLOR_BLUE                                = 0x0000FFFF;
const int GUI_COLOR_NAVY                                = 0x000080FF;
const int GUI_COLOR_FUSCHIA                             = 0xFF00FFFF;
const int GUI_COLOR_PURPLE                              = 0x800080FF;

// Reserve nAmount of PostString() IDs for sSubsystemScript
void GUI_ReserveIDs(string sSubsystemScript, int nAmount);
// Return the starting PostString() ID for sSubsystemScript
int GUI_GetStartID(string sSubsystemScript);
// Return the ending PostString() ID for sSubsystemScript
int GUI_GetEndID(string sSubsystemScript);
// Return the amount of PostString() IDs that sSubsystemScript has requested
int GUI_GetIDAmount(string sSubsystemScript);

// Clear a PostString() string with nID for oPlayer
void GUI_ClearByID(object oPlayer, int nID);
// Clear a PostString() string ID range for oPlayer
void GUI_ClearByRange(object oPlayer, int nStartID, int nEndID);
// Clear all PostString() strings of sSubsystemScript for oPlayer
void GUI_ClearBySubsystem(object oPlayer, string sSubsystemScript);

int GUI_GetIsPlayerInputLocked(object oPlayer);
void GUI_LockPlayerInput(object oPlayer);
void GUI_UnlockPlayerInput(object oPlayer);

// Badly center a string in a window
int GUI_CenterStringInWindow(string sString, int nWindowX, int nWindowWidth);

// Wrapper around PostString() that draws GUI parts using GUI_FONT_GUI_NAME with color GUI_COLOR_WHITE
void GUI_Draw(object oPlayer, string sMessage, int nX, int nY, int nAnchor, int nID, float fLifeTime = 0.0f);
// Draw a window with borders on all sides
// Returns the amount of IDs used, minimum of 2
int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 0.0f, int bIncrementID = TRUE);
// Draw a window that covers the conversation window and only has right and bottom borders
// Returns the amount of IDs used, minimum of 2
int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 0.0f, int bIncrementID = TRUE);
// Draws a text notification at the the top left anchor
// Returns the amount of IDs used, minimum of 4
int GUI_DrawNotification(object oPlayer, string sMessage, int nX, int nY, int nID, int nTextColor = GUI_COLOR_WHITE, float fLifeTime = 0.0f);
// Draw sText over multiple lines of nMaxLength
int GUI_DrawSplitText(object oPlayer, string sText, int nMaxLength, int nX, int nY, int nID, int nTextColor = GUI_COLOR_WHITE, float fLifeTime = 0.0f, string sFont = GUI_FONT_TEXT_NAME);

// @Load
void GUI_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    SetLocalInt(oDataObject, "TotalIDs", GUI_ID_START);
}

void GUI_ReserveIDs(string sSubsystemScript, int nAmount)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    if (!GetLocalInt(oDataObject, sSubsystemScript + "_Amount"))
    {
        int nTotal = GetLocalInt(oDataObject, "TotalIDs");
        int nStart = nTotal;
        int nEnd = nTotal + nAmount - 1;

        SetLocalInt(oDataObject, "TotalIDs", nTotal + nAmount);
        SetLocalInt(oDataObject, sSubsystemScript + "_Amount", nAmount);
        SetLocalInt(oDataObject, sSubsystemScript + "_StartID", nStart);
        SetLocalInt(oDataObject, sSubsystemScript + "_EndID", nEnd);

        ES_Util_Log(GUI_LOG_TAG, "Subsystem '" + sSubsystemScript + "' requested '" + IntToString(nAmount) + "' IDs -> " + IntToString(nStart) + " - " + IntToString(nEnd));
    }
}

int GUI_GetStartID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return GetLocalInt(oDataObject, sSubsystemScript + "_StartID");
}

int GUI_GetEndID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return GetLocalInt(oDataObject, sSubsystemScript + "_EndID");
}

int GUI_GetIDAmount(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return GetLocalInt(oDataObject, sSubsystemScript + "_Amount");
}

void GUI_ClearByID(object oPlayer, int nID)
{
    PostString(oPlayer, "", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.1f, GUI_COLOR_TRANSPARENT, GUI_COLOR_TRANSPARENT, nID);
}

void GUI_ClearByRange(object oPlayer, int nStartID, int nEndID)
{
    int i;
    for(i = nStartID; i < nEndID; i++)
    {
        GUI_ClearByID(oPlayer, i);
    }
}

void GUI_ClearBySubsystem(object oPlayer, string sSubsystemScript)
{
    int nStartID = GUI_GetStartID(sSubsystemScript);
    int nEndID = nStartID + GUI_GetIDAmount(sSubsystemScript);

    GUI_ClearByRange(oPlayer, nStartID, nEndID);
}

int GUI_GetIsPlayerInputLocked(object oPlayer)
{
    return GetIsObjectValid(GetLocalObject(oPlayer, GUI_SCRIPT_NAME + "_InputLock"));
}

void GUI_LockPlayerInput(object oPlayer)
{
    GUI_UnlockPlayerInput(oPlayer);

    location locPlayer = GetLocation(oPlayer);
    object oLock = CreateObject(OBJECT_TYPE_PLACEABLE, "plc_boulder", locPlayer, FALSE, GUI_SCRIPT_NAME + "_InputLock");

    SetPlotFlag(oLock, TRUE);
    NWNX_Object_SetPosition(oPlayer, GetPositionFromLocation(locPlayer));
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, ExtraordinaryEffect(EffectVisualEffect(VFX_DUR_CUTSCENE_INVISIBILITY)), oLock);

    SetLocalObject(oPlayer, GUI_SCRIPT_NAME + "_InputLock", oLock);
}

void GUI_UnlockPlayerInput(object oPlayer)
{
    object oLock = GetLocalObject(oPlayer, GUI_SCRIPT_NAME + "_InputLock");

    if (GetIsObjectValid(oLock))
    {
        DestroyObject(oLock);
        DeleteLocalObject(oPlayer, GUI_SCRIPT_NAME + "_InputLock");
    }
}

void GUI_Draw(object oPlayer, string sMessage, int nX, int nY, int nAnchor, int nID, float fLifeTime = 0.0f)
{
    PostString(oPlayer, sMessage, nX, nY, nAnchor, fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID, GUI_FONT_GUI_NAME);
}

int GUI_CenterStringInWindow(string sString, int nWindowX, int nWindowWidth)
{
    return (nWindowX + (nWindowWidth / 2)) - ((GetStringLength(sString) + 2) / 2);
}

int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 0.0f, int bIncrementID = TRUE)
{
    string sTop = GUI_FONT_GUI_GLYPH_WINDOW_TOP_LEFT;
    string sMiddle = GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_LEFT;
    string sBottom = GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_LEFT;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop += GUI_FONT_GUI_GLYPH_WINDOW_TOP_MIDDLE;
        sMiddle += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_MIDDLE;
    }

    sTop += GUI_FONT_GUI_GLYPH_WINDOW_TOP_RIGHT;
    sMiddle += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_RIGHT;

    GUI_Draw(oPlayer, sTop, nX, nY, nAnchor, bIncrementID ? nStartID++ : nStartID--, fLifetime);
    for (i = 0; i < nHeight; i++)
    {
        GUI_Draw(oPlayer, sMiddle, nX, ++nY, nAnchor, bIncrementID ? nStartID++ : nStartID--, fLifetime);
    }
    GUI_Draw(oPlayer, sBottom, nX, ++nY, nAnchor, nStartID, fLifetime);

    return nHeight + 2;
}

int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 0.0f, int bIncrementID = TRUE)
{
    int nX = 0, nY = 0;
    int nAnchor = SCREEN_ANCHOR_TOP_LEFT;

    string sTop = GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK;
    string sMiddle = GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK;
    string sBottom = GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_MIDDLE;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK;
        sMiddle += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_MIDDLE;
    }

    sTop += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_RIGHT;
    sMiddle += GUI_FONT_GUI_GLYPH_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_GUI_GLYPH_WINDOW_BOTTOM_RIGHT;

    GUI_Draw(oPlayer, sTop, nX, nY, nAnchor, bIncrementID ? nStartID++ : nStartID--, fLifetime);
    for (i = 0; i < nHeight; i++)
    {
        GUI_Draw(oPlayer, sMiddle, nX, ++nY, nAnchor, bIncrementID ? nStartID++ : nStartID--, fLifetime);
    }
    GUI_Draw(oPlayer, sBottom, nX, ++nY, nAnchor, nStartID, fLifetime);

    return nHeight + 2;
}

int GUI_DrawNotification(object oPlayer, string sMessage, int nX, int nY, int nID, int nTextColor = GUI_COLOR_WHITE, float fLifeTime = 0.0f)
{
    int nMessageLength = GetStringLength(sMessage) + 1;

    PostString(oPlayer, sMessage, nX + 1, nY + 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, GUI_FONT_TEXT_NAME);

    nID += GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, nX, nY, nMessageLength, 1, fLifeTime);

    return nID;
}

int GUI_DrawSplitText(object oPlayer, string sText, int nMaxLength, int nX, int nY, int nID, int nTextColor = GUI_COLOR_WHITE, float fLifeTime = 0.0f, string sFont = GUI_FONT_TEXT_NAME)
{
    if (sText == "")
        return 0;

    if (GetStringLength(sText) <= nMaxLength)
    {
        PostString(oPlayer, sText, nX, nY, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID, sFont);
        return 1;
    }

    if (GetStringRight(sText, 1) != " ")
        sText += " ";

    string sLine;
    int nNumLines, nStart = 0, nEnd = FindSubString(sText, " ", nStart);

    while (nEnd != -1)
    {
        string sWord = GetSubString(sText, nStart, nEnd - nStart + 1);

        if (GetStringLength(sLine) + GetStringLength(sWord) > nMaxLength)
        {
            nNumLines++;
            PostString(oPlayer, sLine, nX, nY++, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sFont);
            sLine = sWord;
        }
        else
            sLine += sWord;

        nStart = nEnd + 1;
        nEnd = FindSubString(sText, " ", nStart);
    }

    if (GetStringLength(sLine))
    {
        nNumLines++;
        PostString(oPlayer, sLine, nX, nY, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sFont);
    }

    return nNumLines;
}

