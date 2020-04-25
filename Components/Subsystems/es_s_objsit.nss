/*
    ScriptName: es_s_objsit.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that allows players to sit on objects
                 with the following tag: OBJSIT_SINGLE
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_simdialog"
#include "es_srv_toolbox"

const string OBJSIT_LOG_TAG                 = "ObjectSit";
const string OBJSIT_SCRIPT_NAME             = "es_s_objsit";

const string OBJSIT_SINGLE_SPAWN_TAG        = "OBJSIT_SINGLE";

void ObjectSit_SpawnSittingObjects(string sSubsystemScript);

// @Load
void ObjectSit_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_USED, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, TRUE);

    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);
    SimpleDialog_AddPage(oConversation, "Sitting Action Menu.", TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Rotate clockwise]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Rotate counter-clockwise]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Do nothing]"));

    ObjectSit_SpawnSittingObjects(sSubsystemScript);
}

// @EventHandler
void ObjectSit_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE)
    {
        SimpleDialog_SetOverrideText("While sitting on the " + GetStringLowerCase(GetName(OBJECT_SELF)) + " you...");
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oSittingObject = OBJECT_SELF;
        object oPlayer = Events_GetEventData_NWNX_Object("PLAYER");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        if (GetSittingCreature(oSittingObject) != oPlayer)
        {
            SimpleDialog_EndConversation(oPlayer);
            return;
        }

        switch (nOption)
        {
            case 1:
            case 2:
                NWNX_Object_SetFacing(oSittingObject, GetFacing(oSittingObject) + (nOption == 1 ? -20.0f : 20.0f));
                break;

            case 3:
                SimpleDialog_EndConversation(oPlayer);
                break;
        }
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_PLACEABLE_ON_USED:
            {
                object oSittingObject = OBJECT_SELF;
                object oPlayer = GetLastUsedBy();

                if (!GetIsObjectValid(GetSittingCreature(oSittingObject)))
                {
                    SimpleDialog_StartConversation(oPlayer, oSittingObject, sSubsystemScript);
                    AssignCommand(oPlayer, ActionSit(oSittingObject));
                }

                break;
            }
        }
    }
}

void ObjectSit_SpawnSittingObjects(string sSubsystemScript)
{
    struct Toolbox_PlaceableData pd;
    pd.nModel = 179;
    pd.sTag = "OBJSIT_SINGLE_CHAIR";
    pd.sName = "Chair";
    pd.sDescription = "It is a simple chair but the grace of its lines speaks to the quality of its craftmanship.";
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnUsed = TRUE;
    pd.fFacingAdjustment = 180.0f;

    string sSerializedChair = Toolbox_GeneratePlaceable(pd);

    int nNth = 0;
    object oSpawnpoint;
    while ((oSpawnpoint = GetObjectByTag(OBJSIT_SINGLE_SPAWN_TAG, nNth++)) != OBJECT_INVALID)
    {
        object oSittingObject = Toolbox_CreatePlaceable(sSerializedChair, GetLocation(oSpawnpoint));

        Events_AddObjectToAllDispatchLists(sSubsystemScript, oSittingObject);
    }

    ES_Util_Log(OBJSIT_LOG_TAG, "* Created '" + IntToString(--nNth) + "' Sitting Objects");
}

