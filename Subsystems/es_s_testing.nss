/*
    ScriptName: es_s_testing.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player Area Administration Object]
        
    Flags:
        @HotSwap        

    Description: A test subsystem
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_gui"
#include "es_srv_profiler"
#include "es_srv_mediator"
#include "nwnx_player"
#include "nwnx_area"
#include "nwnx_admin"
#include "nwnx_object"

const string TESTING_LOG_TAG        = "Testing";
const string TESTING_SCRIPT_NAME    = "es_s_testing";

// @Load
void Testing_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);

    object oPlayer = GetFirstPC();
    if (GetIsObjectValid(oPlayer))
    {
        GUI_ClearByRange(oPlayer, 1, 100);
    }
}

// @Unload
void Testing_Unload(string sSubsystemScript)
{
    ES_Core_UnsubscribeAllEvents(sSubsystemScript, TRUE);
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

        if (sMessage == "/shutdown")
        {
            NWNX_Player_PlaySound(oPlayer, "gui_dm_alert");

            Testing_ShutdownNotification(oPlayer, 15);

            SetPCChatMessage("");
        }

        if (sMessage == "/dam")
        {
            object oBadger = GetNearestObjectByTag("NW_BADGER", oPlayer);

            if (!GetIsDead(oBadger))
            {            
                int nAmount = Random(5) + 1;

                AssignCommand(oPlayer, DoDamage(oBadger, nAmount));
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE), oBadger);
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

        if (sMessage == "/badger")
        {
            object oBadger = CreateObject(OBJECT_TYPE_CREATURE, "nw_badger", GetStartingLocation());
            SetName(oBadger, "Ferocious Badger");
            NWNX_Object_SetMaxHitPoints(oBadger, 5 + Random(10));            
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(GetMaxHitPoints(oBadger)), oBadger);            

            struct ProfilerData pd = Profiler_Start("Mediator_ExecuteFunction", FALSE, TRUE);
            
            if (Mediator_ExecuteFunction("es_s_hpbar", "HealthBar_EnableHealthBar", Mediator_Object(oBadger) + Mediator_String("Yerple! Grrr!")))
            {
                 SendMessageToPC(oPlayer, "HealthBar Functionality Enabled :)");               
            }
            else
            {
                SendMessageToPC(oPlayer, "No HealthBar Functionality :(");
            }
            
            Profiler_Stop(pd);
            
            SetCommandable(FALSE, oBadger);
            
            SetPCChatMessage("");            
        }
    }
}
