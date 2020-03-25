/*
    ScriptName: es_srv_gui.nss
    Created by: Daz

    Description: An EventSystem Service that provides various GUI functionality
*/

//void main() {}

#include "es_inc_core"

const string GUI_LOG_TAG                    = "GUI";
const string GUI_SCRIPT_NAME                = "es_srv_gui";

const float GUI_PRELOAD_DELAY               = 1.0f;
const int GUI_ID_START                      = 100;

const string GUI_FONT_WINDOW_NAME           = "fnt_esgui";
const string GUI_FONT_WINDOW_TOP_LEFT       = "a";
const string GUI_FONT_WINDOW_TOP_RIGHT      = "c";
const string GUI_FONT_WINDOW_TOP_MIDDLE     = "b";
const string GUI_FONT_WINDOW_MIDDLE_LEFT    = "d";
const string GUI_FONT_WINDOW_MIDDLE_RIGHT   = "f";
const string GUI_FONT_WINDOW_MIDDLE_BLANK   = "i";
const string GUI_FONT_WINDOW_BOTTOM_LEFT    = "h";
const string GUI_FONT_WINDOW_BOTTOM_RIGHT   = "g";
const string GUI_FONT_WINDOW_BOTTOM_MIDDLE  = "e";

const int GUI_COLOR_BLACK                   = 0x000000FF;
const int GUI_COLOR_WHITE                   = 0xFFFFFFFF;
const int GUI_COLOR_RED                     = 0xFF0000FF;
const int GUI_COLOR_GREEN                   = 0x00FF00FF;
const int GUI_COLOR_BLUE                    = 0x0000FFFF;

// Preload sFontTexture
//
// Only needed in some very specific cases where SetTextureOverride() is used
void GUI_PreloadFontTexture(string sFontTexture);

// Request nAmount of PostString() IDs for sSubsystemScript
void GUI_RequestSubsystemIDs(string sSubsystemScript, int nAmount);
// Return the starting PostString() ID for sSubsystemScript
int GUI_GetSubsystemStartID(string sSubsystemScript);
// Return the ending PostString() ID for sSubsystemScript
int GUI_GetSubsystemEndID(string sSubsystemScript);
// Return the amount of PostString() IDs that sSubsystemScript has requested
int GUI_GetSubsystemIDAmount(string sSubsystemScript);

// Clear a PostString() string with nID for oPlayer
void GUI_ClearByID(object oPlayer, int nID);
// Clear a PostString() string ID range for oPlayer
void GUI_ClearByRange(object oPlayer, int nStartID, int nEndID);
// Clear all PostString() strings of sSubsystemScript for oPlayer
void GUI_ClearBySubsystem(object oPlayer, string sSubsystemScript);

// Badly calculate the actual length of a string for use with GUI_Draw{Conversation}Window Functions
// Only really works with fnt_console
int GUI_CalculateStringLength(string sMessage, string sFont = "fnt_console");

// Draw a window with borders on all sides
// Returns the amount of IDs used, minimum of 2
int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 1.0f);
// Draw a window that covers the conversation window and only has right and bottom borders
// Returns the amount of IDs used, minimum of 2
int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 1.0f);

// @Load
void GUI_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    ES_Util_SetInt(oDataObject, "TotalIDs", GUI_ID_START);

    ES_Core_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
}

// @EventHandler
void GUI_EventHandler(string sServiceScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER)
    {
        object oPlayer = GetEnteringObject();
        object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

        int nNumPreloadableFonts = ES_Util_StringArray_Size(oDataObject, "PreloadFontTextures");

        int i;
        for (i = 0; i < nNumPreloadableFonts; i++)
        {
            string sFont = ES_Util_StringArray_At(oDataObject, "PreloadFontTextures", i);
            DelayCommand(GUI_PRELOAD_DELAY, PostString(oPlayer, "a", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 1.0f, 0xFFFFFFF00, 0xFFFFFF00, 1 + i, sFont));
        }
    }
}

void GUI_PreloadFontTexture(string sFontTexture)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    if (ES_Util_StringArray_Contains(oDataObject, "PreloadFontTextures", sFontTexture) == -1)
    {
        ES_Util_Log(GUI_LOG_TAG, "Adding Font Texture '" + sFontTexture + "' to Preload List");

        ES_Util_StringArray_Insert(oDataObject, "PreloadFontTextures", sFontTexture);
    }
}

void GUI_RequestSubsystemIDs(string sSubsystemScript, int nAmount)
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

int GUI_GetSubsystemStartID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_StartID");
}

int GUI_GetSubsystemEndID(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_EndID");
}

int GUI_GetSubsystemIDAmount(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);

    return ES_Util_GetInt(oDataObject, sSubsystemScript + "_Amount");
}

void GUI_ClearByID(object oPlayer, int nID)
{
    PostString(oPlayer, "", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.01f, 0xFFFFFF00, 0xFFFFFF00, nID);
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
    int nStartID = GUI_GetSubsystemStartID(sSubsystemScript);
    int nEndID = nStartID + GUI_GetSubsystemIDAmount(sSubsystemScript);

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

int GUI_DrawWindow(object oPlayer, int nStartID, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 10.0f)
{
    int nStartColor = 0xFFFFFFFF;
    int nEndColor   = 0xFFFFFFFF;

    string sTop = GUI_FONT_WINDOW_TOP_LEFT;
    string sMiddle = GUI_FONT_WINDOW_MIDDLE_LEFT;
    string sBottom = GUI_FONT_WINDOW_BOTTOM_LEFT;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop    += GUI_FONT_WINDOW_TOP_MIDDLE;
        sMiddle += GUI_FONT_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_WINDOW_BOTTOM_MIDDLE;
    }

    sTop    += GUI_FONT_WINDOW_TOP_RIGHT;
    sMiddle += GUI_FONT_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_WINDOW_BOTTOM_RIGHT;

    PostString(oPlayer, sTop, nX, nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID++, GUI_FONT_WINDOW_NAME);
    for (i = 0; i < nHeight; i++)
    {
        PostString(oPlayer, sMiddle, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID++, GUI_FONT_WINDOW_NAME);
    }
    PostString(oPlayer, sBottom, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID, GUI_FONT_WINDOW_NAME);

    return nHeight + 2;
}

int GUI_DrawConversationWindow(object oPlayer, int nStartID, int nWidth, int nHeight, float fLifetime = 10.0f)
{
    int nX = 0, nY = 0;
    int nAnchor = SCREEN_ANCHOR_TOP_LEFT;
    int nStartColor = 0xFFFFFFFF;
    int nEndColor   = 0xFFFFFFFF;

    string sTop = GUI_FONT_WINDOW_MIDDLE_BLANK;
    string sMiddle = GUI_FONT_WINDOW_MIDDLE_BLANK;
    string sBottom = GUI_FONT_WINDOW_BOTTOM_MIDDLE;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop    += GUI_FONT_WINDOW_MIDDLE_BLANK;
        sMiddle += GUI_FONT_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_FONT_WINDOW_BOTTOM_MIDDLE;
    }

    sTop    += GUI_FONT_WINDOW_MIDDLE_RIGHT;
    sMiddle += GUI_FONT_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_FONT_WINDOW_BOTTOM_RIGHT;

    PostString(oPlayer, sTop, nX, nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID++, GUI_FONT_WINDOW_NAME);
    for (i = 0; i < nHeight; i++)
    {
        PostString(oPlayer, sMiddle, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID++, GUI_FONT_WINDOW_NAME);
    }
    PostString(oPlayer, sBottom, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nStartID, GUI_FONT_WINDOW_NAME);

    return nHeight + 2;
}

