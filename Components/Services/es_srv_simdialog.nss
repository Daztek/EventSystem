/*
    ScriptName: es_srv_simdialog.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Dialog]

    Description: An EventSystem Service that allows Subsystems to create
                 conversations through scripting
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_dialog"

// *** Events
const string SIMPLE_DIALOG_EVENT_ACTION_TAKEN               = "SIMPLE_DIALOG_EVENT_ACTION_TAKEN";
const string SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE           = "SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE";
const string SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION         = "SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION";
const string SIMPLE_DIALOG_EVENT_CONVERSATION_END           = "SIMPLE_DIALOG_EVENT_CONVERSATION_END";
// ***

// *** Internal Constants
const string SIMPLE_DIALOG_LOG_TAG                          = "SimpleDialog";
const string SIMPLE_DIALOG_SCRIPT_NAME                      = "es_srv_simdialog";

const string SIMPLE_DIALOG_CONVERSATION                     = "cv_simdialog";
const int    SIMPLE_DIALOG_LIST_RANGE_SIZE                  = 10;
const string SIMPLE_DIALOG_BLANK_ENTRY_TEXT                 = "SDBlankEntry";

const string SIMPLE_DIALOG_PLR_CURRENT_CONVERSATION         = "SDPlayerCurrentConversation";
const string SIMPLE_DIALOG_PLR_CURRENT_PAGE                 = "SDPlayerCurrentPage";
const string SIMPLE_DIALOG_PLR_END_CONVERSATION             = "SDPlayerEndConversation";
const string SIMPLE_DIALOG_PLR_LIST_RANGE                   = "SDPlayerListRange";

const string SIMPLE_DIALOG_CV_PAGE_INDEX                    = "SDConversationPageIndex";
const string SIMPLE_DIALOG_CV_PAGE                          = "SDConversationPage_";
const string SIMPLE_DIALOG_CV_PAGE_CONDITIONAL              = "SDConversationPageConditional_";
const string SIMPLE_DIALOG_CV_OPTION_INDEX                  = "SDConversationOptionIndex";
const string SIMPLE_DIALOG_CV_OPTION                        = "SDConversationOption_";
const string SIMPLE_DIALOG_CV_OPTION_CONDITIONAL            = "SDConversationOptionConditional_";

const string SIMPLE_DIALOG_CONDITIONAL_RESULT               = "SDConditionalResult";
const string SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT        = "SDConditionalOverrideText";
// ***

// Subscribe sSubsystemScript to a SIMPLE_DIALOG_EVENT_*
//
// Event Data Tags for SIMPLE_DIALOG_EVENT_ACTION_TAKEN
//                     SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION:
// - CONVERSATION_TAG -> string
// - PLAYER           -> object
// - PAGE             -> int
// - OPTION           -> int
// Event Data Tags for SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE:
// - CONVERSATION_TAG -> string
// - PLAYER           -> object
// - PAGE             -> int
// Event Data Tags for SIMPLE_DIALOG_EVENT_CONVERSATION_END:
// - CONVERSATION_TAG -> string
// - PLAYER           -> object
// - ABORTED          -> int
void SimpleDialog_SubscribeEvent(string sSubsystemScript, string sSimpleDialogEvent, int bDispatchListMode = FALSE);
// Returns TRUE if sEvent is a SimpleDialog event
int SimpleDialog_GetIsDialogEvent(string sEvent);

// Sets the result of a conditional check in a SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION event
void SimpleDialog_SetResult(int bResult);
// Overrides the page/option text in a SIMPLE_DIALOG_EVENT_CONDITIONAL_* event
void SimpleDialog_SetOverrideText(string sText);

// Create a new conversation object
object SimpleDialog_CreateConversation(string sConversationTag);
// Get a conversation object
// Returns: the conversation object or OBJECT_INVALID on error
object SimpleDialog_GetConversation(string sConversationTag);
// Destroy a conversation object
void SimpleDialog_DestroyConversation(string sConversationTag);

// Add a page with sText to oConversation
// - bEnableConditionalEvent: if TRUE, a SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE event will be signalled
//                            which can be used to override the displayed text
//
// Returns: the page number
int SimpleDialog_AddPage(object oConversation, string sText, int bEnableConditionalEvent = FALSE);
// Get the header text of a conversation page
string SimpleDialog_GetPageText(object oConversation, int nPage);
// Add a conversation option to the current page
// - bEnableConditionalEvent: if TRUE, a SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION event will be signalled
//                            which can be used to add and set the result of a conditional check or to
//                            override the displayed text for the option
//
// Returns: the option number
int SimpleDialog_AddOption(object oConversation, string sText, int bEnableConditionalEvent = FALSE);
// Get the option text of a conversation page
string SimpleDialog_GetOptionText(object oConversation, int nPage, int nOption);

// Set the player's current conversation
//
// Should only be used if you know what you're doing
void SimpleDialog_SetCurrentConversation(object oPlayer, string sConversationTag);
// Get the player's current conversation, or "" when not set
string SimpleDialog_GetCurrentConversation(object oPlayer);
// Returns TRUE if oPlayer is in a conversation with sConversationTag
int SimpleDialog_IsInConversation(object oPlayer, string sConversationTag);
// Set the player's current page
//
// Should be called during a SIMPLE_DIALOG_EVENT_ACTION_TAKEN event
void SimpleDialog_SetCurrentPage(object oPlayer, int nPage);
// Get the player's current page, or 0 when not set
int SimpleDialog_GetCurrentPage(object oPlayer);

// Start a conversation with sConversationTag between oPlayer and oTarget
void SimpleDialog_StartConversation(object oPlayer, object oTarget, string sConversationTag, int nStartingPage = 1, int bClearAllActions = FALSE);
// End the player's current conversation, must be called during a SIMPLE_DIALOG_EVENT_ACTION_TAKEN event
void SimpleDialog_EndConversation(object oPlayer);
// Abort any conversations oObject is involved in
// Should not be called in a conversation script
void SimpleDialog_AbortConversation(object oObject);

void SimpleDialog_SetListRange(object oPlayer, int nRange);
int SimpleDialog_GetListRange(object oPlayer);
int SimpleDialog_GetNextListRange(object oPlayer);
int SimpleDialog_GetPreviousListRange(object oPlayer);
void SimpleDialog_IncrementListRange(object oPlayer);
void SimpleDialog_DecrementListRange(object oPlayer);
int SimpleDialog_CalculateMaxRange(int nAmount);
int SimpleDialog_GetListSelection(object oPlayer, int nOption);

// Returns sText as green text
string SimpleDialog_Token_Action(string sText);
// Returns sText as red text
string SimpleDialog_Token_Check(string sText);
// Returns sText as blue text
string SimpleDialog_Token_Highlight(string sText);

/* *** */

// @Load
void SimpleDialog_Load(string sServiceScript)
{
    ES_Util_AddConditionalScript("simdialog_sc", sServiceScript, nssFunction("SimpleDialog_HandleStartingConditional"));
    ES_Util_AddScript("simdialog_at", sServiceScript, nssFunction("SimpleDialog_HandleActionTaken"));
    ES_Util_AddScript("simdialog_normal", sServiceScript, nssFunction("SimpleDialog_HandleConversationEnd", "FALSE"));
    ES_Util_AddScript("simdialog_abort", sServiceScript, nssFunction("SimpleDialog_HandleConversationEnd", "TRUE"));
}

// @Test
void SimpleDialog_Test(string sServiceScript)
{
    Test_Assert("Conversation File '" + SIMPLE_DIALOG_CONVERSATION + ".dlg' Exists", NWNX_Util_IsValidResRef(SIMPLE_DIALOG_CONVERSATION, NWNX_UTIL_RESREF_TYPE_DIALOG));
}

int SimpleDialog_HandleStartingConditional()
{
    object oSelf = OBJECT_SELF;
    object oPlayer = GetPCSpeaker();
    object oConversation = SimpleDialog_GetConversation(SimpleDialog_GetCurrentConversation(oPlayer));
    int bReturn = FALSE;

    if (GetIsObjectValid(oConversation))
    {
        int nPage = SimpleDialog_GetCurrentPage(oPlayer);
        string sNodeType = GetScriptParam("NODE_TYPE");

        if (sNodeType == "HEADER")
        {

            string sText = SimpleDialog_GetPageText(oConversation, nPage);

            if (sText != "")
            {
                int bConditionalEnabled = GetLocalInt(oConversation, SIMPLE_DIALOG_CV_PAGE_CONDITIONAL + IntToString(nPage));

                if (bConditionalEnabled)
                {
                    DeleteLocalString(oSelf, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

                    Events_PushEventData("CONVERSATION_TAG", SimpleDialog_GetCurrentConversation(oPlayer));
                    Events_PushEventData("PLAYER", ObjectToString(oPlayer));
                    Events_PushEventData("PAGE", IntToString(nPage));
                    Events_SignalEvent(SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, oSelf);

                    string sOverrideText = GetLocalString(oSelf, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

                    sText = sOverrideText == "" ? sText : sOverrideText;
                }

                if (sText == SIMPLE_DIALOG_BLANK_ENTRY_TEXT)
                    NWNX_Dialog_SetCurrentNodeText("");
                else
                    NWNX_Dialog_SetCurrentNodeText(sText);

                bReturn = !GetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_END_CONVERSATION);
            }
        }
        else
        {
            string sOption = GetScriptParam("NODE_ID");
            string sText = SimpleDialog_GetOptionText(oConversation, nPage, StringToInt(sOption));

            if (sText != "")
            {
                int bConditionalEnabled = GetLocalInt(oConversation, SIMPLE_DIALOG_CV_OPTION_CONDITIONAL + IntToString(nPage) + "_" + sOption);

                if (bConditionalEnabled)
                {
                    DeleteLocalInt(oSelf, SIMPLE_DIALOG_CONDITIONAL_RESULT);
                    DeleteLocalString(oSelf, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

                    Events_PushEventData("CONVERSATION_TAG", SimpleDialog_GetCurrentConversation(oPlayer));
                    Events_PushEventData("PLAYER", ObjectToString(oPlayer));
                    Events_PushEventData("PAGE", IntToString(nPage));
                    Events_PushEventData("OPTION", sOption);
                    Events_SignalEvent(SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, oSelf);

                    string sOverrideText = GetLocalString(oSelf, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

                    sText = sOverrideText == "" ? sText : sOverrideText;
                }

                if (sText == SIMPLE_DIALOG_BLANK_ENTRY_TEXT)
                    NWNX_Dialog_SetCurrentNodeText("");
                else
                    NWNX_Dialog_SetCurrentNodeText(sText);

                bReturn = !bConditionalEnabled ? TRUE : GetLocalInt(oSelf, SIMPLE_DIALOG_CONDITIONAL_RESULT);
            }
        }
    }

    return bReturn;
}

void SimpleDialog_HandleActionTaken()
{
    object oSelf = OBJECT_SELF;
    object oPlayer = GetPCSpeaker();

    Events_PushEventData("CONVERSATION_TAG", SimpleDialog_GetCurrentConversation(oPlayer));
    Events_PushEventData("PLAYER", ObjectToString(oPlayer));
    Events_PushEventData("PAGE", IntToString(SimpleDialog_GetCurrentPage(oPlayer)));
    Events_PushEventData("OPTION", GetScriptParam("NODE_ID"));

    Events_SignalEvent(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oSelf);
}

void SimpleDialog_HandleConversationEnd(int bAborted)
{
    object oSelf = OBJECT_SELF;
    object oPlayer = GetPCSpeaker();
    string sConversationTag = SimpleDialog_GetCurrentConversation(oPlayer);

    Events_PushEventData("CONVERSATION_TAG", sConversationTag);
    Events_PushEventData("PLAYER", ObjectToString(oPlayer));
    Events_PushEventData("ABORTED", IntToString(bAborted));
    Events_SignalEvent(SIMPLE_DIALOG_EVENT_CONVERSATION_END, oSelf);

    DeleteLocalInt(oSelf, SIMPLE_DIALOG_CONDITIONAL_RESULT);
    DeleteLocalString(oSelf, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

    DeleteLocalInt(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_PAGE);
    DeleteLocalInt(oPlayer, SIMPLE_DIALOG_PLR_END_CONVERSATION);
    DeleteLocalInt(oPlayer, SIMPLE_DIALOG_PLR_LIST_RANGE);
    DeleteLocalString(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_CONVERSATION);
}

void SimpleDialog_SubscribeEvent(string sSubsystemScript, string sSimpleDialogEvent, int bDispatchListMode = FALSE)
{
    Events_SubscribeEvent(sSubsystemScript, sSimpleDialogEvent, bDispatchListMode);
}

int SimpleDialog_GetIsDialogEvent(string sEvent)
{
    return GetStringLeft(sEvent, GetStringLength("SIMPLE_DIALOG_EVENT_")) == "SIMPLE_DIALOG_EVENT_";
}

/* Conditional Event Related Functions */
void SimpleDialog_SetResult(int bResult)
{
    SetLocalInt(OBJECT_SELF, SIMPLE_DIALOG_CONDITIONAL_RESULT, bResult);
}

void SimpleDialog_SetOverrideText(string sText)
{
    SetLocalString(OBJECT_SELF, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT, sText);
}

/* Conversation Related Functions */
object SimpleDialog_CreateConversation(string sConversationTag)
{
    return ES_Util_CreateDataObject(SIMPLE_DIALOG_SCRIPT_NAME + "_cv_" + sConversationTag);
}

object SimpleDialog_GetConversation(string sConversationTag)
{
    return ES_Util_GetDataObject(SIMPLE_DIALOG_SCRIPT_NAME + "_cv_" + sConversationTag, FALSE);
}

void SimpleDialog_DestroyConversation(string sConversationTag)
{
    ES_Util_DestroyDataObject(SIMPLE_DIALOG_SCRIPT_NAME + "_cv_" + sConversationTag);
}

int SimpleDialog_AddPage(object oConversation, string sText, int bEnableConditionalEvent = FALSE)
{
    int nPage = GetLocalInt(oConversation, SIMPLE_DIALOG_CV_PAGE_INDEX) + 1;

    SetLocalInt(oConversation, SIMPLE_DIALOG_CV_PAGE_INDEX, nPage);
    SetLocalString(oConversation, SIMPLE_DIALOG_CV_PAGE + IntToString(nPage), sText);

    DeleteLocalInt(oConversation, SIMPLE_DIALOG_CV_OPTION_INDEX);

    if (bEnableConditionalEvent)
        SetLocalInt(oConversation, SIMPLE_DIALOG_CV_PAGE_CONDITIONAL + IntToString(nPage), TRUE);

    return nPage;
}

string SimpleDialog_GetPageText(object oConversation, int nPage)
{
    return GetLocalString(oConversation, SIMPLE_DIALOG_CV_PAGE + IntToString(nPage));
}

int SimpleDialog_AddOption(object oConversation, string sText, int bEnableConditionalEvent = FALSE)
{
    int nPage = GetLocalInt(oConversation, SIMPLE_DIALOG_CV_PAGE_INDEX);
    int nOption = GetLocalInt(oConversation, SIMPLE_DIALOG_CV_OPTION_INDEX) + 1;

    SetLocalInt(oConversation, SIMPLE_DIALOG_CV_OPTION_INDEX, nOption);
    SetLocalString(oConversation, SIMPLE_DIALOG_CV_OPTION + IntToString(nPage) + "_" + IntToString(nOption), sText);

    if (bEnableConditionalEvent)
        SetLocalInt(oConversation, SIMPLE_DIALOG_CV_OPTION_CONDITIONAL + IntToString(nPage) + "_" + IntToString(nOption), TRUE);

    return nOption;
}

string SimpleDialog_GetOptionText(object oConversation, int nPage, int nOption)
{
    return GetLocalString(oConversation, SIMPLE_DIALOG_CV_OPTION + IntToString(nPage) + "_" + IntToString(nOption));
}

/* Player Related Functions */
void SimpleDialog_SetCurrentConversation(object oPlayer, string sConversationTag)
{
    SetLocalString(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_CONVERSATION, sConversationTag);
}

string SimpleDialog_GetCurrentConversation(object oPlayer)
{
    return GetLocalString(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_CONVERSATION);
}

int SimpleDialog_IsInConversation(object oPlayer, string sConversationTag)
{
    return IsInConversation(oPlayer) && SimpleDialog_GetCurrentConversation(oPlayer) == sConversationTag;
}

void SimpleDialog_SetCurrentPage(object oPlayer, int nPage)
{
    SetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_PAGE, nPage);
}

int SimpleDialog_GetCurrentPage(object oPlayer)
{
    return GetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_CURRENT_PAGE);
}

void SimpleDialog_StartConversation(object oPlayer, object oTarget, string sConversationTag, int nStartingPage = 1, int bClearAllActions = FALSE)
{
    if (IsInConversation(oTarget))
    {
        SendMessageToPCByStrRef(oPlayer, 6625);// Object is busy
        return;
    }

    object oConversation = SimpleDialog_GetConversation(sConversationTag);

    if (GetIsObjectValid(oConversation))
    {
        SimpleDialog_SetCurrentConversation(oPlayer, sConversationTag);
        SimpleDialog_SetCurrentPage(oPlayer, nStartingPage);

        DeleteLocalInt(oPlayer, SIMPLE_DIALOG_PLR_END_CONVERSATION);
        DeleteLocalInt(oTarget, SIMPLE_DIALOG_CONDITIONAL_RESULT);
        DeleteLocalString(oTarget, SIMPLE_DIALOG_CONDITIONAL_OVERRIDE_TEXT);

        if (bClearAllActions)
        {
            AssignCommand(oPlayer, ClearAllActions(TRUE));
            AssignCommand(oTarget, ClearAllActions(TRUE));
        }

        if (!GetIsPC(oTarget) && GetObjectType(oTarget) == OBJECT_TYPE_CREATURE)
            ActionStartConversation(oPlayer, SIMPLE_DIALOG_CONVERSATION, TRUE, FALSE);
        else
            AssignCommand(oPlayer, ActionStartConversation(oTarget, SIMPLE_DIALOG_CONVERSATION, TRUE, FALSE));
    }
}

void SimpleDialog_EndConversation(object oPlayer)
{
    SetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_END_CONVERSATION, TRUE);
}

void SimpleDialog_AbortConversation(object oObject)
{
    if (!NWNX_Dialog_GetCurrentScriptType())
        NWNX_Dialog_End(oObject);
}

/* List Related Functions */
void SimpleDialog_SetListRange(object oPlayer, int nRange)
{
    SetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_LIST_RANGE, nRange * SIMPLE_DIALOG_LIST_RANGE_SIZE);
}

int SimpleDialog_GetListRange(object oPlayer)
{
    return GetLocalInt(oPlayer, SIMPLE_DIALOG_PLR_LIST_RANGE);
}

int SimpleDialog_GetNextListRange(object oPlayer)
{
    return SimpleDialog_GetListRange(oPlayer) + SIMPLE_DIALOG_LIST_RANGE_SIZE;
}

int SimpleDialog_GetPreviousListRange(object oPlayer)
{
    return SimpleDialog_GetListRange(oPlayer) - SIMPLE_DIALOG_LIST_RANGE_SIZE;
}

void SimpleDialog_IncrementListRange(object oPlayer)
{
    SimpleDialog_SetListRange(oPlayer, (SimpleDialog_GetListRange(oPlayer) / SIMPLE_DIALOG_LIST_RANGE_SIZE) + 1);
}

void SimpleDialog_DecrementListRange(object oPlayer)
{
    SimpleDialog_SetListRange(oPlayer, (SimpleDialog_GetListRange(oPlayer) / SIMPLE_DIALOG_LIST_RANGE_SIZE) - 1);
}

int SimpleDialog_CalculateMaxRange(int nAmount)
{
    return ceil(IntToFloat(nAmount) / 10.0f) * 10;
}

int SimpleDialog_GetListSelection(object oPlayer, int nOption)
{
    return SimpleDialog_GetListRange(oPlayer) + nOption;
}

/* Token Related Functions */
string SimpleDialog_Token_Action(string sText)
{
    return "<StartAction>" + sText + "</Start>";
}

string SimpleDialog_Token_Check(string sText)
{
    return "<StartCheck>" + sText + "</Start>";
}

string SimpleDialog_Token_Highlight(string sText)
{
    return "<StartHighlight>" + sText + "</Start>";
}

