/*
    ScriptName: ai_b_sitonchair.nss
    Created by: Daz

    Description: A SimpleAI Behavior that lets NPCs sit on a chair.
*/

#include "es_srv_simai"

//void main(){}

const string AIBEHAVIOR_SITONCHAIR_WAYPOINT_TAG     = "WP_AIB_SITONCHAIR";

const string AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT      = "AIBSitOnChairSeatAmount";
const string AIBEHAVIOR_SITONCHAIR_SEAT             = "AIBSitOnChairSeat_";

object SitOnChair_FindSeat();

// @SimAIBehavior_Init
void SitOnChair_Init()
{
    int nNth = 0;
    object oWaypoint = GetObjectByTag(AIBEHAVIOR_SITONCHAIR_WAYPOINT_TAG, nNth);

    while (GetIsObjectValid(oWaypoint))
    {
        object oArea = GetArea(oWaypoint);

        if (!GetLocalInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT))
        {
            int nNthSeat = 1;
            object oSeat = GetNearestObjectByTag("OBJSIT_SINGLE", oWaypoint, nNthSeat);

            while (GetIsObjectValid(oSeat))
            {
                int nAmount = ES_Util_GetInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT);

                SetLocalInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT, ++nAmount);
                SetLocalObject(oArea, AIBEHAVIOR_SITONCHAIR_SEAT + IntToString(nAmount), oSeat);

                oSeat = GetNearestObjectByTag("OBJSIT_SINGLE", oWaypoint, ++nNthSeat);
            }
        }

        oWaypoint = GetObjectByTag(AIBEHAVIOR_SITONCHAIR_WAYPOINT_TAG, ++nNth);
    }
}

// @SimAIBehavior_OnSpawn
void SitOnChair_Spawn()
{
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
        int nRandom = Random(100);

        if (nRandom < 5)
            PlayVoiceChat(VOICE_CHAT_LAUGH);
        else
        if(nRandom > 97)
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

        if (nRandom > 4)
           PlayVoiceChat(VOICE_CHAT_THREATEN);
        else
            SpeakString(Random(2) ? "Hey!" : "That's my seat!");


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
    object oArea = GetArea(OBJECT_SELF);
    int nSeats = GetLocalInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT);
    int nNumTries = 0, nMaxTries = nSeats / 2;

    object oSeat = GetLocalObject(oArea, AIBEHAVIOR_SITONCHAIR_SEAT + IntToString(Random(nSeats)));

    while (GetIsObjectValid(oSeat) && nNumTries < nMaxTries)
    {
        nNumTries++;

        if (!GetIsObjectValid(GetSittingCreature(oSeat)))
            return oSeat;
        else
            oSeat = GetLocalObject(oArea, AIBEHAVIOR_SITONCHAIR_SEAT + IntToString(Random(nSeats)));
    }

    return OBJECT_INVALID;
}

