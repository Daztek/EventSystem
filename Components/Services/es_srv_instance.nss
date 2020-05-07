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
const float INSTANCE_INTERNAL_DESTROY_DELAY             = 1.0f;

const string INSTANCE_EVENT_CREATED                     = "INSTANCE_EVENT_CREATED";
const string INSTANCE_EVENT_CLOSING                     = "INSTANCE_EVENT_CLOSING";
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

    string sEntranceObjectTag;
    location locExit;
};

void Instance_INTERNAL_ClientEnter(object oPlayer);
void Instance_INTERNAL_ClientExit(object oPlayer);
void Instance_INTERNAL_AreaExit(object oPlayer, object oInstance);
void Instance_INTERNAL_AreaEnter(object oPlayer, object oInstance);

void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent, int bDispatchListMode = FALSE);
void Instance_Register(string sTemplateAreaResRef, string sTemplateAreaTag = "");

object Instance_Create(string sSubsystemScript, string sAreaResRef, struct InstanceData id);
void Instance_Destroy(object oInstance);

int Instance_GetAreaIsInstance(object oArea);
string Instance_GetCreator(object oInstance);
object Instance_GetOwner(object oInstance);
string Instance_GetOwnerUUID(object oInstance);
int Instance_GetDestroyType(object oInstance);
float Instance_GetDestroyDelay(object oInstance);
int Instance_GetIsClosing(object oInstance);
object Instance_GetEntranceObject(object oInstance);
location Instance_GetExitLocation(object oInstance);

void Instance_SendMessageToOwner(object oInstance, string sMessage);
void Instance_SendMessageToInstance(object oInstance, string sMessage);
void Instance_RemoveAllPlayers(object oInstance);
void Instance_RemovePlayer(object oPlayer, object oInstance);
void Instance_AddPlayer(object oPlayer, object oInstance);

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

void Instance_INTERNAL_SignalEvent(string sEvent, object oInstance)
{
    Events_PushEventData("TAG", GetTag(oInstance));
    Events_PushEventData("CREATOR", Instance_GetCreator(oInstance));
    Events_PushEventData("OWNER_UUID", Instance_GetOwnerUUID(oInstance));
    Events_SignalEvent(sEvent, oInstance);
}

void Instance_INTERNAL_DestroyArea(object oInstance, int nDelayCommandID)
{
    if (!GetIsObjectValid(oInstance)||
        !Instance_GetIsClosing(oInstance) ||
        !(GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID") == nDelayCommandID))
        return;

    string sOwnerUUID = Instance_GetOwnerUUID(oInstance);
    string sInstanceTag = GetTag(oInstance);

    // Signal Destroyed Event
    Instance_INTERNAL_SignalEvent(INSTANCE_EVENT_DESTROYED, oInstance);

    int nInstanceDestroyed = DestroyArea(oInstance);

    if (nInstanceDestroyed)
    {
        // Remove the instance from the dispatch lists
        Instance_INTERNAL_InstanceDispatchList_Remove(oInstance);

        // Remove the instance from the owner's instance list
        ObjectArray_DeleteByValue(ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME), "PlayerInstances_" + sOwnerUUID, oInstance);
    }
    else
    {
        ES_Util_Log(INSTANCE_LOG_TAG, "WARNING: Failed to destroy instance[" + IntToString(nInstanceDestroyed) + "]: " + sInstanceTag);
    }
}

void Instance_INTERNAL_Destroy(object oInstance, int nDelayCommandID)
{
    if (!GetIsObjectValid(oInstance) ||
        !Instance_GetIsClosing(oInstance) ||
        !(GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID") == nDelayCommandID))
        return;

    Instance_RemoveAllPlayers(oInstance);
    DelayCommand(INSTANCE_INTERNAL_DESTROY_DELAY, Instance_INTERNAL_DestroyArea(oInstance, nDelayCommandID));
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
                        int nDelayCommandID = GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID");

                        SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID", ++nDelayCommandID);
                        DeleteLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing");
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
                        int nDelayCommandID = GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID");
                        float fDelay = Instance_GetDestroyDelay(oInstance);

                        Instance_INTERNAL_SignalEvent(INSTANCE_EVENT_CLOSING, oInstance);

                        SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing", TRUE);
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
                    int nDelayCommandID = GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID");

                    SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID", ++nDelayCommandID);
                    DeleteLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing");
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
                    int nDelayCommandID = GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID");
                    float fDelay = Instance_GetDestroyDelay(oInstance);

                    Instance_INTERNAL_SignalEvent(INSTANCE_EVENT_CLOSING, oInstance);

                    SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing", TRUE);
                    DelayCommand(fDelay, Instance_INTERNAL_Destroy(oInstance, nDelayCommandID));
                }
            }

            break;
        }
    }
}

// *** GENERAL FUNCTIONS
void Instance_SubscribeEvent(string sSubsystemScript, string sInstanceEvent, int bDispatchListMode = FALSE)
{
    // No DispatchListMode for INSTANCE_EVENT_CREATED
    bDispatchListMode = (sInstanceEvent == INSTANCE_EVENT_CREATED ? FALSE : bDispatchListMode);

    Events_SubscribeEvent(sSubsystemScript, sInstanceEvent, bDispatchListMode);
}

void Instance_Register(string sTemplateAreaResRef, string sTemplateAreaTag = "")
{
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "InstanceTemplates", sTemplateAreaResRef) == -1)
    {
        StringArray_Insert(oDataObject, "InstanceTemplates", sTemplateAreaResRef);

        ES_Util_Log(INSTANCE_LOG_TAG, "* Registered Instance Template: " + sTemplateAreaResRef);

        if (sTemplateAreaTag != "")
        {
            object oBlueprintArea = GetObjectByTag(sTemplateAreaTag);

            if (GetIsObjectValid(oBlueprintArea))
            {
                int nDestroyed = DestroyArea(oBlueprintArea);

                if (nDestroyed)
                    ES_Util_Log(INSTANCE_LOG_TAG, "  > Destroyed Template Area");
                else
                    ES_Util_Log(INSTANCE_LOG_TAG, "  > WARNING: Failed to destroy template area: " + IntToString(nDestroyed));
            }
        }
    }
}

// *** CREATE/DESTROY FUNCTIONS
object Instance_Create(string sSubsystemScript, string sAreaResRef, struct InstanceData id)
{
    if (!GetIsObjectValid(id.oOwner) || !GetIsPC(id.oOwner))
        return OBJECT_INVALID;

    object oInstance;
    object oDataObject = ES_Util_GetDataObject(INSTANCE_SCRIPT_NAME);

    if (StringArray_Contains(oDataObject, "InstanceTemplates", sAreaResRef) != -1)
    {
        oInstance = CreateArea(sAreaResRef, id.sTag, id.sName);

        if (GetIsObjectValid(oInstance))
        {
            string sOwnerUUID = GetObjectUUID(id.oOwner);

            Events_SetAreaEventScripts(oInstance);

            ObjectArray_Insert(oDataObject, "PlayerInstances_" + sOwnerUUID, oInstance);

            SetLocalString(oInstance, INSTANCE_SCRIPT_NAME + "_Creator", sSubsystemScript);
            SetLocalString(oInstance, INSTANCE_SCRIPT_NAME + "_ResRef", sAreaResRef);

            SetLocalObject(oInstance, INSTANCE_SCRIPT_NAME + "_Owner", id.oOwner);
            SetLocalString(oInstance, INSTANCE_SCRIPT_NAME + "_OwnerUUID", sOwnerUUID);

            SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DestroyType", id.nDestroyType);
            SetLocalFloat(oInstance, INSTANCE_SCRIPT_NAME + "_DestroyDelay", id.fDestroyDelay);

            object oEntrance = ES_Util_GetObjectByTagInArea(id.sEntranceObjectTag, oInstance);
            SetLocalObject(oInstance, INSTANCE_SCRIPT_NAME + "_EntranceObject", oEntrance);
            SetLocalLocation(oInstance, INSTANCE_SCRIPT_NAME + "_ExitLocation", id.locExit);

            Instance_INTERNAL_InstanceDispatchList_Add(oInstance);

            Instance_INTERNAL_SignalEvent(INSTANCE_EVENT_CREATED, oInstance);
        }
    }

    return oInstance;
}

void Instance_Destroy(object oInstance)
{
    if (!GetIsObjectValid(oInstance) || !Instance_GetAreaIsInstance(oInstance))
        return;

    int nDelayCommandID = GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DelayCommandID");

    Instance_RemoveAllPlayers(oInstance);
    SetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing", TRUE);
    DelayCommand(INSTANCE_INTERNAL_DESTROY_DELAY, Instance_INTERNAL_DestroyArea(oInstance, nDelayCommandID));
}

// *** INFO FUNCTIONS
int Instance_GetAreaIsInstance(object oArea)
{
    return GetLocalString(oArea, INSTANCE_SCRIPT_NAME + "_ResRef") != "";
}

string Instance_GetCreator(object oInstance)
{
    return GetLocalString(oInstance, INSTANCE_SCRIPT_NAME + "_Creator");
}

object Instance_GetOwner(object oInstance)
{
    return GetLocalObject(oInstance, INSTANCE_SCRIPT_NAME + "_Owner");
}

string Instance_GetOwnerUUID(object oInstance)
{
    return GetLocalString(oInstance, INSTANCE_SCRIPT_NAME + "_OwnerUUID");
}

int Instance_GetDestroyType(object oInstance)
{
    return GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_DestroyType");
}

float Instance_GetDestroyDelay(object oInstance)
{
    return GetLocalFloat(oInstance, INSTANCE_SCRIPT_NAME + "_DestroyDelay");
}

int Instance_GetIsClosing(object oInstance)
{
    return GetLocalInt(oInstance, INSTANCE_SCRIPT_NAME + "_IsClosing");
}

object Instance_GetEntranceObject(object oInstance)
{
    return GetLocalObject(oInstance, INSTANCE_SCRIPT_NAME + "_EntranceObject");
}

location Instance_GetExitLocation(object oInstance)
{
    location locExit = GetLocalLocation(oInstance, INSTANCE_SCRIPT_NAME + "_ExitLocation");
    object oExitArea = GetAreaFromLocation(locExit);

    if (!GetIsObjectValid(oExitArea) || oExitArea == oInstance)
    {
        locExit = GetStartingLocation();
    }

    return locExit;
}

// *** UTILITY FUNCIONS
void Instance_SendMessageToOwner(object oInstance, string sMessage)
{
    if (sMessage == "")
        return;

    object oOwner = Instance_GetOwner(oInstance);

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
            AssignCommand(oPlayer, ClearAllActions());
            AssignCommand(oPlayer, JumpToLocation(locExit));
        }

        oPlayer = GetNextPC();
    }
}

void Instance_RemovePlayer(object oPlayer, object oInstance)
{
    if (Instance_GetAreaIsInstance(oInstance) && GetArea(oPlayer) == oInstance)
    {
        AssignCommand(oPlayer, ClearAllActions());
        AssignCommand(oPlayer, JumpToLocation(Instance_GetExitLocation(oInstance)));
    }
}

void Instance_AddPlayer(object oPlayer, object oInstance)
{
    object oEntrance = Instance_GetEntranceObject(oInstance);

    if (GetIsObjectValid(oEntrance) && GetArea(oPlayer) != oInstance)
    {
        AssignCommand(oPlayer, ClearAllActions());
        AssignCommand(oPlayer, JumpToObject(oEntrance));
    }
}

