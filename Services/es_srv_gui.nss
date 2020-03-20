/*
    ScriptName: es_srv_gui.nss
    Created by: Daz

    Description: An EventSystem Service that provides some gui functionality
*/

//void main() {}

#include "es_inc_core"

const string GUI_LOG_TAG                = "GUI";
const string GUI_SCRIPT_NAME            = "es_srv_gui";

const string GUI_FONT_WINDOW_NAME       = "fnt_esgui";

const string GUI_WINDOW_TOP_LEFT        = "a";
const string GUI_WINDOW_TOP_RIGHT       = "c";
const string GUI_WINDOW_TOP_MIDDLE      = "b";

const string GUI_WINDOW_MIDDLE_LEFT     = "d";
const string GUI_WINDOW_MIDDLE_RIGHT    = "f";
const string GUI_WINDOW_MIDDLE_BLANK    = "i";

const string GUI_WINDOW_BOTTOM_LEFT     = "h";
const string GUI_WINDOW_BOTTOM_RIGHT    = "g";
const string GUI_WINDOW_BOTTOM_MIDDLE   = "e";

int GUI_CalculateStringLength(string sMessage, string sFont = "fnt_console");
int GUI_DrawWindow(object oPlayer, int nId, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 1.0f);

// @Load
void GUI_Load(string sServiceScript)
{
    //object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);
}

// @Post
void GUI_Post(string sServiceScript)
{
    //object oDataObject = ES_Util_GetDataObject(GUI_SCRIPT_NAME);
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

int GUI_DrawWindow(object oPlayer, int nId, int nAnchor, int nX, int nY, int nWidth, int nHeight, float fLifetime = 1.0f)
{
    int nStartColor = 0xFFFFFFFF;
    int nEndColor   = 0xFFFFFFFF;

    string sTop = GUI_WINDOW_TOP_LEFT;
    string sMiddle = GUI_WINDOW_MIDDLE_LEFT;
    string sBottom = GUI_WINDOW_BOTTOM_LEFT;

    int i;
    for (i = 0; i < nWidth; i++)
    {
        sTop    += GUI_WINDOW_TOP_MIDDLE;
        sMiddle += GUI_WINDOW_MIDDLE_BLANK;
        sBottom += GUI_WINDOW_BOTTOM_MIDDLE;
    }

    sTop    += GUI_WINDOW_TOP_RIGHT;
    sMiddle += GUI_WINDOW_MIDDLE_RIGHT;
    sBottom += GUI_WINDOW_BOTTOM_RIGHT;

    PostString(oPlayer, sTop, nX, nY, nAnchor, fLifetime, nStartColor, nEndColor, nId++, GUI_FONT_WINDOW_NAME);
    for (i = 0; i < nHeight; i++)
    {
        PostString(oPlayer, sMiddle, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nId++, GUI_FONT_WINDOW_NAME);
    }
    PostString(oPlayer, sBottom, nX, ++nY, nAnchor, fLifetime, nStartColor, nEndColor, nId++, GUI_FONT_WINDOW_NAME);

    return nId;
}

