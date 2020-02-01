/*
    ScriptName: es_s_charsave.nss
    Created by: Daz

    Description: An EventSystem subsystem that periodically saves all player
                 characters and adds a chat command for players to manually
                 save their character.
*/

//void main() {}

#include "es_inc_core"
#include "es_s_worldtimer"
#include "es_s_chatcommand"

const string CHARACTERSAVE_SYSTEM_TAG           = "CharacterSave";
const string CHARACTERSAVE_CHAT_COMMAND         = "save";
const string CHARACTERSAVE_AUTO_SAVE_INTERVAL   = WORLD_TIMER_EVENT_5_MINUTES;
const float  CHARACTERSAVE_MANUAL_COOLDOWN      = 60.0f;

// @EventSystem_Init
void CharacterSave_Init(string sSubsystemScript)
{
    WorldTimer_SubscribeEvent(sSubsystemScript, CHARACTERSAVE_AUTO_SAVE_INTERVAL);

    if (CHARACTERSAVE_CHAT_COMMAND != "")
    {
        int nId = ChatCommand_Register(sSubsystemScript, "CharacterSave_SaveChatCommand",
            CHATCOMMAND_GLOBAL_PREFIX + CHARACTERSAVE_CHAT_COMMAND, "", "Manually save your character.");
        ChatCommand_SetPermission(nId, "", "!GetIsDM(oPlayer)", "", "");
    }
}

// @EventSystem_EventHandler
void CharacterSave_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == CHARACTERSAVE_AUTO_SAVE_INTERVAL)
    {
        ES_Util_Log(CHARACTERSAVE_SYSTEM_TAG, "Saving all characters.");

        object oPlayer = GetFirstPC();

        while (GetIsObjectValid(oPlayer))
        {
            ExportSingleCharacter(oPlayer);

            SendMessageToPC(oPlayer, "Your character has been automatically saved.");

            oPlayer = GetNextPC();
        }
    }
}

void CharacterSave_SaveChatCommand(object oPlayer, string sParams, int nVolume)
{
    if (!ES_Util_GetInt(oPlayer, CHARACTERSAVE_SYSTEM_TAG))
    {
        ExportSingleCharacter(oPlayer);

        ES_Util_SetInt(oPlayer, CHARACTERSAVE_SYSTEM_TAG, TRUE);
        DelayCommand(CHARACTERSAVE_MANUAL_COOLDOWN, ES_Util_DeleteInt(oPlayer, CHARACTERSAVE_SYSTEM_TAG));

        FloatingTextStringOnCreature("Your character has been manually saved.", oPlayer, FALSE);
    }
    else
    {
        FloatingTextStringOnCreature("You may only save your character every '" +
            FloatToString(CHARACTERSAVE_MANUAL_COOLDOWN, 0, 2) + "' seconds.", oPlayer, FALSE);
    }
}

