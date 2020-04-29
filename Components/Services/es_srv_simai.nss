/*
    ScriptName: es_srv_simai.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Area]

    Description: An EventSystem Service that allows the creation of simple AI routines through scripting

    Events:
        @SimAIBehavior_Init

        @SimAIBehavior_OnBlocked
        @SimAIBehavior_OnCombatRoundEnd
        @SimAIBehavior_OnConversation
        @SimAIBehavior_OnDamaged
        @SimAIBehavior_OnDeath
        @SimAIBehavior_OnDisturbed
        @SimAIBehavior_OnHeartbeat
        @SimAIBehavior_OnPerception
        @SimAIBehavior_OnPhysicalAttacked
        @SimAIBehavior_OnRested
        @SimAIBehavior_OnSpawn
        @SimAIBehavior_OnSpellCastAt
        @SimAIBehavior_OnUserDefined
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_area"

const string SIMPLE_AI_LOG_TAG              = "SimpleAI";
const string SIMPLE_AI_SCRIPT_NAME          = "es_srv_simai";

const string SIMPLE_AI_NPC_BEHAVIOR_TAG     = "SimpleAINPCBehavior";

const string SIMPLE_AI_INIT_FUNCTION        = "SimpleAIInitFunction";
const string SIMPLE_AI_EVENT_FUNCTION       = "SimpleAIEventFunction_";

void SimpleAI_SetAIBehavior(object oCreature, string sBehavior);
void SimpleAI_UnsetAIBehavior(object oCreature);
void SimpleAI_SwitchAIBehavior(object oCreature, string sNewBehavior);
string SimpleAI_GetAIBehavior(object oCreature = OBJECT_SELF);

int SimpleAI_GetIsAreaEmpty();
int SimpleAI_GetTick();
void SimpleAI_SetTick(int nTick);

// @Load
void SimpleAI_Load(string sServiceScript)
{
    object oSystemDataObject = ES_Util_GetDataObject(sServiceScript), oModule = GetModule();
    string sAIBehaviorArray = ES_Util_GetResRefArray(oSystemDataObject, NWNX_UTIL_RESREF_TYPE_NSS, "ai_b_.+", FALSE);

    ES_Util_ExecuteScriptChunkForArrayElements(oSystemDataObject, sAIBehaviorArray, sServiceScript, nssFunction("SimpleAI_InitAIBehavior", "sArrayElement"), oModule);

    ES_Util_Log(SIMPLE_AI_LOG_TAG, "* Creating Event Handlers");
    ES_Util_ExecuteScriptChunkForArrayElements(oSystemDataObject, sAIBehaviorArray, sServiceScript, nssFunction("SimpleAI_CreateEventHandler", "sArrayElement"), oModule);

    ES_Util_Log(SIMPLE_AI_LOG_TAG, "* Executing Init Functions");
    ES_Util_ExecuteScriptChunkForArrayElements(oSystemDataObject, sAIBehaviorArray, sServiceScript, nssFunction("SimpleAI_ExecuteInitFunction", "sArrayElement"), oModule);

    StringArray_Clear(oSystemDataObject, sAIBehaviorArray);
}

void SimpleAI_GetInitFunction(object oDataObject, string sScriptContents)
{
    string sFunctionName = ES_Util_GetFunctionName(sScriptContents, "SimAIBehavior_Init");

    if (GetStringLength(sFunctionName))
    {
        ES_Util_Log(SIMPLE_AI_LOG_TAG, "  > Found init function '" + sFunctionName + "'");

        SetLocalString(oDataObject, SIMPLE_AI_INIT_FUNCTION, sFunctionName);
    }
}

void SimpleAI_GetEventFunction(object oBehaviorDataObject, string sScriptContents, string sFunctionDecorator, int nEvent)
{
    string sFunctionName = ES_Util_GetFunctionName(sScriptContents, sFunctionDecorator);

    if (nEvent == EVENT_SCRIPT_CREATURE_ON_DEATH)
    {
        if (GetStringLength(sFunctionName))
        {
            ES_Util_Log(SIMPLE_AI_LOG_TAG, "  > Found event function '" + sFunctionName + "' for event: " + IntToString(nEvent));

            sFunctionName += "(); ";
        }

        SetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent), sFunctionName + "SimpleAI_CleanUpOnDeath");
    }
    else
    if (GetStringLength(sFunctionName))
    {
        ES_Util_Log(SIMPLE_AI_LOG_TAG, "  > Found event function '" + sFunctionName + "' for event: " + IntToString(nEvent));

        SetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent), sFunctionName);
    }
}

void SimpleAI_InitAIBehavior(string sAIBehavior)
{
    ES_Util_Log(SIMPLE_AI_LOG_TAG, "* Initializing AI Behavior: " + sAIBehavior);

    object oSystemDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME);
    object oDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sAIBehavior);
    string sScriptContents = NWNX_Util_GetNSSContents(sAIBehavior);

    SetLocalInt(oSystemDataObject, sAIBehavior, TRUE);

    SimpleAI_GetInitFunction(oDataObject, sScriptContents);

    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnBlocked", EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnCombatRoundEnd", EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnConversation", EVENT_SCRIPT_CREATURE_ON_DIALOGUE);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnDamaged", EVENT_SCRIPT_CREATURE_ON_DAMAGED);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnDeath", EVENT_SCRIPT_CREATURE_ON_DEATH);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnDisturbed", EVENT_SCRIPT_CREATURE_ON_DISTURBED);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnHeartbeat", EVENT_SCRIPT_CREATURE_ON_HEARTBEAT);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnPerception", EVENT_SCRIPT_CREATURE_ON_NOTICE);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnPhysicalAttacked", EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnRested", EVENT_SCRIPT_CREATURE_ON_RESTED);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnSpawn", EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnSpellCastAt", EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnUserDefined", EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT);
}

void SimpleAI_CreateEventHandler(string sAIBehavior)
{
    object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sAIBehavior);

    ES_Util_Log(SIMPLE_AI_LOG_TAG, "  > Compiling Event Handler for AI Behavior: " + sAIBehavior);

    string sCases;
    int nEvent;
    for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
    {
        string sFunctionName = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent));

        if (sFunctionName != "")
        {
            sCases += nssCaseStatement(nEvent, nssFunction(sFunctionName));
            Events_SubscribeEvent_Object(sAIBehavior, nEvent, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
        }
    }

    string sEventHandler = nssInclude(sAIBehavior) + nssVoidMain(nssInt("nEvent", nssFunction("StringToInt", nssFunction("NWNX_Events_GetCurrentEvent", "", FALSE))) + nssSwitch("nEvent", sCases));

    string sResult = NWNX_Util_AddScript(sAIBehavior, sEventHandler, FALSE);

    if (sResult != "")
        ES_Util_Log(SIMPLE_AI_LOG_TAG, "    > Failed: " + sResult);
}

void SimpleAI_ExecuteInitFunction(string sAIBehavior)
{
    object oDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sAIBehavior);
    string sInitFunction = GetLocalString(oDataObject, SIMPLE_AI_INIT_FUNCTION);

    if (sInitFunction != "")
    {
        ES_Util_Log(SIMPLE_AI_LOG_TAG, "  > Executing '" + sInitFunction + "()' for: " + sAIBehavior);

        ES_Util_ExecuteScriptChunk(sAIBehavior, nssFunction(sInitFunction), GetModule());
    }
}

string SimpleAI_GetBehaviorScriptName(string sBehavior)
{
    return FindSubString(sBehavior, "ai_b_") == -1 ?  "ai_b_" + sBehavior : sBehavior;
}

void SimpleAI_CleanUpOnDeath()
{
    string sBehavior = GetLocalString(OBJECT_SELF, SIMPLE_AI_NPC_BEHAVIOR_TAG);

    if (sBehavior != "")
    {
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sBehavior);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                Events_RemoveObjectFromDispatchList(sBehavior, Events_GetEventName_Object(nEvent), OBJECT_SELF);
            }
        }
    }
}

void SimpleAI_SetAIBehavior(object oCreature, string sBehavior)
{
    if (GetObjectType(oCreature) != OBJECT_TYPE_CREATURE || GetIsPC(oCreature))
        return;

    object oSystemDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME);
    sBehavior = SimpleAI_GetBehaviorScriptName(GetStringLowerCase(sBehavior));

    if (GetLocalInt(oSystemDataObject, sBehavior))
    {
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sBehavior);

        SetLocalString(oCreature, SIMPLE_AI_NPC_BEHAVIOR_TAG, sBehavior);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                Events_SetObjectEventScript(oCreature, nEvent, FALSE);
                Events_AddObjectToDispatchList(sBehavior, Events_GetEventName_Object(nEvent), oCreature);
            }
            else
                SetEventScript(oCreature, nEvent, "");
        }
    }
    else
    {
        ES_Util_Log(SIMPLE_AI_LOG_TAG, "WARNING: Tried to set invalid behavior: '" + sBehavior + "' on: " + GetName(oCreature) + "(" + GetTag(oCreature) + ")");
    }
}

void SimpleAI_UnsetAIBehavior(object oCreature)
{
    if (GetObjectType(oCreature) != OBJECT_TYPE_CREATURE || GetIsPC(oCreature))
        return;

    string sBehavior = SimpleAI_GetAIBehavior(oCreature);

    if (sBehavior != "")
    {
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SCRIPT_NAME + sBehavior);

        DeleteLocalString(oCreature, SIMPLE_AI_NPC_BEHAVIOR_TAG);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                SetEventScript(oCreature, nEvent, "");
                Events_RemoveObjectFromDispatchList(sBehavior, Events_GetEventName_Object(nEvent), oCreature);
            }
        }
    }
}

void SimpleAI_SwitchAIBehavior(object oCreature, string sNewBehavior)
{
    string sCurrentBehavior = SimpleAI_GetAIBehavior(oCreature);

    if (sCurrentBehavior != SimpleAI_GetBehaviorScriptName(sNewBehavior))
    {
        SimpleAI_UnsetAIBehavior(oCreature);
        SimpleAI_SetAIBehavior(oCreature, sNewBehavior);
    }
}

string SimpleAI_GetAIBehavior(object oCreature = OBJECT_SELF)
{
    return GetLocalString(oCreature, SIMPLE_AI_NPC_BEHAVIOR_TAG);
}

int SimpleAI_GetIsAreaEmpty()
{
    return !NWNX_Area_GetNumberOfPlayersInArea(GetArea(OBJECT_SELF));
}

int SimpleAI_GetTick()
{
    return GetLocalInt(OBJECT_SELF, "SimpleAITick");
}

void SimpleAI_SetTick(int nTick)
{
    SetLocalInt(OBJECT_SELF, "SimpleAITick", nTick);
}

