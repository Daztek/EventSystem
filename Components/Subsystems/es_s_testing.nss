/*
    ScriptName: es_s_testing.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player Administration Object]

    Flags:
        @HotSwap

    Description: A test subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_profiler"
#include "es_srv_gui"
#include "es_srv_mediator"
#include "nwnx_player"
#include "nwnx_admin"
#include "nwnx_object"

#include "x0_i0_position"

const string TESTING_LOG_TAG        = "Testing";
const string TESTING_SCRIPT_NAME    = "es_s_testing";

// @Load
void Testing_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
    //Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_BEFORE");
    //Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_KEYBOARD_BEFORE");
   
    object oPlayer = GetFirstPC();
    if (GetIsObjectValid(oPlayer))
    {        
        GUI_ClearByRange(oPlayer, 1, 100); 
    }
}

// @Unload
void Testing_Unload(string sSubsystemScript)
{
    Events_UnsubscribeAllEvents(sSubsystemScript, TRUE);
}

void Testing_ShutdownNotification(object oPlayer, int nCountdown)
{
    if (nCountdown)
    {
        string sMessage = "Server shutting down in '" + IntToString(nCountdown) + "' second" + (nCountdown == 1 ? "" : "s") + ".";

        GUI_DrawNotification(oPlayer, sMessage, 1, 0, 1, nCountdown <= 5 ? GUI_COLOR_RED: GUI_COLOR_WHITE, 1.1f);
        
        DelayCommand(1.0f, Testing_ShutdownNotification(oPlayer, --nCountdown));
    }
    else
    {
        NWNX_Administration_ShutdownServer();
    }
}

void DoDamage(object oCreature, int nAmount)
{
    effect eDamage = EffectDamage(nAmount);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDamage, oCreature);
}

// @EventHandler
void Testing_EventHandler(string sSubsystemScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT)
    {
        object oPlayer = GetPCChatSpeaker();
        string sMessage = GetPCChatMessage(); 
        
        if (sMessage == "/tl")
        {
            if (GUI_GetIsPlayerInputLocked(oPlayer))
            {
                GUI_ClearByRange(oPlayer, 1, 500);
                GUI_UnlockPlayerInput(oPlayer);
            }
            else
            {
                GUI_LockPlayerInput(oPlayer);           
            }
            
            SetPCChatMessage("");            
        }
        
        if (sMessage == "/shutdown")
        {
            NWNX_Player_PlaySound(oPlayer, "gui_dm_alert");

            Testing_ShutdownNotification(oPlayer, 15);

            SetPCChatMessage("");
        }

        if (sMessage == "/dc")
        {
            object oCreature = GetNearestObjectByTag("NW_KOBOLD001", oPlayer);

            if (!GetIsDead(oCreature))
            {
                int nAmount = Random(5) + 1;

                AssignCommand(oPlayer, DoDamage(oCreature, nAmount));
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE), oCreature);
            }
            SetPCChatMessage("");
        }

        if (sMessage == "/ds")
        {
            int nAmount = 1;

            AssignCommand(oPlayer, DoDamage(oPlayer, nAmount));
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE), oPlayer);

            SetPCChatMessage("");
        }

        if (sMessage == "/npc")
        {
            object oCreature = CreateObject(OBJECT_TYPE_CREATURE, "nw_kobold001", GetStartingLocation());

            SetName(oCreature, "Angery Kobold");
            SetCommandable(FALSE, oCreature);

            NWNX_Object_SetMaxHitPoints(oCreature, 5 + Random(10));

            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(GetMaxHitPoints(oCreature)), oCreature);

            struct ProfilerData pd = Profiler_Start("Mediator_ExecuteFunction");

            //Mediator_ExecuteFunction("es_s_hpbar", "HealthBar_EnableHealthBar", Mediator_Object(oCreature));

            Mediator_ExecuteFunction("es_s_hpbar", "HealthBar_SetInfoBlurb", Mediator_Object(oCreature) + Mediator_String("Very ANGERY at YOU."));
            
            //Mediator_ExecuteFunction("es_s_dumplocals", "DumpLocals_DumpLocals", Mediator_Object(oPlayer) + Mediator_Int(0) + Mediator_Object(oCreature));

            Profiler_Stop(pd);

            SetPCChatMessage("");
        }       
    } 
}
