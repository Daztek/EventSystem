/*
    ScriptName: es_srv_instance.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Area]

    Description: An EventSystem Service that handles area instance management
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_area"

const string INSTANCE_LOG_TAG                           = "Instance";
const string INSTANCE_SCRIPT_NAME                       = "es_srv_instance";

const string INSTANCE_TAG_PREFIX                        = "INS_";

const string INSTANCE_EVENT_CREATED                     = "INSTANCE_EVENT_CREATED";
const string INSTANCE_EVENT_DESTROYED                   = "INSTANCE_EVENT_DESTROYED";

const int INSTANCE_DESTROY_TYPE_NEVER                   = 0;
const int INSTANCE_DESTROY_TYPE_EMPTY                   = 1;
const int INSTANCE_DESTROY_TYPE_EMPTY_DELAY             = 2;
const int INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT        = 3;
const int INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT_DELAY  = 4;

struct InstanceData
{
    string sName;
    string sTag;
    object oOwner;

    int nDestroyType;
    float fDestroyDelay;
    location locExit;
};

void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent, int bDispatchListMode = FALSE);
void Instance_Register(string sAreaTag, string sAreaResRef);
void Instance_Create(string sAreaResRef, struct InstanceData id);
location Instance_GetExitLocation(object oInstance);

void Instance_Destroy(object oInstance);
void Instance_CheckDestroy_ClientExit(object oPlayer);
void Instance_CheckDestroy_AreaExit(object oPlayer, object oInstance);

void Instance_SendMessageToOwner(object oInstance, string sMessage, int bFloating = TRUE);
void Instance_SendMessageToInstance(object oInstance, string sMessage, int bFloating = TRUE);

// @Load
void Instance_Load(string sServiceScript)
{
    object oDataObject = ES_Util_GetDataObject(sServiceScript);

    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER, TRUE);
}

// @EventHandler
void Instance_EventHandler(string sServiceScript, string sEvent)
{
    object oDataObject = ES_Util_GetDataObject(sServiceScript);

    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
        {
            Instance_CheckDestroy_ClientExit(GetExitingObject());
        }

        case EVENT_SCRIPT_AREA_ON_EXIT:
        {
            Instance_CheckDestroy_AreaExit(GetExitingObject(), OBJECT_SELF);
            break;
        }
    }
}

// *** INTERNAL FUNCTIONS
void Instance_INTERNAL_Destroy(object oInstance)
{
    string sInstanceName = GetName(oInstance);
    int nDestroyed = DestroyArea(oInstance);

    ES_Util_Log(INSTANCE_LOG_TAG, "DEBUG: Destroyed '" + sInstanceName + "' Instance: " + IntToString(nDestroyed));
}

void Instance_INTERNAL_InstanceDispatchList_Add(object oInstance)
{
    string sAreaOnExit = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER);
    Events_AddObjectToDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnExit, oInstance);
}

void Instance_INTERNAL_InstanceDispatchList_Remove(object oInstance)
{
    string sAreaOnExit = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER);
    Events_RemoveObjectFromDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnExit, oInstance);
}

// ***

void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent, int bDispatchListMode = FALSE)
{
    Events_SubscribeEvent(sSubsystemScript, sInstanceEvent, bDispatchListMode);
}

void Instance_Register(string sAreaTag, string sAreaResRef)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "InstanceBlueprints", sAreaResRef) == -1)
    {
        StringArray_Insert(oDataObject, "InstanceBlueprints", sAreaResRef);

        ES_Util_Log(INSTANCE_LOG_TAG, "* Registered Instance: " + sAreaResRef);

        object oBlueprintArea = GetObjectByTag(sAreaTag);

        if (GetIsObjectValid(oBlueprintArea))
        {
            int nDestroy = DestroyArea(oBlueprintArea);

            ES_Util_Log(INSTANCE_LOG_TAG, "  > Destroyed Blueprint: " + IntToString(nDestroy));
        }
    }
}

void Instance_Create(string sAreaResRef, struct InstanceData id)
{
    if (!GetIsObjectValid(id.oOwner) || !GetIsPC(id.oOwner))
        return;

    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "InstanceBlueprints", sAreaResRef) != -1)
    {
        object oInstance = CreateArea(sAreaResRef, INSTANCE_TAG_PREFIX + id.sTag, id.sName);

        if (GetIsObjectValid(oInstance))
        {
            Events_SetAreaEventScripts(oInstance);

            ObjectArray_Insert(oDataObject, "Instances_" + GetObjectUUID(id.oOwner), oInstance);

            SetLocalObject(oInstance, "InstanceOwner", id.oOwner);
            SetLocalInt(oInstance, "InstanceDestroyType", id.nDestroyType);
            SetLocalFloat(oInstance, "InstanceDestroyDelay", id.fDestroyDelay);
            SetLocalLocation(oInstance, "InstanceExitLocation", id.locExit);

            Instance_INTERNAL_InstanceDispatchList_Add(oInstance);

            Events_SignalEvent(INSTANCE_EVENT_CREATED, oInstance);
        }
    }
}

location Instance_GetExitLocation(object oInstance)
{
    location locExit = GetLocalLocation(oInstance, "InstanceExitLocation");
    object oExitArea = GetAreaFromLocation(locExit);

    if (!GetIsObjectValid(oExitArea) || oExitArea == oInstance)
        locExit = GetStartingLocation();

    return locExit;
}

void Instance_Destroy(object oInstance)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);
    string sOwnerUUID = GetObjectUUID(GetLocalObject(oInstance, "InstanceOwner"));
    location locExit = Instance_GetExitLocation(oInstance);

    object oPlayer = GetFirstPC();
    while (GetIsObjectValid(oPlayer))
    {
        AssignCommand(oPlayer, JumpToLocation(locExit));

        oPlayer = GetNextPC();
    }

    Events_SignalEvent(INSTANCE_EVENT_DESTROYED, oInstance);

    Instance_INTERNAL_InstanceDispatchList_Remove(oInstance);
    ObjectArray_DeleteByValue(oDataObject, "Instances_" + sOwnerUUID, oInstance);

    DelayCommand(1.0f, Instance_INTERNAL_Destroy(oInstance));
}

void Instance_CheckDestroy_ClientExit(object oPlayer)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);
    string sOwnerUUID = GetObjectUUID(oPlayer);
    int nNumInstances = ObjectArray_Size(oDataObject, "Instances_" + sOwnerUUID);

    int nInstance;
    for (nInstance = 0; nInstance < nNumInstances; nInstance++)
    {
        object oInstance = ObjectArray_At(oDataObject, "Instances_" + sOwnerUUID, nInstance);

        if (GetIsObjectValid(oInstance))
        {
            int nDestroyType = GetLocalInt(oInstance, "InstanceDestroyType");

            switch (nDestroyType)
            {
                case INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT:
                {
                    string sMessage = "Instance: Closing";
                    Instance_SendMessageToInstance(oInstance, sMessage);

                    SetLocalInt(oInstance, "InstanceIsDestroyed", TRUE);

                    DelayCommand(0.0f, Instance_Destroy(oInstance));

                    break;
                }

                case INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT_DELAY:
                {
                    float fDelay = GetLocalFloat(oInstance, "InstanceDestroyDelay");

                    string sMessage = "Instance: Closing in '" + FloatToString(fDelay, 0, 2) + "' seconds";
                    Instance_SendMessageToInstance(oInstance, sMessage);

                    SetLocalInt(oInstance, "InstanceIsDestroyed", TRUE);

                    DelayCommand(fDelay, Instance_Destroy(oInstance));

                    break;
                }
            }
        }
    }
}

void Instance_CheckDestroy_AreaExit(object oPlayer, object oInstance)
{
    if (!GetIsPC(oPlayer) || GetLocalInt(oInstance, "InstanceIsDestroyed"))
        return;

    int nDestroyType = GetLocalInt(oInstance, "InstanceDestroyType");

    switch (nDestroyType)
    {
        case INSTANCE_DESTROY_TYPE_EMPTY:
        {
            int nNumPlayers = NWNX_Area_GetNumberOfPlayersInArea(oInstance);

            if (!nNumPlayers)
            {
                string sMessage = "Instance: Closing";
                Instance_SendMessageToOwner(oInstance, sMessage);
                Instance_SendMessageToInstance(oInstance, sMessage);

                SetLocalInt(oInstance, "InstanceIsDestroyed", TRUE);

                Instance_Destroy(oInstance);
            }

            break;
        }

        case INSTANCE_DESTROY_TYPE_EMPTY_DELAY:
        {
            int nNumPlayers = NWNX_Area_GetNumberOfPlayersInArea(oInstance);
            float fDelay = GetLocalFloat(oInstance, "InstanceDestroyDelay");

            if (!nNumPlayers)
            {
                string sMessage = "Instance: Closing in '" + FloatToString(fDelay, 0, 2) + "' seconds";
                Instance_SendMessageToOwner(oInstance, sMessage);
                Instance_SendMessageToInstance(oInstance, sMessage);

                SetLocalInt(oInstance, "InstanceIsDestroyed", TRUE);

                DelayCommand(fDelay, Instance_Destroy(oInstance));
            }

            break;
        }
    }
}

void Instance_SendMessageToOwner(object oInstance, string sMessage, int bFloating = TRUE)
{
    object oOwner = GetLocalObject(oInstance, "InstanceOwner");

    if (GetIsObjectValid(oOwner))
    {
        if (bFloating)
            FloatingTextStringOnCreature(sMessage, oOwner, FALSE);
        else
            SendMessageToPC(oOwner, sMessage);
    }
}

void Instance_SendMessageToInstance(object oInstance, string sMessage, int bFloating = TRUE)
{
    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        if (GetArea(oPlayer) == oInstance)
        {
            if (bFloating)
                FloatingTextStringOnCreature(sMessage, oPlayer, FALSE);
            else
                SendMessageToPC(oPlayer, sMessage);
        }

        oPlayer = GetNextPC();
    }
}

