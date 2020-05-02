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

const string INSTANCE_EVENT_CREATED                     = "INSTANCE_EVENT_CREATED";
const string INSTANCE_EVENT_DESTROYED                   = "INSTANCE_EVENT_DESTROYED";

const int INSTANCE_DESTROY_TYPE_NEVER                   = 0;
const int INSTANCE_DESTROY_TYPE_EMPTY                   = 1;
const int INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT        = 2;

struct InstanceData
{
    string sName;
    string sTag;
    object oOwner;

    int nDestroyType;
    float fDestroyDelay;

    location locExit;

    string sClosingMessage;
};

// INTERNAL FUNCTION
void Instance_INTERNAL_ClientEnter(object oPlayer);
// INTERNAL FUNCTION
void Instance_INTERNAL_ClientExit(object oPlayer);
// INTERNAL FUNCTION
void Instance_INTERNAL_AreaExit(object oPlayer, object oInstance);
// INTERNAL FUNCTION
void Instance_INTERNAL_AreaEnter(object oPlayer, object oInstance);

void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent);
void Instance_Register(string sAreaTag, string sAreaResRef);

void Instance_Create(string sAreaResRef, struct InstanceData id);
void Instance_Destroy(object oInstance);

object Instance_GetOwner(object oInstance);
string Instance_GetOwnerUUID(object oInstance);
int Instance_GetDestroyType(object oInstance);
float Instance_GetDestroyDelay(object oInstance);
int Instance_GetIsClosing(object oInstance);
location Instance_GetExitLocation(object oInstance);
string Instance_GetClosingMessage(object oInstance);

void Instance_SendMessageToOwner(object oInstance, string sMessage);
void Instance_SendMessageToInstance(object oInstance, string sMessage);
void Instance_RemoveAllPlayers(object oInstance);

// @Load
void Instance_Load(string sServiceScript)
{
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_BEFORE, TRUE);
    Events_SubscribeEvent_Object(sServiceScript, EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER, TRUE);
}

// @EventHandler
void Instance_EventHandler(string sServiceScript, string sEvent)
{
    ES_Util_Log(INSTANCE_LOG_TAG, "DEBUG: " + sEvent);

    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
        {
            Instance_INTERNAL_ClientEnter(GetEnteringObject());
            break;
        }

        case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
        {
            Instance_INTERNAL_ClientExit(GetExitingObject());
            break;
        }

        case EVENT_SCRIPT_AREA_ON_ENTER:
        {
            Instance_INTERNAL_AreaEnter(GetExitingObject(), OBJECT_SELF);
            break;
        }

        case EVENT_SCRIPT_AREA_ON_EXIT:
        {
            Instance_INTERNAL_AreaExit(GetExitingObject(), OBJECT_SELF);
            break;
        }
    }
}

// *** INTERNAL FUNCTIONS
void Instance_INTERNAL_InstanceDispatchList_Add(object oInstance)
{
    string sAreaOnEnter = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_BEFORE);
    Events_AddObjectToDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnEnter, oInstance);

    string sAreaOnExit = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER);
    Events_AddObjectToDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnExit, oInstance);
}

void Instance_INTERNAL_InstanceDispatchList_Remove(object oInstance)
{
    string sAreaOnEnter = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_BEFORE);
    Events_RemoveObjectFromDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnEnter, oInstance);

    string sAreaOnExit = Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_AFTER);
    Events_RemoveObjectFromDispatchList(INSTANCE_SCRIPT_NAME, sAreaOnExit, oInstance);
}

void Instance_INTERNAL_DestroyArea(object oInstance, int nDelayCommandID)
{
    if (!GetIsObjectValid(oInstance)||
        !Instance_GetIsClosing(oInstance) ||
        !(GetLocalInt(oInstance, "InstanceDelayCommandID") == nDelayCommandID))
        return;

    string sOwnerUUID = Instance_GetOwnerUUID(oInstance);
    string sInstanceTag = GetTag(oInstance);
    int nInstanceDestroyed = DestroyArea(oInstance);

    if (nInstanceDestroyed)
    {
        // Remove the instance from the dispatch lists
        Instance_INTERNAL_InstanceDispatchList_Remove(oInstance);

        // Remove the instance from the owner's instance list
        ObjectArray_DeleteByValue(ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME), "PlayerInstances_" + sOwnerUUID, oInstance);

        // Signal Destroy Event
        Events_PushEventData("TAG", sInstanceTag);
        Events_PushEventData("OWNER_UUID", sOwnerUUID);
        Events_SignalEvent(INSTANCE_EVENT_DESTROYED, GetModule());
    }
    else
    {
        ES_Util_Log(INSTANCE_LOG_TAG, "ERROR: Failed to destroy instance[" + IntToString(nInstanceDestroyed) + "]: " + sInstanceTag);
    }
}

void Instance_INTERNAL_Destroy(object oInstance, int nDelayCommandID)
{
    if (!GetIsObjectValid(oInstance) ||
        !Instance_GetIsClosing(oInstance) ||
        !(GetLocalInt(oInstance, "InstanceDelayCommandID") == nDelayCommandID))
        return;

    Instance_RemoveAllPlayers(oInstance);
    DelayCommand(1.0f, Instance_INTERNAL_DestroyArea(oInstance, nDelayCommandID));
}

void Instance_INTERNAL_ClientEnter(object oPlayer)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);
    string sArrayName = "PlayerInstances_" + GetObjectUUID(oPlayer);
    int nNumInstances = ObjectArray_Size(oDataObject, sArrayName);

    int nInstance;
    for (nInstance = 0; nInstance < nNumInstances; nInstance++)
    {
        object oInstance = ObjectArray_At(oDataObject, sArrayName, nInstance);

        if (GetIsObjectValid(oInstance))
        {
            int nDestroyType = Instance_GetDestroyType(oInstance);

            switch (nDestroyType)
            {
                case INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT:
                {
                    if (Instance_GetIsClosing(oInstance))
                    {
                        int nDelayCommandID = GetLocalInt(oInstance, "InstanceDelayCommandID");

                        SetLocalInt(oInstance, "InstanceDelayCommandID", ++nDelayCommandID);
                        DeleteLocalInt(oInstance, "InstanceIsClosing");
                    }

                    break;
                }
            }
        }
    }
}

void Instance_INTERNAL_ClientExit(object oPlayer)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);
    string sArrayName = "PlayerInstances_" + GetObjectUUID(oPlayer);
    int nNumInstances = ObjectArray_Size(oDataObject, sArrayName);

    int nInstance;
    for (nInstance = 0; nInstance < nNumInstances; nInstance++)
    {
        object oInstance = ObjectArray_At(oDataObject, sArrayName, nInstance);

        if (GetIsObjectValid(oInstance))
        {
            int nDestroyType = Instance_GetDestroyType(oInstance);

            switch (nDestroyType)
            {
                case INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT:
                {
                    if (!Instance_GetIsClosing(oInstance))
                    {
                        int nDelayCommandID = GetLocalInt(oInstance, "InstanceDelayCommandID");
                        float fDelay = Instance_GetDestroyDelay(oInstance);

                        if (fDelay > 0.0f)
                            ES_Util_SendServerMessageToArea(oInstance, Instance_GetClosingMessage(oInstance));

                        SetLocalInt(oInstance, "InstanceIsClosing", TRUE);
                        DelayCommand(fDelay, Instance_INTERNAL_Destroy(oInstance, nDelayCommandID));
                    }

                    break;
                }
            }
        }
    }
}

void Instance_INTERNAL_AreaEnter(object oPlayer, object oInstance)
{
    if (!GetIsPC(oPlayer))
        return;

    int nDestroyType = Instance_GetDestroyType(oInstance);

    switch (nDestroyType)
    {
        case INSTANCE_DESTROY_TYPE_EMPTY:
        {
            int nNumPlayers = NWNX_Area_GetNumberOfPlayersInArea(oInstance);

            if (nNumPlayers)
            {
                if (Instance_GetIsClosing(oInstance))
                {
                    int nDelayCommandID = GetLocalInt(oInstance, "InstanceDelayCommandID");

                    SetLocalInt(oInstance, "InstanceDelayCommandID", ++nDelayCommandID);
                    DeleteLocalInt(oInstance, "InstanceIsClosing");
                }
            }

            break;
        }
    }
}

void Instance_INTERNAL_AreaExit(object oPlayer, object oInstance)
{
    if (!GetIsPC(oPlayer))
        return;

    int nDestroyType = Instance_GetDestroyType(oInstance);

    switch (nDestroyType)
    {
        case INSTANCE_DESTROY_TYPE_EMPTY:
        {
            int nNumPlayers = NWNX_Area_GetNumberOfPlayersInArea(oInstance);

            if (!nNumPlayers)
            {
                if (!Instance_GetIsClosing(oInstance))
                {
                    int nDelayCommandID = GetLocalInt(oInstance, "InstanceDelayCommandID");
                    float fDelay = Instance_GetDestroyDelay(oInstance);

                    SetLocalInt(oInstance, "InstanceIsClosing", TRUE);
                    DelayCommand(fDelay, Instance_INTERNAL_Destroy(oInstance, nDelayCommandID));
                }
            }

            break;
        }
    }
}

// *** GENERAL FUNCTIONS
void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent)
{
    Events_SubscribeEvent(sSubsystemScript, sInstanceEvent, FALSE);
}

void Instance_Register(string sAreaTag, string sAreaResRef)
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "RegisteredInstanceBlueprints", sAreaResRef) == -1)
    {
        StringArray_Insert(oDataObject, "RegisteredInstanceBlueprints", sAreaResRef);

        ES_Util_Log(INSTANCE_LOG_TAG, "* Registered Instance: " + sAreaResRef);

        object oBlueprintArea = GetObjectByTag(sAreaTag);

        if (GetIsObjectValid(oBlueprintArea))
        {
            int nDestroy = DestroyArea(oBlueprintArea);

            ES_Util_Log(INSTANCE_LOG_TAG, "  > Destroyed Blueprint: " + IntToString(nDestroy));
        }
    }
}

// *** CREATE/DESTROY FUNCTIONS
void Instance_Create(string sAreaResRef, struct InstanceData id)
{
    if (!GetIsObjectValid(id.oOwner) || !GetIsPC(id.oOwner))
        return;

    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "RegisteredInstanceBlueprints", sAreaResRef) != -1)
    {
        object oInstance = CreateArea(sAreaResRef, id.sTag, id.sName);

        if (GetIsObjectValid(oInstance))
        {
            string sOwnerUUID = GetObjectUUID(id.oOwner);

            Events_SetAreaEventScripts(oInstance);

            ObjectArray_Insert(oDataObject, "PlayerInstances_" + sOwnerUUID, oInstance);

            SetLocalString(oInstance, "InstanceResRef", sAreaResRef);

            SetLocalObject(oInstance, "InstanceOwner", id.oOwner);
            SetLocalString(oInstance, "InstanceOwnerUUID", sOwnerUUID);

            SetLocalInt(oInstance, "InstanceDestroyType", id.nDestroyType);
            SetLocalFloat(oInstance, "InstanceDestroyDelay", id.fDestroyDelay);

            SetLocalLocation(oInstance, "InstanceExitLocation", id.locExit);

            SetLocalString(oInstance, "InstanceClosingMessage", id.sClosingMessage);

            Instance_INTERNAL_InstanceDispatchList_Add(oInstance);

            Events_PushEventData("TAG", GetTag(oInstance));
            Events_PushEventData("OWNER_UUID", sOwnerUUID);
            Events_SignalEvent(INSTANCE_EVENT_CREATED, oInstance);
        }
    }
}

void Instance_Destroy(object oInstance)
{
    if (!GetIsObjectValid(oInstance) || GetLocalString(oInstance, "InstanceResRef") == "")
        return;

    int nDelayCommandID = GetLocalInt(oInstance, "InstanceDelayCommandID");

    Instance_RemoveAllPlayers(oInstance);
    SetLocalInt(oInstance, "InstanceIsClosing", TRUE);
    DelayCommand(1.0f, Instance_INTERNAL_DestroyArea(oInstance, nDelayCommandID));
}

// *** INFO FUNCTIONS
object Instance_GetOwner(object oInstance)
{
    return GetLocalObject(oInstance, "InstanceOwner");
}

string Instance_GetOwnerUUID(object oInstance)
{
    return GetLocalString(oInstance, "InstanceOwnerUUID");
}

int Instance_GetDestroyType(object oInstance)
{
    return GetLocalInt(oInstance, "InstanceDestroyType");
}

float Instance_GetDestroyDelay(object oInstance)
{
    return GetLocalFloat(oInstance, "InstanceDestroyDelay");
}

int Instance_GetIsClosing(object oInstance)
{
    return GetLocalInt(oInstance, "InstanceIsClosing");
}

location Instance_GetExitLocation(object oInstance)
{
    location locExit = GetLocalLocation(oInstance, "InstanceExitLocation");
    object oExitArea = GetAreaFromLocation(locExit);

    if (!GetIsObjectValid(oExitArea) || oExitArea == oInstance)
        locExit = GetStartingLocation();

    return locExit;
}

string Instance_GetClosingMessage(object oInstance)
{
    return GetLocalString(oInstance, "InstanceClosingMessage");
}

// *** UTILITY FUNCIONS
void Instance_SendMessageToOwner(object oInstance, string sMessage)
{
    if (sMessage == "")
        return;

    object oOwner = GetLocalObject(oInstance, "InstanceOwner");

    if (GetIsObjectValid(oOwner))
    {
        SendMessageToPC(oOwner, sMessage);
    }
}

void Instance_SendMessageToInstance(object oInstance, string sMessage)
{
    if (sMessage == "")
        return;

    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        if (GetArea(oPlayer) == oInstance)
        {
            SendMessageToPC(oPlayer, sMessage);
        }

        oPlayer = GetNextPC();
    }
}

void Instance_RemoveAllPlayers(object oInstance)
{
    location locExit = Instance_GetExitLocation(oInstance);

    object oPlayer = GetFirstPC();
    while (GetIsObjectValid(oPlayer))
    {
        if (GetArea(oPlayer) == oInstance)
        {
            AssignCommand(oPlayer, JumpToLocation(locExit));
        }

        oPlayer = GetNextPC();
    }
}

