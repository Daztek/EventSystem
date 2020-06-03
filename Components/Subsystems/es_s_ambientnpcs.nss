/*
    ScriptName: es_s_ambientnpcs.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that spawns randomly generated ambient NPCs
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_randarmor"
#include "es_srv_randomnpc"
#include "es_srv_simai"

const string AMBIENT_NPCS_LOG_TAG           = "AmbientNPCs";
const string AMBIENT_NPCS_SCRIPT_NAME       = "es_s_ambientnpcs";

const string AMBIENT_NPCS_NPC_TAG           = "AMBIENT_NPC";
const string AMBIENT_NPCS_SPAWN_TAG         = "AMBIENT_NPCS_SPAWN";

void AmbientNPCs_SpawnNPCs(int nAmount, string sBehavior, location locSpawn);
void AmbientNPCs_ReactMove(object oNPC);
void AmbientNPCs_ReactLookHere(object oPlayer, object oNPC);

// @Load
void AmbientNPCs_Load(string sSubsystemScript)
{
    object oWaypoint;
    int nNth;

    while ((oWaypoint = GetObjectByTag(AMBIENT_NPCS_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        int nWanderNPCAmount = GetLocalInt(oWaypoint, "ai_b_wander");
        int nSitOnChairNPCAmount = GetLocalInt(oWaypoint, "ai_b_sitonchair");
        object oArea = GetArea(oWaypoint);
        location locSpawn = GetLocation(oWaypoint);

        ES_Util_Log(AMBIENT_NPCS_LOG_TAG, "* Spawning '" + IntToString(nWanderNPCAmount + nSitOnChairNPCAmount) + "' Ambient NPCs in Area: " + GetName(oArea));

        AmbientNPCs_SpawnNPCs(nWanderNPCAmount, "ai_b_wander", locSpawn);
        AmbientNPCs_SpawnNPCs(nSitOnChairNPCAmount, "ai_b_sitonchair", locSpawn);

        SetLocalInt(oArea, AMBIENT_NPCS_SPAWN_TAG, TRUE);
    }

    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_QUICKCHAT_BEFORE");
}

// @EventHandler
void AmbientNPCs_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_QUICKCHAT_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oArea = GetArea(oPlayer);

        if (!GetLocalInt(oArea, AMBIENT_NPCS_SPAWN_TAG))
            return;

        int nVoiceChatID = Events_GetEventData_NWNX_Int("QUICKCHAT_COMMAND");

        switch (nVoiceChatID)
        {
            case VOICE_CHAT_MOVEOVER:
            {
                object oNPC = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, PLAYER_CHAR_NOT_PC, oPlayer, 1, CREATURE_TYPE_IS_ALIVE, TRUE);

                if (GetIsObjectValid(oNPC) && GetTag(oNPC) == AMBIENT_NPCS_NPC_TAG)
                {
                    if (GetCurrentAction(oNPC) == ACTION_SIT)
                        DelayCommand(1.0f, AmbientNPCs_ReactMove(oNPC));
                }

                break;
            }

            case VOICE_CHAT_HELLO:
            case VOICE_CHAT_GOODBYE:
            {
                location locSelf = ES_Util_GetAheadLocation(oPlayer, 2.0f);
                object oNPC = GetFirstObjectInShape(SHAPE_SPHERE, 4.0f, locSelf);

                while (GetIsObjectValid(oNPC))
                {
                    if (GetTag(oNPC) == AMBIENT_NPCS_NPC_TAG)
                    {
                        if (!Random(3))
                            DelayCommand(1.0f + (Random(16) / 10.0f), SimpleAI_PlayVoiceChat(nVoiceChatID, oNPC));
                    }

                    oNPC = GetNextObjectInShape(SHAPE_SPHERE, 4.0f, locSelf);
                }

                break;
            }

            case VOICE_CHAT_LOOKHERE:
            {

                location locSelf = GetLocation(oPlayer);
                object oNPC = GetFirstObjectInShape(SHAPE_SPHERE, 5.0f, locSelf);

                while (GetIsObjectValid(oNPC))
                {
                    if (GetTag(oNPC) == AMBIENT_NPCS_NPC_TAG)
                    {
                        if (!Random(4))
                        {
                            DelayCommand(1.0f + (Random(16) / 10.0f), AmbientNPCs_ReactLookHere(oPlayer, oNPC));
                        }
                    }

                    oNPC = GetNextObjectInShape(SHAPE_SPHERE, 5.0f, locSelf);
                }
                break;
            }
        }
    }
}

void AmbientNPCs_SpawnNPCs(int nAmount, string sBehavior, location locSpawn)
{
    int nNPC;
    for(nNPC = 0; nNPC < nAmount; nNPC++)
    {
        object oNPC = RandomNPC_GetRandomPregeneratedNPC(AMBIENT_NPCS_NPC_TAG, locSpawn);
        object oClothes = RandomArmor_GetClothes(oNPC);

        SetLocalObject(oNPC, "AMBIENT_NPC_CLOTHES", oClothes);
        SimpleAI_SetAIBehavior(oNPC, sBehavior);
        SetPlotFlag(oNPC, TRUE);
    }
}

void AmbientNPCs_ReactMove(object oNPC)
{
    if (GetLocalInt(oNPC, "AmbientNPC_Annoyed"))
        SimpleAI_PlayVoiceChat(VOICE_CHAT_THREATEN, oNPC);
    else
    {
        if (!Random(3))
        {
            SetLocalInt(oNPC, "AmbientNPC_Annoyed", TRUE);
            SimpleAI_PlayVoiceChat(VOICE_CHAT_CANTDO, oNPC);
            DelayCommand(15.0f, DeleteLocalInt(oNPC, "AmbientNPC_Annoyed"));
        }
        else
        {
            AssignCommand(oNPC, ClearAllActions());
            SimpleAI_PlayVoiceChat(VOICE_CHAT_CANDO, oNPC);
        }
    }
}

void AmbientNPCs_ReactLookHere(object oPlayer, object oNPC)
{
    if (GetLocalInt(oNPC, "AmbientNPC_RecentlyLooked"))
        SimpleAI_PlayVoiceChat(VOICE_CHAT_NO, oNPC);
    else
    {
        SetLocalInt(oNPC, "AmbientNPC_RecentlyLooked", TRUE);
        DelayCommand(60.0f, DeleteLocalInt(oNPC, "AmbientNPC_RecentlyLooked"));

        SimpleAI_PlayVoiceChat(VOICE_CHAT_YES, oNPC);
        AssignCommand(oNPC, ClearAllActions());
        AssignCommand(oNPC, ActionForceMoveToObject(oPlayer, FALSE, 1.0f, 30.0f));
        AssignCommand(oNPC, ActionWait(1.0f + (Random(50) / 10.0f)));
    }
}

