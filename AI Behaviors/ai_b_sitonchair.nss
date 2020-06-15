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

const string AIBEHAVIOR_SITONCHAIR_NEXT_MOVE_TICK   = "AIBSitOnChairNextMoveTick";

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
                int nAmount = GetLocalInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT);

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
    object oSelf = OBJECT_SELF;

    object oClothes = GetLocalObject(oSelf, "AMBIENT_NPC_CLOTHES");
    if (GetIsObjectValid(oClothes))
        ActionEquipItem(oClothes, INVENTORY_SLOT_CHEST);

    SetLocalInt(oSelf, AIBEHAVIOR_SITONCHAIR_NEXT_MOVE_TICK, Random(25) + 10);

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

void SitOnChair_PlayVoiceChat(int nVoiceChatID, float fNearbyCreatureDistance = 3.0f)
{
    object oNearby = GetNearestCreature(CREATURE_TYPE_IS_ALIVE, TRUE);

    if (GetIsObjectValid(oNearby))
    {
        if (GetDistanceBetween(OBJECT_SELF, oNearby) <= fNearbyCreatureDistance)
            SimpleAI_PlayVoiceChat(nVoiceChatID);
    }
}

void SitOnChair_Sit(object oSeat)
{
    if (!GetIsObjectValid(GetSittingCreature(oSeat)))
    {
        ActionSit(oSeat);
        SitOnChair_PlayVoiceChat(VOICE_CHAT_HELLO);
    }
    else
        SitOnChair_PlayVoiceChat(VOICE_CHAT_MOVEOVER);
}

// @SimAIBehavior_OnHeartbeat
void SitOnChair_Heartbeat()
{
    if (SimpleAI_GetIsAreaEmpty()) return;

    object oSelf = OBJECT_SELF;
    int nAction = GetCurrentAction();

    if (nAction == ACTION_RANDOMWALK)
    {
        if (!Random(5))
        {
            object oSeat = SitOnChair_FindSeat();

            if (oSeat != OBJECT_INVALID)
            {
                ClearAllActions();
                ActionForceMoveToObject(oSeat, FALSE, 5.0f, 30.0f);
                ActionDoCommand(SitOnChair_Sit(oSeat));
            }
        }
    }
    else if (nAction == ACTION_SIT)
    {
        int nRandom = Random(100);

        if (nRandom < 5)
            SitOnChair_PlayVoiceChat(VOICE_CHAT_LAUGH);
        else
        if(nRandom > 97)
            SitOnChair_PlayVoiceChat(VOICE_CHAT_CHEER);

        int nTick = SimpleAI_GetTick();
        int nNextMoveTick = GetLocalInt(oSelf, AIBEHAVIOR_SITONCHAIR_NEXT_MOVE_TICK);

        if (nTick > nNextMoveTick)
        {
            SetLocalInt(oSelf, AIBEHAVIOR_SITONCHAIR_NEXT_MOVE_TICK, Random(25) + 10);
            ClearAllActions();
            SitOnChair_PlayVoiceChat(VOICE_CHAT_GOODBYE);
            ActionRandomWalk();
            SimpleAI_SetTick(0);
        }
        else
            SimpleAI_SetTick(++nTick);
    }
    else
    if (nAction != ACTION_SIT && nAction != ACTION_MOVETOPOINT && nAction != ACTION_WAIT)
    {
        ActionRandomWalk();
    }
}

// @SimAIBehavior_OnConversation
void SitOnChair_Conversation()
{
    if (GetCurrentAction() == ACTION_SIT)
        ClearAllActions();

    // Debug
    SpeakString("Behavior: " + SimpleAI_GetAIBehavior());
    PrintString("Pelvis: " + IntToString(GetItemAppearance(GetItemInSlot(INVENTORY_SLOT_CHEST), ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_PELVIS)) +
                ", Head: " + IntToString(GetCreatureBodyPart(CREATURE_PART_HEAD)));
}

/* *** */

object SitOnChair_FindSeat()
{
    object oArea = GetArea(OBJECT_SELF);
    int nSeats = GetLocalInt(oArea, AIBEHAVIOR_SITONCHAIR_SEAT_AMOUNT);
    int nNumTries = 0, nMaxTries = nSeats / 2;

    object oSeat = GetLocalObject(GetLocalObject(oArea, AIBEHAVIOR_SITONCHAIR_SEAT + IntToString(Random(nSeats))), "OBJSIT_SINGLE_CHAIR");

    while (GetIsObjectValid(oSeat) && nNumTries < nMaxTries)
    {
        nNumTries++;

        if (!GetIsObjectValid(GetSittingCreature(oSeat)))
            return oSeat;
        else
            oSeat = GetLocalObject(GetLocalObject(oArea, AIBEHAVIOR_SITONCHAIR_SEAT + IntToString(Random(nSeats))), "OBJSIT_SINGLE_CHAIR");
    }

    return OBJECT_INVALID;
}

