/*
    ScriptName: ai_b_sitonchair.nss
    Created by: Daz

    Description: A SimpleAI Behavior that lets NPCs sit on a chair.
*/

#include "es_s_simai"

//void main(){}

object SitOnChair_FindSeat();

// @SimAIBehavior_OnSpawn
void SitOnChair_Spawn()
{
    SimpleAI_InitialSetup();

    object oSeat = SitOnChair_FindSeat();

    if (oSeat != OBJECT_INVALID)
    {
        ActionForceMoveToObject(oSeat, FALSE, 5.0f, 15.0f);
        ActionSit(oSeat);
    }
    else
    {
        ActionRandomWalk();
    }
}

// @SimAIBehavior_OnHeartbeat
void SitOnChair_Heartbeat()
{
    if (SimpleAI_GetIsAreaEmpty()) return;

    int nAction = GetCurrentAction();

    if (nAction == ACTION_RANDOMWALK)
    {
        if (!Random(5))
        {
            object oSeat = SitOnChair_FindSeat();

            if (oSeat != OBJECT_INVALID)
            {
                ClearAllActions();
                ActionForceMoveToObject(oSeat, FALSE, 5.0f, 15.0f);
                ActionSit(oSeat);
            }
        }
    }
    else
    if (nAction != ACTION_SIT && nAction != ACTION_MOVETOPOINT)
    {
        ActionRandomWalk();
    }
    else
    if (nAction == ACTION_SIT)
    {
        int nRandom = d100();

        if (nRandom <= 5)
            PlayVoiceChat(VOICE_CHAT_LAUGH);
        else
        if(nRandom >= 97)
            PlayVoiceChat(VOICE_CHAT_CHEER);
    }
}

// @SimAIBehavior_OnConversation
void SitOnChair_Conversation()
{
    if (GetCurrentAction() == ACTION_SIT)
    {
        ClearAllActions();

        int nRandom = Random(10);

        if (nRandom >= 5)
           PlayVoiceChat(VOICE_CHAT_THREATEN);
        else
            SpeakString(Random(2) ? "Hey!?" : "What's the dealio?!");


        ActionRandomWalk();
    }
    else
    {
        SpeakString("Behavior: " + SimpleAI_GetAIBehavior());
    }
}

/* *** */

object SitOnChair_FindSeat()
{
    int nNth = 1;
    object oSeat = GetNearestObjectByTag("OBJSIT_SINGLE", OBJECT_SELF, nNth);

    while (GetIsObjectValid(oSeat))
    {
        if (!GetIsObjectValid(GetSittingCreature(oSeat)))
            return oSeat;
        else
            oSeat = GetNearestObjectByTag("OBJSIT_SINGLE", OBJECT_SELF, ++nNth);
    }

    return OBJECT_INVALID;
}

