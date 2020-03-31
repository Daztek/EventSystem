/*
    ScriptName: es_s_charsave.nss
    Created by: Daz

    Description: An EventSystem subsystem that periodically saves all player
                 characters and adds a chat command for players to manually
                 save their character.
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_wtimer"
#include "es_srv_chatcom"

const string CHARACTERSAVE_LOG_TAG              = "CharacterSave";
const string CHARACTERSAVE_SCRIPT_NAME          = "es_s_charsave";

const string CHARACTERSAVE_CHAT_COMMAND         = "save";
const string CHARACTERSAVE_AUTO_SAVE_INTERVAL   = WORLD_TIMER_EVENT_5_MINUTES;
const float  CHARACTERSAVE_MANUAL_COOLDOWN      = 60.0f;

// @Load
void CharacterSave_Load(string sSubsystemScript)
{
    WorldTimer_SubscribeEvent(sSubsystemScript, CHARACTERSAVE_AUTO_SAVE_INTERVAL);

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
}

void CharacterSave_SaveChatCommand(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(CHARACTERSAVE_SCRIPT_NAME);
    string sCooldownVariable = CHARACTERSAVE_SCRIPT_NAME + "_Cooldown_" + GetObjectUUID(oPlayer);

    if (!ES_Util_GetInt(oDataObject, sCooldownVariable))
    {
        ExportSingleCharacter(oPlayer);

        ES_Util_SetInt(oDataObject, sCooldownVariable, TRUE);
        DelayCommand(CHARACTERSAVE_MANUAL_COOLDOWN, ES_Util_DeleteInt(oDataObject, sCooldownVariable));

        ES_Util_SendServerMessage("Your character has been manually saved.", oPlayer);
    }
    else
    {
        ES_Util_SendServerMessage("You may only save your character every '" +
            FloatToString(CHARACTERSAVE_MANUAL_COOLDOWN, 0, 2) + "' seconds.", oPlayer);
    }

    SetPCChatMessage("");
}

