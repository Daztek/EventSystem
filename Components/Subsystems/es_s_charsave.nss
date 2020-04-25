/*
    ScriptName: es_s_charsave.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem subsystem that periodically saves all player
                 characters and adds a chat command for players to manually
                 save their character. Also limits how often player my export
                 their character to their localvault.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_wtimer"
#include "es_srv_chatcom"

const string CHARACTERSAVE_LOG_TAG                  = "CharacterSave";
const string CHARACTERSAVE_SCRIPT_NAME              = "es_s_charsave";

const string CHARACTERSAVE_CHAT_COMMAND             = "save";
const string CHARACTERSAVE_AUTO_SAVE_INTERVAL       = WORLD_TIMER_EVENT_5_MINUTES;

const float  CHARACTERSAVE_MANUAL_SAVE_COOLDOWN     = 60.0f;
const float  CHARACTERSAVE_EXPORT_COOLDOWN          = 300.0f;

// @Load
void CharacterSave_Load(string sSubsystemScript)
{
    WorldTimer_SubscribeEvent(sSubsystemScript, CHARACTERSAVE_AUTO_SAVE_INTERVAL);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_CLIENT_EXPORT_CHARACTER_BEFORE");

    if (CHARACTERSAVE_CHAT_COMMAND != "")
    {
        int nId = ChatCommand_Register(sSubsystemScript, "CharacterSave_SaveChatCommand",
            CHATCOMMAND_GLOBAL_PREFIX + CHARACTERSAVE_CHAT_COMMAND, "", "Manually save your character.");

        ChatCommand_SetPermission(nId, "", "!GetIsDM(oPlayer)", "", "");
    }
}

// @EventHandler
void CharacterSave_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == CHARACTERSAVE_AUTO_SAVE_INTERVAL)
    {
        if (!ES_Util_GetPlayersOnline()) return;

        ES_Util_Log(CHARACTERSAVE_LOG_TAG, "Saving all characters.");

        object oPlayer = GetFirstPC();
        while (GetIsObjectValid(oPlayer))
        {
            if (!GetIsDM(oPlayer))
            {
                ExportSingleCharacter(oPlayer);

                ES_Util_SendServerMessage("Your character has been automatically saved.", oPlayer);
            }

            oPlayer = GetNextPC();
        }
    }
    else
    if (sEvent == "NWNX_ON_CLIENT_EXPORT_CHARACTER_BEFORE")
    {
        object oPlayer = OBJECT_SELF;

        if (GetIsDM(oPlayer))
            return;

        object oDataObject = ES_Util_GetDataObject(CHARACTERSAVE_SCRIPT_NAME);
        string sExportCooldownVariable = "SaveCooldown_" + GetObjectUUID(oPlayer);

        if (!GetLocalInt(oDataObject, sExportCooldownVariable))
        {
            SetLocalInt(oDataObject, sExportCooldownVariable, TRUE);
            DelayCommand(CHARACTERSAVE_EXPORT_COOLDOWN, DeleteLocalInt(oDataObject, sExportCooldownVariable));
        }
        else
        {
            NWNX_Events_SkipEvent();

            SendMessageToPC(oPlayer, ES_Util_ColorString("Request denied, you may only export your character every '" +
                FloatToString(CHARACTERSAVE_EXPORT_COOLDOWN, 0, 0) + "' seconds.", "700"));
        }
    }
}

void CharacterSave_SaveChatCommand(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(CHARACTERSAVE_SCRIPT_NAME);
    string sSaveCooldownVariable = "SaveCooldown_" + GetObjectUUID(oPlayer);

    if (!GetLocalInt(oDataObject, sSaveCooldownVariable))
    {
        ExportSingleCharacter(oPlayer);

        SetLocalInt(oDataObject, sSaveCooldownVariable, TRUE);
        DelayCommand(CHARACTERSAVE_MANUAL_SAVE_COOLDOWN, DeleteLocalInt(oDataObject, sSaveCooldownVariable));

        ES_Util_SendServerMessage("Your character has been manually saved.", oPlayer);
    }
    else
    {
        ES_Util_SendServerMessage("You may only save your character every '" +
            FloatToString(CHARACTERSAVE_MANUAL_SAVE_COOLDOWN, 0, 0) + "' seconds.", oPlayer);
    }

    SetPCChatMessage("");
}

