/*
    ScriptName: es_s_intchair.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_srv_toolbox"
#include "es_srv_simdialog"

const string INTCHAIR_LOG_TAG           = "InteractiveChair";
const string INTCHAIRT_SCRIPT_NAME      = "es_s_intchair";

const string INTCHAIR_WAYPOINT_TAG      = "INTCHAIR_SPAWN";

void InteractiveChair_SpawnChairs(string sSubsystemScript);

// @Load
void InteractiveChair_Load(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_USED, ES_CORE_EVENT_FLAG_DEFAULT, TRUE);
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER, ES_CORE_EVENT_FLAG_DEFAULT, TRUE);
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT, ES_CORE_EVENT_FLAG_DEFAULT, TRUE);

    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);

    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);
    SimpleDialog_AddPage(oConversation, "Sitting Action Menu.", TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Sit]"));

    InteractiveChair_SpawnChairs(sSubsystemScript);
}

// @EventHandler
void InteractiveChair_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        int nOption = ES_Util_GetEventData_NWNX_Int("OPTION");
        object oPlayer = ES_Util_GetEventData_NWNX_Object("PLAYER");
        object oChair = GetLocalObject(oPlayer, "INTCHAIR_CURRENT_CHAIR");

        if (nOption == 1)
        {
            AssignCommand(oPlayer, ActionSit(oChair));
        }
    }
    else
    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_PLACEABLE_ON_USED:
        {
            object oSelf = OBJECT_SELF;
            object oPlayer = GetLastUsedBy();

            if (!GetIsObjectValid(GetSittingCreature(oSelf)))
            {
                //SimpleDialog_StartConversation(oPlayer, oSelf, sSubsystemScript);
                AssignCommand(oPlayer, ActionSit(oSelf));
            }

            break;
        }

        case EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER:
        {
            object oTrigger = OBJECT_SELF;
            object oPlayer = GetEnteringObject();
            object oChair = GetLocalObject(oTrigger, "INTCHAIR_CHAIR");

            SetLocalObject(oPlayer, "INTCHAIR_CURRENT_CHAIR", oChair);

            NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oPlayer);

            SimpleDialog_StartConversation(oPlayer, oPlayer, sSubsystemScript);

            break;
        }

        case EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT:
        {
            object oTrigger = OBJECT_SELF;
            object oPlayer = GetExitingObject();

            DeleteLocalObject(oPlayer, "INTCHAIR_CURRENT_CHAIR");

            SimpleDialog_AbortConversation(oPlayer);
            NWNX_Events_RemoveObjectFromDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oPlayer);

            break;
        }
    }
}

void InteractiveChair_SpawnChairs(string sSubsystemScript)
{
    int nNth = 0;
    object oSpawnpoint;

    struct Toolbox_CircleTriggerData ctd;
    ctd.sTag = "INTCHAIR_TRIGGER";
    ctd.fRadius = 1.25f;
    ctd.nPoints = 12;
    ctd.scriptOnEnter = TRUE;
    ctd.scriptOnExit = TRUE;
    //ctd.scriptOnClick = TRUE;

    struct Toolbox_PlaceableData pd;
    pd.nModel = 179;
    pd.sTag = "INTCHAIR_CHAIR";
    pd.sName = "Chair";
    pd.sDescription = "It is a simple chair but the grace of its lines speaks to the quality of its craftmanship.";
    pd.bPlot = TRUE;
    //pd.bUseable = TRUE;
    //pd.scriptOnUsed = TRUE;

    string sSerializedChair = Toolbox_GeneratePlaceable(pd);

    string sPlaceableOnUsed = ES_Core_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_USED);
    string sTriggerOnEnter = ES_Core_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER);
    string sTriggerOnExit = ES_Core_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT);

    while ((oSpawnpoint = GetObjectByTag(INTCHAIR_WAYPOINT_TAG, nNth++)) != OBJECT_INVALID)
    {
        location locSpawn = GetLocation(oSpawnpoint);
        object oTrigger = Toolbox_CreateCircleTrigger(ctd, locSpawn);
        object oChair = Toolbox_CreatePlaceable(sSerializedChair, locSpawn);

        SetLocalObject(oTrigger, GetTag(oChair), oChair);
        SetLocalObject(oChair, GetTag(oTrigger), oTrigger);

        NWNX_Events_AddObjectToDispatchList(sPlaceableOnUsed, sSubsystemScript, oChair);
        NWNX_Events_AddObjectToDispatchList(sTriggerOnEnter, sSubsystemScript, oTrigger);
        NWNX_Events_AddObjectToDispatchList(sTriggerOnExit, sSubsystemScript, oTrigger);
    }
}

