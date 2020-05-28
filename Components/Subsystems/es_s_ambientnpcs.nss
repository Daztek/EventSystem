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

// @Load
void AmbientNPCs_Load(string sSubsystemScript)
{
    object oWaypoint;
    int nNth;

    while ((oWaypoint = GetObjectByTag(AMBIENT_NPCS_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        int nNumNPCs = GetLocalInt(oWaypoint, "NUM_NPCS");
        location locSpawn = GetLocation(oWaypoint);

        ES_Util_Log(AMBIENT_NPCS_LOG_TAG, "* Spawning '" + IntToString(nNumNPCs) + "' in Area: " + GetName(GetArea(oWaypoint)));

        int nNPC;
        for(nNPC = 0; nNPC < nNumNPCs; nNPC++)
        {
            object oNPC = RandomNPC_GetRandomPregeneratedNPC("AMBIENT_NPC", locSpawn);
            object oClothes = RandomArmor_GetClothes(oNPC);

            SetLocalObject(oNPC, "AMBIENT_NPC_CLOTHES", oClothes);

            SimpleAI_SetAIBehavior(oNPC, Random(2) ? "ai_b_wander" : "ai_b_sitonchair");
        }
    }
}

