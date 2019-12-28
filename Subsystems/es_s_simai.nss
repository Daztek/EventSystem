/*
    ScriptName: es_s_simai.nss
    Created by: Daz

    Description: A subsystem that allows the creation of simple AI routines through scripting

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
#include "es_s_randomarmor"

#include "nwnx_area"

const string SIMPLE_AI_SYSTEM_TAG           = "SimpleAI";

const string SIMPLE_AI_NPC_BEHAVIOR_TAG     = "SimpleAINPCBehavior";

const string SIMPLE_AI_EVENT_HANDLER        = "SimpleAIEventHandler";
const string SIMPLE_AI_INIT_FUNCTION        = "SimpleAIInitFunction";
const string SIMPLE_AI_EVENT_FUNCTION       = "SimpleAIEventFunction_";

void SimpleAI_SetAIBehavior(object oCreature, string sBehavior);
void SimpleAI_UnsetAIBehavior(object oCreature);
void SimpleAI_SwitchAIBehavior(object oCreature, string sNewBehavior);
string SimpleAI_GetAIBehavior(object oCreature = OBJECT_SELF);

int SimpleAI_GetIsAreaEmpty();
int SimpleAI_GetTick();
void SimpleAI_SetTick(int nTick);

void SimpleAI_InitialSetup(int bEquipClothes = TRUE, int bCutsceneGhost = TRUE);

// @EventSystem_Init
void SimpleAI_Init(string sEventHandlerScript)
{
    object oSystemDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG), oModule = GetModule();
    string sAIBehaviorList = ES_Util_GetResRefList(NWNX_UTIL_RESREF_TYPE_NSS, "ai_b_.+", FALSE);

    ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "* Found AI Behaviors: " + sAIBehaviorList);

    ES_Util_ExecuteScriptChunk("es_s_simai", "SimpleAI_CheckAIBehaviorScripts(\"" + sAIBehaviorList + "\");", oModule);
    ES_Util_ExecuteScriptChunk("es_s_simai", "SimpleAI_CreateEventHandlers(\"" + sAIBehaviorList + "\");", oModule);
    ES_Util_ExecuteScriptChunk("es_s_simai", "SimpleAI_ExecuteInitFunctions(\"" + sAIBehaviorList + "\");", oModule);
}

void SimpleAI_GetInitFunction(object oDataObject, string sScriptContents)
{
    string sFunctionName = ES_Util_GetFunctionName(sScriptContents, "SimAIBehavior_Init");

    if (GetStringLength(sFunctionName))
    {
        ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "  > Found init function '" + sFunctionName + "'");

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
            ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "  > Found event function '" + sFunctionName + "' for event: " + IntToString(nEvent));

            sFunctionName += "(); ";
        }

        SetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent), sFunctionName + "SimpleAI_CleanUpOnDeath");
    }
    else
    if (GetStringLength(sFunctionName))
    {
        ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "  > Found event function '" + sFunctionName + "' for event: " + IntToString(nEvent));

        SetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent), sFunctionName);
    }
}

void SimpleAI_InitAIBehavior(string sAIBehavior)
{
    ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "* Initializing AI Behavior: " + sAIBehavior);

    object oDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sAIBehavior);
    string sScriptContents = NWNX_Util_GetNSSContents(sAIBehavior);

    SetLocalString(oDataObject, SIMPLE_AI_EVENT_HANDLER, "ai_e_" + GetSubString(sAIBehavior, 5, GetStringLength(sAIBehavior) - 5));

    SimpleAI_GetInitFunction(oDataObject, sScriptContents);

    SimpleAI_GetEventFunction(oDataObject, sScriptContents, "SimAIBehavior_OnBlocked", EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR);
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

void SimpleAI_CheckAIBehaviorScripts(string sAIBehaviorList)
{
    object oSystemDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG), oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sAIBehaviorList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sAIBehavior = GetTokenByPosition(sAIBehaviorList, ";", nCount);

        SetLocalInt(oSystemDataObject, sAIBehavior, TRUE);

        ES_Util_ExecuteScriptChunk("es_s_simai", "SimpleAI_InitAIBehavior(\"" + sAIBehavior + "\");", oModule);
    }
}

string SimpleAI_GetEventCase(int nEvent, string sFunctionName, string sEventHandlerScript)
{
    string sCase;

    if (sFunctionName != "")
    {
        sCase += "case " + IntToString(nEvent) + ": { " + sFunctionName + "(); break; } ";
        ES_Core_SubscribeEvent_Object(sEventHandlerScript, nEvent, ES_CORE_EVENT_FLAG_DEFAULT, TRUE);
    }

    return sCase;
}

void SimpleAI_CompileEventHandler(string sAIBehavior)
{
    object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sAIBehavior);
    string sEventHandlerScript = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_HANDLER);

    ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "  > Compiling event handler '" + sEventHandlerScript + "' for AI Behavior: " + sAIBehavior);

    string sInclude = "#" + "include \"" + sAIBehavior + "\" ";
    string sEventHandler = sInclude + "void main() { int nEvent = StringToInt(NWNX_Events_GetCurrentEvent()); switch (nEvent) { ";

    int nEvent;
    for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
    {
        string sFunctionName = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent));

        sEventHandler += SimpleAI_GetEventCase(nEvent, sFunctionName, sEventHandlerScript);
    }

    sEventHandler += " } }";

    string sResult = NWNX_Util_AddScript(sEventHandlerScript, sEventHandler, FALSE);

    if (sResult != "")
        ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "    > Failed: " + sResult);
}

void SimpleAI_CreateEventHandlers(string sAIBehaviorList)
{
    ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "* Creating Event Handlers");

    object oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sAIBehaviorList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sAIBehavior = GetTokenByPosition(sAIBehaviorList, ";", nCount);

        ES_Util_ExecuteScriptChunk("es_s_simai", "SimpleAI_CompileEventHandler(\"" + sAIBehavior + "\");", oModule);
    }
}

void SimpleAI_ExecuteInitFunctions(string sAIBehaviorList)
{
    ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "* Executing Init Functions");

    object oModule = GetModule();
    int nCount, nNumTokens = GetNumberTokens(sAIBehaviorList, ";");

    for (nCount = 0; nCount < nNumTokens; nCount++)
    {
        string sAIBehavior = GetTokenByPosition(sAIBehaviorList, ";", nCount);
        object oDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sAIBehavior);
        string sInitFunction = GetLocalString(oDataObject, SIMPLE_AI_INIT_FUNCTION);

        if (sInitFunction != "")
        {
            ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "  > Executing '" + sInitFunction + "()' for: " + sAIBehavior);

            ES_Util_ExecuteScriptChunk(sAIBehavior, sInitFunction + "();", oModule);
        }
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
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sBehavior);
        string sEventHandlerScript = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_HANDLER);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                NWNX_Events_RemoveObjectFromDispatchList(ES_Core_GetEventName_Object(nEvent), sEventHandlerScript, OBJECT_SELF);
            }
        }
    }
}

void SimpleAI_SetAIBehavior(object oCreature, string sBehavior)
{
    if (GetObjectType(oCreature) != OBJECT_TYPE_CREATURE || GetIsPC(oCreature))
        return;

    object oSystemDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG);
    string sBehaviorScriptName = SimpleAI_GetBehaviorScriptName(GetStringLowerCase(sBehavior));

    if (GetLocalInt(oSystemDataObject, sBehaviorScriptName))
    {
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sBehaviorScriptName);
        string sEventHandlerScript = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_HANDLER);

        SetLocalString(oCreature, SIMPLE_AI_NPC_BEHAVIOR_TAG, sBehaviorScriptName);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                ES_Core_SetObjectEventScript(oCreature, nEvent, FALSE);
                NWNX_Events_AddObjectToDispatchList(ES_Core_GetEventName_Object(nEvent), sEventHandlerScript, oCreature);
            }
            else
                SetEventScript(oCreature, nEvent, "");
        }
    }
    else
    {
        ES_Util_Log(SIMPLE_AI_SYSTEM_TAG, "WARNING: Tried to set invalid behavior: '" + sBehavior + "' on: " + GetName(oCreature) + "(" + GetTag(oCreature) + ")");
    }
}

void SimpleAI_UnsetAIBehavior(object oCreature)
{
    if (GetObjectType(oCreature) != OBJECT_TYPE_CREATURE || GetIsPC(oCreature))
        return;

    string sBehavior = SimpleAI_GetAIBehavior(oCreature);

    if (sBehavior != "")
    {
        object oBehaviorDataObject = ES_Util_GetDataObject(SIMPLE_AI_SYSTEM_TAG + sBehavior);
        string sEventHandlerScript = GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_HANDLER);

        DeleteLocalString(oCreature, SIMPLE_AI_NPC_BEHAVIOR_TAG);

        int nEvent;
        for (nEvent = EVENT_SCRIPT_CREATURE_ON_HEARTBEAT; nEvent <= EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR; nEvent++)
        {
            if (GetLocalString(oBehaviorDataObject, SIMPLE_AI_EVENT_FUNCTION + IntToString(nEvent)) != "")
            {
                SetEventScript(oCreature, nEvent, "");
                NWNX_Events_RemoveObjectFromDispatchList(ES_Core_GetEventName_Object(nEvent), sEventHandlerScript, oCreature);
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

void SimpleAI_InitialSetup(int bEquipClothes = TRUE, int bCutsceneGhost = TRUE)
{
    if (bEquipClothes)
        ActionEquipItem(RandomArmor_GetClothes(OBJECT_SELF), INVENTORY_SLOT_CHEST);

    if (bCutsceneGhost)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, ExtraordinaryEffect(EffectCutsceneGhost()), OBJECT_SELF);
}

