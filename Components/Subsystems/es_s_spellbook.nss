/*
    ScriptName: es_s_spellbook.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Regex Creature]

    Description: A Spellbook Subsystem

    Note: This is a very rough proof of concept which only works for Sorcerers.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_gui"
#include "es_srv_chatcom"

#include "nwnx_regex"
#include "nwnx_creature"

const string SPELLBOOK_LOG_TAG                  = "Spellbook";
const string SPELLBOOK_SCRIPT_NAME              = "es_s_spellbook";
const string SPELLBOOK_CHATCOMMAND_NAME         = "spellbook";
const string SPELLBOOK_CHATCOMMAND_DESCRIPTION  = "Look at all the cool spells you know!";

const int SPELLBOOK_GUI_NUM_IDS                 = 50;

const string SPELLBOOK_BOOK_TEXTURE_NAME        = "fnt_book";
const string SPELLBOOK_ICON_TEXTURE_NAME        = "fnt_es_icon32";
const string SPELLBOOK_GLYPH_NAME               = "a";

const string SPELLBOOK_SPELL_DESCRIPTION        = "SpellDescription_";
const string SPELLBOOK_SPELL_DATA_ARRAY         = "SpellData_";

// @Load
void Spellbook_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_KEYBOARD_BEFORE", TRUE);

    ChatCommand_Register(sSubsystemScript, "Spellbook_ChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + SPELLBOOK_CHATCOMMAND_NAME, "", SPELLBOOK_CHATCOMMAND_DESCRIPTION);

    GUI_ReserveIDs(sSubsystemScript, SPELLBOOK_GUI_NUM_IDS);
}

void Spellbook_ExtractSpellData(int nSpellID)
{
    object oDataObject = ES_Util_GetDataObject(SPELLBOOK_SCRIPT_NAME);

    if (GetLocalString(oDataObject, SPELLBOOK_SPELL_DESCRIPTION + IntToString(nSpellID)) != "")
        return;

    string sArrayName = SPELLBOOK_SPELL_DATA_ARRAY + IntToString(nSpellID);

    string sSpellData = NWNX_Regex_Replace(GetStringByStrRef(StringToInt(Get2DAString("spells", "SpellDesc", nSpellID))), "\n", "*", FALSE);

    int nDescriptionStart = FindSubString(sSpellData, "**", 0);
    string sDescription = GetSubString(sSpellData, nDescriptionStart + 2, GetStringLength(sSpellData) - nDescriptionStart - 2);

    SetLocalString(oDataObject, SPELLBOOK_SPELL_DESCRIPTION + IntToString(nSpellID), sDescription);

    sSpellData = GetSubString(sSpellData, 0, GetStringLength(sSpellData) - GetStringLength(sDescription) - 1);

    int nDataStart = 0, nDataEnd = FindSubString(sSpellData, "*", nDataStart);

    while (nDataEnd != -1)
    {
        string sData = GetSubString(sSpellData, nDataStart, nDataEnd - nDataStart);

        StringArray_Insert(oDataObject, sArrayName, sData);

        nDataStart = nDataEnd + 1;
        nDataEnd = FindSubString(sSpellData, "*", nDataStart);
    }
}

void Spellbook_DrawSpellbookGUI(object oPlayer, int nSpellID)
{
    object oDataObject = ES_Util_GetDataObject(SPELLBOOK_SCRIPT_NAME);
    int nID = GUI_GetStartID(SPELLBOOK_SCRIPT_NAME);
    int nTextColor = GUI_COLOR_WHITE;
    string sTextFont = "fnt_dialog_big16";
    int nMaxLength = 47;
    float fLifeTime = 0.0f;

    string sSpellName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", nSpellID)));
    string sSpellIconResRef = GetStringLowerCase(Get2DAString("spells", "IconResRef", nSpellID));

    // *** KNOWN SPELLS PAGE
    int nCurrentSpellLevel = GetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellLevel");
    int nNumSpells = StringArray_Size(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nCurrentSpellLevel));

    PostString(oPlayer, "Spell Level: " + IntToString(nCurrentSpellLevel), 10, 5,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    int nSpellsX = 10, nSpellsY = 7;

    int nSpellIndex;
    for (nSpellIndex = 0; nSpellIndex < nNumSpells; nSpellIndex++)
    {
        string sName = GetStringByStrRef(StringToInt(Get2DAString("spells", "Name", StringToInt(StringArray_At(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nCurrentSpellLevel), nSpellIndex)))));

        if (nSpellIndex == GetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellIndex"))
            PostString(oPlayer, "*", nSpellsX - 1, nSpellsY,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

        PostString(oPlayer, sName, nSpellsX, nSpellsY++,  SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);
    }

    // *** SPELL INFO PAGE
    // Spell Icon Texture
    PostString(oPlayer, SPELLBOOK_GLYPH_NAME, 42, 3, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID++, SPELLBOOK_ICON_TEXTURE_NAME);

    // Spell Name
    PostString(oPlayer, sSpellName, 47, 4, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    // Spell Description
    int nDX = 42, nDY = 6;
    string sDescription = GetLocalString(oDataObject, SPELLBOOK_SPELL_DESCRIPTION + IntToString(nSpellID));
    int nLines = GUI_DrawSplitText(oPlayer, sDescription, nMaxLength, nDX, nDY, nID++, nTextColor, fLifeTime, sTextFont);
    nID += nLines;

    // Spell Data
    string sArrayName = SPELLBOOK_SPELL_DATA_ARRAY + IntToString(nSpellID);
    int nSpellDataSize = StringArray_Size(oDataObject, sArrayName);
    int nSpellDataIndex;

    nDY += nLines + 1;
    for (nSpellDataIndex = 0; nSpellDataIndex < nSpellDataSize; nSpellDataIndex++)
    {
        string sSpellData = StringArray_At(oDataObject, sArrayName, nSpellDataIndex);

        nLines = GUI_DrawSplitText(oPlayer, sSpellData, nMaxLength, nDX, nDY, nID++, nTextColor, fLifeTime, sTextFont);
        nID += nLines;
        nDY += nLines;
    }

    // Update Spell Icon
    SetTextureOverride(SPELLBOOK_ICON_TEXTURE_NAME, sSpellIconResRef, oPlayer);
}

void SpellBook_ExtractKnownSpells(object oPlayer, int nLevel)
{
    if (StringArray_Size(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nLevel))) return;

    int nNumSpells = NWNX_Creature_GetKnownSpellCount(oPlayer, CLASS_TYPE_SORCERER, nLevel);

    int nSpellIndex;
    for (nSpellIndex = 0; nSpellIndex < nNumSpells; nSpellIndex++)
    {
        StringArray_Insert(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nLevel), IntToString(NWNX_Creature_GetKnownSpell(oPlayer, CLASS_TYPE_SORCERER, nLevel, nSpellIndex)));
    }
}

void Spellbook_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    GUI_ClearBySubsystem(oPlayer, SPELLBOOK_SCRIPT_NAME);

    if (GUI_GetIsPlayerInputLocked(oPlayer))
    {
        GUI_UnlockPlayerInput(oPlayer);

        Events_RemoveObjectFromDispatchList(SPELLBOOK_SCRIPT_NAME, "NWNX_ON_INPUT_KEYBOARD_BEFORE", oPlayer);

        DeleteLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellIndex");
        DeleteLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellLevel");
    }
    else
    {
        GUI_LockPlayerInput(oPlayer);

        Events_AddObjectToDispatchList(SPELLBOOK_SCRIPT_NAME, "NWNX_ON_INPUT_KEYBOARD_BEFORE", oPlayer);

        int nCurrentSpellLevel = GetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellLevel");

        SpellBook_ExtractKnownSpells(oPlayer, nCurrentSpellLevel);

        int nCurrentSpell = StringToInt(StringArray_At(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nCurrentSpellLevel), GetLocalInt(oPlayer, "CurrentSpellIndex")));

        int nID = GUI_GetEndID(SPELLBOOK_SCRIPT_NAME);
        // Draw Book
        PostString(oPlayer, SPELLBOOK_GLYPH_NAME, 1, 1, SCREEN_ANCHOR_TOP_LEFT, 0.0f, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID--, SPELLBOOK_BOOK_TEXTURE_NAME);
        // Draw Spell Icon
        PostString(oPlayer, SPELLBOOK_GLYPH_NAME, 42, 3, SCREEN_ANCHOR_TOP_LEFT, 0.0f, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID--, SPELLBOOK_ICON_TEXTURE_NAME);
        // Header
        string sHeader = GetName(oPlayer) + "'s Spellbook";
        PostString(oPlayer, sHeader, 10, 3, SCREEN_ANCHOR_TOP_LEFT, 0.0f, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID, "fnt_dialog_big16");

        Spellbook_ExtractSpellData(nCurrentSpell);
        Spellbook_DrawSpellbookGUI(oPlayer, nCurrentSpell);
    }

    SetPCChatMessage("");
}

// @EventHandler
void Spellbook_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_INPUT_KEYBOARD_BEFORE")
    {
        object oPlayer = OBJECT_SELF;

        if (!GUI_GetIsPlayerInputLocked(oPlayer))
            return;

        string sKey = Events_GetEventData_NWNX_String("KEY");

        int bRedraw = FALSE;
        int nCurrentSpellLevel = GetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellLevel");
        int nCurrentSpellIndex = GetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellIndex");

        if (sKey == "W")
        {
            if (nCurrentSpellIndex > 0)
            {
                nCurrentSpellIndex--;
                bRedraw = TRUE;
            }
        }
        else
        if (sKey == "S")
        {
            if (nCurrentSpellIndex < StringArray_Size(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_"+ IntToString(nCurrentSpellLevel)) - 1)
            {
                nCurrentSpellIndex++;
                bRedraw = TRUE;
            }
        }
        else
        if (sKey == "E")
        {
            if (nCurrentSpellLevel < 9)
            {
                nCurrentSpellLevel++;
                nCurrentSpellIndex = 0;
                bRedraw = TRUE;
            }
        }
        else
        if (sKey == "Q")
        {
            if (nCurrentSpellLevel > 0)
            {
                nCurrentSpellLevel--;
                nCurrentSpellIndex = 0;
                bRedraw = TRUE;
            }
        }

        SetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellLevel", nCurrentSpellLevel);
        SetLocalInt(oPlayer, SPELLBOOK_SCRIPT_NAME + "CurrentSpellIndex", nCurrentSpellIndex);

        if (bRedraw)
        {
            SpellBook_ExtractKnownSpells(oPlayer, nCurrentSpellLevel);

            int nCurrentSpell = StringToInt(StringArray_At(oPlayer, SPELLBOOK_SCRIPT_NAME + "Spells_" + IntToString(nCurrentSpellLevel), nCurrentSpellIndex));

            int nStartID = GUI_GetStartID(SPELLBOOK_SCRIPT_NAME);
            GUI_ClearByRange(oPlayer, nStartID, nStartID + GUI_GetIDAmount(SPELLBOOK_SCRIPT_NAME) - 3);
            Spellbook_ExtractSpellData(nCurrentSpell);
            Spellbook_DrawSpellbookGUI(oPlayer, nCurrentSpell);
        }
    }
}

