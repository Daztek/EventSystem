/*
    ScriptName: es_s_uuidcol.nss
    Created by: Daz

    Description: A UUID Collision Test Subsystem
*/

//void main() {}

#include "es_inc_core"

// @EventSystem_Init
void UUIDCollision_Init(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
    ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_UUID_COLLISION_BEFORE");
    ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_UUID_COLLISION_AFTER");
}

// @EventSystem_EventHandler
void UUIDCollision_EventHandler(string sSubsystemScript, string sEvent)
{
    if (StringToInt(sEvent) == EVENT_SCRIPT_MODULE_ON_MODULE_LOAD)
    {
        object oWP = ES_Util_CreateWaypoint(GetStartingLocation(), "UUIDTest");
        string sUUID = GetObjectUUID(oWP);
        object oCopy = CopyObject(oWP, GetStartingLocation());

        PrintString("MODULELOAD: ExistingObject: " + ObjectToString(oWP) + ", CollisionObject: " + ObjectToString(oCopy) + ", UUID: " + sUUID);
    }
    else
    {
        object oCollisionObject = OBJECT_SELF;
        string sUUID = ES_Core_GetEventData_NWNX_String("UUID");
        object oExistingObject = GetObjectByUUID(sUUID);
        int bBefore = sEvent == "NWNX_ON_UUID_COLLISION_BEFORE";

        PrintString((bBefore ? "BEFORE" : "AFTER") + " EVENT: CollisionObject: " + ObjectToString(oCollisionObject) + ",  ExistingObject: " + ObjectToString(oExistingObject) + ", UUID: " + sUUID);
    }
}

