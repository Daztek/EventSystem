/*
    ScriptName: es_s_emote.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: A subsystem that adds an /emote chat command that allows players to emote
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_chatcom"

const float EMOTE_DURATION_LOOPING = 86400.0f;

// @Load
void Emote_Load(string sSubsystemScript)
{
    ChatCommand_Register(sSubsystemScript, "Emote_HandleEmoteChatCommand",  CHATCOMMAND_GLOBAL_PREFIX + "emote", "[emote]", "Perform an emote!");
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
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_CONJURE1, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "cast2")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_CONJURE2, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "deadback")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_DEAD_BACK, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "deadfront")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_DEAD_FRONT, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "low")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_GET_LOW, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "mid")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_GET_MID, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "meditate")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_MEDITATE, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "drunk")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_PAUSE_DRUNK, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "tired")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_PAUSE_TIRED, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "sit")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_SIT_CROSS, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "spasm")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_SPASM, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "forceful")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_FORCEFUL, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "laugh")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_LAUGHING, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "talk")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_NORMAL, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "plead")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_TALK_PLEADING, EMOTE_DURATION_LOOPING);
    else
    if (sEmote == "worship")
        Emote_DoEmote(oPlayer, ANIMATION_LOOPING_WORSHIP, EMOTE_DURATION_LOOPING);
    else
    {
        SendMessageToPC(oPlayer, "Available Emotes: bow, duck, dodge, drink, greet, bored, scratch, " +
            "read, salute, steal, taunt, victory1, victory2, victory3, cast1, cast2, deadback, deadfront, " +
            "low, mid, meditate, drunk, tired, sit, spasm, forceful, laugh, talk, plead, worship");
    }

    SetPCChatMessage("");
}

