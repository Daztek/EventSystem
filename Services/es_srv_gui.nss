/*
    ScriptName: es_srv_gui.nss
    Created by: Daz

    Description: An EventSystem Service that provides various GUI functionality
*/

//void main() {}

#include "es_inc_core"

const string GUI_LOG_TAG                            = "GUI";
const string GUI_SCRIPT_NAME                        = "es_srv_gui";

const int GUI_ID_START                              = 1000;

const string GUI_FONT_NAME                          = "fnt_esgui";
const string GUI_FONT_GLYPH_WINDOW_TOP_LEFT         = "a";
const string GUI_FONT_GLYPH_WINDOW_TOP_RIGHT        = "c";
const string GUI_FONT_GLYPH_WINDOW_TOP_MIDDLE       = "b";
const string GUI_FONT_GLYPH_WINDOW_MIDDLE_LEFT      = "d";
const string GUI_FONT_GLYPH_WINDOW_MIDDLE_RIGHT     = "f";
const string GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK     = "i";
const string GUI_FONT_GLYPH_WINDOW_BOTTOM_LEFT      = "h";
const string GUI_FONT_GLYPH_WINDOW_BOTTOM_RIGHT     = "g";
const string GUI_FONT_GLYPH_WINDOW_BOTTOM_MIDDLE    = "e";
const string GUI_FONT_GLYPH_ARROW                   = "j";

const int GUI_COLOR_TRANSPARENT                     = 0xFFFFFF00;
const int GUI_COLOR_BLACK                           = 0x000000FF;
const int GUI_COLOR_WHITE                           = 0xFFFFFFFF;
const int GUI_COLOR_RED                             = 0xFF0000FF;
const int GUI_COLOR_GREEN                           = 0x00FF00FF;
const int GUI_COLOR_BLUE                            = 0x0000FFFF;

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

// Badly calculate the actual length of a string for use with GUI_Draw{Conversation}Window Functions
// Only really works with fnt_console
int GUI_CalculateStringLength(string sMessage, string sFont = "fnt_console");

// Wrapper around PostString() that draws GUI parts using GUI_FONT_NAME with color GUI_COLOR_WHITE
void GUI_Draw(object oPlayer, string sMessage, int nX, int nY, int nAnchor, int nID, float fLifeTime = 0.0f);
// Draw a window with borders on all sides
// Returns the amount of IDs used, minimum of 2
int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 0.0f);
// Draw a window that covers the conversation window and only has right and bottom borders
// Returns the amount of IDs used, minimum of 2
int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 0.0f);

// @Load
void GUI_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    ES_Util_SetInt(oDataObject, "TotalIDs", GUI_ID_START);
}

void GUI_ReserveIDs(string sSubsystemScript, int nAmount)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    if (!ES_Util_GetInt(oDataObject, sSubsystemScript + "_Amount"))
    {
        int nTotal = ES_Util_GetInt(oDataObject, "TotalIDs");
        int nStart = nTotal;
        int nEnd = nTotal + nAmount - 1;

        ES_Util_SetInt(oDataObject, "TotalIDs", nTotal + nAmount);
        ES_Util_SetInt(oDataObject, sSubsystemScript + "_Amount", nAmount);
        ES_Util_SetInt(oDataObject, sSubsystemScript + "_StartID", nStart);
        ES_Util_SetInt(oDataObject, sSubsystemScript + "_EndID", nEnd);

        ES_Util_Log(GUI_LOG_TAG, "Subsystem '" + sSubsystemScript + "' requested '" + IntToString(nAmount) + "' IDs -> " + IntToString(nStart) + " - " + IntToString(nEnd));
    }
}

int GUI_GetStartID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_StartID");
}

int GUI_GetEndID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_EndID");
}

int GUI_GetIDAmount(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_Amount");
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

int GUI_CalculateStringLength(string sMessage, string sFont = "fnt_console")
{
    if (sFont == "fnt_console")
    {
        int nLength = GetStringLength(sMessage);
        int nPadding = ceil(((nLength / 4.5f) * 1.2f));

        return nLength + nPadding;
    }
    else
        return GetStringLength(sMessage);
}

void GUI_Draw(object oPlayer, string sMessage, int nX, int nY, int nAnchor, int nID, float fLifeTime = 0.0f)
{
    PostString(oPlayer, sMessage, nX, nY, nAnchor, fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID, GUI_FONT_NAME);
}

int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 0.0f)
{
    string sTop = GUI_FONT_GLYPH_WINDOW_TOP_LEFT;
    string sMiddle = GUI_FONT_GLYPH_WINDOW_MIDDLE_LEFT;
    string sBottom = GUI_FONT_GLYPH_WINDOW_BOTTOM_LEFT;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop += GUI_FONT_GLYPH_WINDOW_TOP_MIDDLE;
        sMiddle += GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_GLYPH_WINDOW_BOTTOM_MIDDLE;
    }

    sTop += GUI_FONT_GLYPH_WINDOW_TOP_RIGHT;
    sMiddle += GUI_FONT_GLYPH_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_GLYPH_WINDOW_BOTTOM_RIGHT;

    GUI_Draw(oPlayer, sTop, nX, nY, nAnchor, nStartID++, fLifetime);
    for (i = 0; i < nHeight; i++)
    {
        GUI_Draw(oPlayer, sMiddle, nX, ++nY, nAnchor, nStartID++, fLifetime);
    }
    GUI_Draw(oPlayer, sBottom, nX, ++nY, nAnchor, nStartID, fLifetime);

    return nHeight + 2;
}

int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 0.0f)
{
    int nX = 0, nY = 0;
    int nAnchor = SCREEN_ANCHOR_TOP_LEFT;

    string sTop = GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK;
    string sMiddle = GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK;
    string sBottom = GUI_FONT_GLYPH_WINDOW_BOTTOM_MIDDLE;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop += GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK;
        sMiddle += GUI_FONT_GLYPH_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_GLYPH_WINDOW_BOTTOM_MIDDLE;
    }

    sTop += GUI_FONT_GLYPH_WINDOW_MIDDLE_RIGHT;
    sMiddle += GUI_FONT_GLYPH_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_GLYPH_WINDOW_BOTTOM_RIGHT;

    GUI_Draw(oPlayer, sTop, nX, nY, nAnchor, nStartID++, fLifetime);
    for (i = 0; i < nHeight; i++)
    {
        GUI_Draw(oPlayer, sMiddle, nX, ++nY, nAnchor, nStartID++, fLifetime);
    }
    GUI_Draw(oPlayer, sBottom, nX, ++nY, nAnchor, nStartID, fLifetime);

    return nHeight + 2;
}

