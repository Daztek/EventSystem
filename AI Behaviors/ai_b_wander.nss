/*
    ScriptName: ai_b_wander.nss
    Created by: Daz

    Description: A SimpleAI Behavior that lets NPCs wander.
*/

#include "es_srv_simai"

//void main(){}

const string AIBEHAVIOR_WANDER_WAYPOINT_TAG     = "WP_AIB_WANDER";

const string AIBEHAVIOR_WANDER_AREA_WAYPOINTS   = "AIBWanderWaypoints";
const string AIBEHAVIOR_WANDER_NEXT_MOVE_TICK   = "AIBWanderNextMoveTick";

object Wander_GetRandomWaypointInArea();

// @SimAIBehavior_Init
void Wander_Init()
{
    int nNth = 0;
    object oWaypoint = GetObjectByTag(AIBEHAVIOR_WANDER_WAYPOINT_TAG, nNth);

    while (GetIsObjectValid(oWaypoint))
    {
        object oArea = GetArea(oWaypoint);
        int nWaypoints = GetLocalInt(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS) + 1;

        SetLocalInt(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS, nWaypoints);
        SetLocalObject(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS + IntToString(nWaypoints), oWaypoint);

        oWaypoint = GetObjectByTag(AIBEHAVIOR_WANDER_WAYPOINT_TAG, ++nNth);
    }
}

// @SimAIBehavior_OnSpawn
void Wander_Spawn()
{
    SetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK, Random(20) + 10);

    ActionForceMoveToObject(Wander_GetRandomWaypointInArea(), FALSE, 2.5f, 30.0f);
    ActionRandomWalk();
}

// @SimAIBehavior_OnHeartbeat
void Wander_Heartbeat()
{
    if (SimpleAI_GetIsAreaEmpty())
    {
        ClearAllActions();
        return;
    }

    int nAction = GetCurrentAction();
    int nTick = SimpleAI_GetTick();

    if (nAction == ACTION_RANDOMWALK)
    {
        int nNextMoveTick = GetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK);

        if (nTick > nNextMoveTick)
        {
            SetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK, Random(20) + 10);
            SimpleAI_SetTick(0);

            ClearAllActions();
            ActionForceMoveToObject(Wander_GetRandomWaypointInArea(), FALSE, 2.5f, 30.0f);
        }
    }
    else
    if (nAction != ACTION_MOVETOPOINT)
    {
        ClearAllActions();
        ActionRandomWalk();
    }

    SimpleAI_SetTick(++nTick);
}

// @SimAIBehavior_OnConversation
void Wander_Conversation()
{
   SpeakString("Behavior: " + SimpleAI_GetAIBehavior());
}

object Wander_GetRandomWaypointInArea()
{
    object oArea = GetArea(OBJECT_SELF);
    int nNumWaypoints = GetLocalInt(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS);
    object oWaypoint = GetLocalObject(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS + IntToString(Random(nNumWaypoints) + 1));

    return GetIsObjectValid(oWaypoint) ? oWaypoint : OBJECT_SELF;
}

