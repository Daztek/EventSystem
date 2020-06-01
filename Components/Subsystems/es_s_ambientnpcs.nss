/*
    ScriptName: es_s_ambientnpcs.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that spawns randomly generated ambient NPCs
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_randarmor"
#include "es_srv_randomnpc"
#include "es_srv_simai"

const string AMBIENT_NPCS_LOG_TAG         = "AmbientNPCs";
const string AMBIENT_NPCS_SCRIPT_NAME     = "es_s_ambientnpcs";

const string AMBIENT_NPCS_SPAWN_TAG       = "AMBIENT_NPCS_SPAWN";

void AmbientNPCs_SpawnNPCs(int nAmount, string sBehavior, location locSpawn);

// @Load
void AmbientNPCs_Load(string sSubsystemScript)
{
    object oWaypoint;
    int nNth;

    while ((oWaypoint = GetObjectByTag(AMBIENT_NPCS_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        int nWanderNPCAmount = GetLocalInt(oWaypoint, "ai_b_wander");
        int nSitOnChairNPCAmount = GetLocalInt(oWaypoint, "ai_b_sitonchair");
        location locSpawn = GetLocation(oWaypoint);

        ES_Util_Log(AMBIENT_NPCS_LOG_TAG, "* Spawning '" + IntToString(nWanderNPCAmount + nSitOnChairNPCAmount) + "' Ambient NPCs in Area: " + GetName(GetArea(oWaypoint)));

        AmbientNPCs_SpawnNPCs(nWanderNPCAmount, "ai_b_wander", locSpawn);
        AmbientNPCs_SpawnNPCs(nSitOnChairNPCAmount, "ai_b_sitonchair", locSpawn);
    }
}

void AmbientNPCs_SpawnNPCs(int nAmount, string sBehavior, location locSpawn)
{
    int nNPC;
    for(nNPC = 0; nNPC < nAmount; nNPC++)
    {
        object oNPC = RandomNPC_GetRandomPregeneratedNPC("AMBIENT_NPC", locSpawn);
        object oClothes = RandomArmor_GetClothes(oNPC);

        SetLocalObject(oNPC, "AMBIENT_NPC_CLOTHES", oClothes);
        SimpleAI_SetAIBehavior(oNPC, sBehavior);
        SetPlotFlag(oNPC, TRUE);
    }
}

