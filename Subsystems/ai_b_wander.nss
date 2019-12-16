/*
    ScriptName: ai_b_wander.nss
    Created by: Daz

    Description: A SimpleAI Behavior that lets NPCs wander.
*/

const string AIBEHAVIOR_WANDER_WAYPOINT_TAG     = "WP_AIB_WANDER";

const string AIBEHAVIOR_WANDER_AREA_WAYPOINTS   = "AIBWanderWaypoints";
const string AIBEHAVIOR_WANDER_NEXT_MOVE_TICK   = "AIBWanderNextMoveTick";

#include "es_s_simai"

object GetRandomWaypointInArea();

// @SimAIBehavior_Init
void Init()
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
void Spawn()
{
    SimpleAI_InitialSetup();

    SetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK, SimpleAI_GetCurrentTick() + Random(20) + 10);

    ActionForceMoveToObject(GetRandomWaypointInArea(), FALSE, 2.5f, 30.0f);
    ActionRandomWalk();
}

// @SimAIBehavior_OnHeartbeat
void Heartbeat()
{
    if (SimpleAI_GetIsAreaEmpty())
    {
        ClearAllActions();
        return;
    }

    int nCurrentAction = GetCurrentAction();

    if (nCurrentAction == ACTION_RANDOMWALK)
    {
        int nCurrentTick = SimpleAI_GetCurrentTick();
        int nNextMoveTick = GetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK);

        if (nCurrentTick > nNextMoveTick)
        {
            SetLocalInt(OBJECT_SELF, AIBEHAVIOR_WANDER_NEXT_MOVE_TICK, nCurrentTick + Random(20) + 10);
            ClearAllActions();
            ActionForceMoveToObject(GetRandomWaypointInArea(), FALSE, 2.5f, 30.0f);
        }
    }
    else
    if (nCurrentAction != ACTION_MOVETOPOINT)
    {
        ClearAllActions();
        ActionRandomWalk();
    }

    SimpleAI_IncrementTick();
}

// @SimAIBehavior_OnConversation
void Conversation()
{
   SpeakString("Behavior: " + SimpleAI_GetAIBehavior());
}

object GetRandomWaypointInArea()
{
    object oArea = GetArea(OBJECT_SELF);
    int nNumWaypoints = GetLocalInt(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS);
    object oWaypoint = GetLocalObject(oArea, AIBEHAVIOR_WANDER_AREA_WAYPOINTS + IntToString(Random(nNumWaypoints) + 1));

    return GetIsObjectValid(oWaypoint) ? oWaypoint : OBJECT_SELF;
}

