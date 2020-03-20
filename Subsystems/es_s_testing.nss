/*
    ScriptName: es_s_testing.nss
    Created by: Daz

    Description: A test subsystem

    Flags:
        @HotSwap
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_gui"
#include "es_srv_profiler"

#include "nwnx_player"

const string TESTING_LOG_TAG        = "Testing";
const string TESTING_SCRIPT_NAME    = "es_s_testing";

// @Load
void Testing_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT);
}

// @Unload
void Testing_Unload(string sSubsystemScript)
{
    ES_Core_UnsubscribeAllEvents(sSubsystemScript);
}

void Testing_ShutdownNotification(object oPlayer, int nCountdown)
{
    if (!nCountdown) return;
    
    string sMessage = "Server shutting down in '" + IntToString(nCountdown) + "' seconds.";
    int nLength = GUI_CalculateStringLength(sMessage);
    
    if (nCountdown <= 5)
    {       
        PostString(oPlayer, sMessage, 2 - (nLength / 2), 1, SCREEN_ANCHOR_CENTER, 1.1f, 0xFF0000FF, 0xFF0000FF, 1); 
        GUI_DrawWindow(oPlayer, 50, SCREEN_ANCHOR_CENTER, 1 - (nLength / 2), 0, nLength, 1, 1.1f);        

        NWNX_Player_PlaySound(oPlayer, "as_cv_bell2");     
    }
    else
    {
        PostString(oPlayer, sMessage, 2, 1, SCREEN_ANCHOR_TOP_LEFT, 1.1f, 0xFFFFFFFF, 0xFFFFFFFF, 1);
        GUI_DrawWindow(oPlayer, 50, SCREEN_ANCHOR_TOP_LEFT, 1, 0, nLength, 1, 1.1f);        
    }    
    
    DelayCommand(1.0f, Testing_ShutdownNotification(oPlayer, --nCountdown));
}

// @EventHandler
void Testing_EventHandler(string sSubsystemScript, string sEvent)
{
    struct ProfilerData pd = Profiler_Start("Testing", FALSE, TRUE);
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_PLAYER_CHAT)
    {
        object oPlayer = GetPCChatSpeaker();
        string sMessage = GetPCChatMessage();

        NWNX_Player_PlaySound(oPlayer, "gui_dm_alert");
        
        Testing_ShutdownNotification(oPlayer, 15);

        SetPCChatMessage("");        
    }
    Profiler_Stop(pd);
}
