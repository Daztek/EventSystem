/*
    ScriptName: es_s_closedoor.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: An EventSystem Subsystem that automatically closes doors.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"

const string CLOSEDOOR_LOG_TAG      = "CloseDoor";
const string CLOSEDOOR_SCRIPT_NAME  = "es_s_closedoor";

const float CLOSEDOOR_CLOSE_DELAY   = 7.5f;

// @Load
void CloseDoor_Load(string sComponentScript)
{
    Events_SubscribeEvent_Object(sComponentScript, EVENT_SCRIPT_DOOR_ON_OPEN, EVENTS_EVENT_FLAG_AFTER, TRUE);

    object oDoor;
    int nNth = 1;
    string sDoorOnOpenEvent = Events_GetEventName_Object(EVENT_SCRIPT_DOOR_ON_OPEN, EVENTS_EVENT_FLAG_AFTER);

    while ((oDoor = NWNX_Util_GetLastCreatedObject(10, nNth++)) != OBJECT_INVALID)
    {
        if (NWNX_Object_GetDoorHasVisibleModel(oDoor))
        {
            Events_SetObjectEventScript(oDoor, EVENT_SCRIPT_DOOR_ON_OPEN);
            Events_AddObjectToDispatchList(sComponentScript, sDoorOnOpenEvent, oDoor);
        }
    }
}

// @EventHandler
void CloseDoor_EventHandler(string sComponentScript, string sEvent)
{
    object oDoor = OBJECT_SELF;

    ClearAllActions();
    ActionWait(CLOSEDOOR_CLOSE_DELAY);
    ActionCloseDoor(oDoor);
}

