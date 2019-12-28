/*
    ScriptName: es_s_emote.nss
    Created by: Daz

    Description: A subsystem that adds an /emote chat command that allows players to emote
*/

//void main() {}

#include "es_s_chatcommand"

// @EventSystem_Init
void Emote_Init(string sEventHandlerScript)
{
    ChatCommand_Register(sEventHandlerScript, "Emote_HandleEmoteChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + "emote", "[emote]", "Perform an emote!");
}

void Emote_DoEmote(object oPlayer, int nEmote, float fDuration = 0.0f)
{
    AssignCommand(oPlayer, ClearAllActions());
    AssignCommand(oPlayer, ActionPlayAnimation(nEmote, 1.0, fDuration));
}

void Emote_HandleEmoteChatCommand(object oPlayer, string sEmote, int nVolume)
{
    if (sEmote == "bow")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_BOW);
    else
    if (sEmote == "duck")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_DODGE_DUCK);
    else
    if (sEmote == "dodge")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_DODGE_SIDE);
    else
    if (sEmote == "drink")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_DRINK);
    else
    if (sEmote == "greet")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_GREETING);
    else
    if (sEmote == "bored")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_PAUSE_BORED);
    else
    if (sEmote == "scratch")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_PAUSE_SCRATCH_HEAD);
    else
    if (sEmote == "read")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_READ);
    else
    if (sEmote == "salute")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_SALUTE);
    else
    if (sEmote == "steal")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_STEAL);
    else
    if (sEmote == "taunt")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_TAUNT);
    else
    if (sEmote == "victory1")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_VICTORY1);
    else
    if (sEmote == "victory2")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_VICTORY2);
    else
    if (sEmote == "victory3")
        Emote_DoEmote(oPlayer, ANIMATION_FIREFORGET_VICTORY3);
    else
    if (sEmote == "cast1")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_CONJURE1, 3600.0f);
    else
    if (sEmote == "cast2")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_CONJURE1, 3600.0f);
    else
    if (sEmote == "deadback")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_DEAD_BACK, 3600.0f);
    else
    if (sEmote == "deadfront")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_DEAD_FRONT, 3600.0f);
    else
    if (sEmote == "low")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_GET_LOW, 3600.0f);
    else
    if (sEmote == "mid")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_GET_MID, 3600.0f);
    else
    if (sEmote == "meditate")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_MEDITATE, 3600.0f);
    else
    if (sEmote == "drunk")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_PAUSE_DRUNK, 3600.0f);
    else
    if (sEmote == "tired")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_PAUSE_TIRED, 3600.0f);
    else
    if (sEmote == "sit")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_SIT_CROSS, 3600.0f);
    else
    if (sEmote == "spasm")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_SPASM, 3600.0f);
    else
    if (sEmote == "forceful")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_FORCEFUL, 3600.0f);
    else
    if (sEmote == "laugh")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_LAUGHING, 3600.0f);
    else
    if (sEmote == "talk")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_NORMAL, 3600.0f);
    else
    if (sEmote == "plead")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_PLEADING, 3600.0f);
    else
    if (sEmote == "worship")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_WORSHIP, 3600.0f);
    else
    {
        SendMessageToPC(oPlayer, "Available Emotes: bow, duck, dodge, drink, greet, bored, scratch, " +
            "read, salute, steal, taunt, victory1, victory2, victory3, cast1, cast2, deadback, deadfront, " +
            "low, mid, meditate, drunk, tired, sit, spasm, forceful, laugh, talk, plead, worship");
    }

    SetPCChatMessage("");
}

