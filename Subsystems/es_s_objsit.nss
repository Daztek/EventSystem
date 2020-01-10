/*
    ScriptName: es_s_objsit.nss
    Created by: Daz

    Description: A subsystem that allows players to sit on objects with the
                 following tag: OBJSIT_SINGLE
*/

//void main() {}

#include "es_s_simdialog"

const string OBJSIT_SYSTEM_TAG              = "ObjectSit";
const string OBJSIT_SINGLE_SEAT_TAG         = "OBJSIT_SINGLE";

// @EventSystem_Init
void ObjectSit_Init(string sSubsystemScript)
{
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
    ES_Core_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_USED, ES_CORE_EVENT_FLAG_DEFAULT, TRUE);

    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, TRUE);
}

// @EventSystem_EventHandler
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
        object oPlayer = ES_Core_GetEventData_NWNX_Object("PLAYER");
        int nOption = ES_Core_GetEventData_NWNX_Int("OPTION");

        if (GetSittingCreature(oSittingObject) != oPlayer)
        {
            SimpleDialog_EndConversation(oPlayer);
            return;
        }

        switch (nOption)
        {
            case 1:
            case 2:
                AssignCommand(oSittingObject, SetFacing(GetFacing(oSittingObject) + (nOption == 1 ? - 20.0f : 20.0f)));
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
            case EVENT_SCRIPT_MODULE_ON_MODULE_LOAD:
            {
                int nNth = 0;
                object oSittingObject;

                while ((oSittingObject = GetObjectByTag(OBJSIT_SINGLE_SEAT_TAG, nNth++)) != OBJECT_INVALID)
                {
                    ES_Core_SetObjectEventScript(oSittingObject, EVENT_SCRIPT_PLACEABLE_ON_USED, FALSE);

                    NWNX_Events_AddObjectToDispatchList(ES_Core_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_USED), sSubsystemScript, oSittingObject);
                    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_ACTION_TAKEN, sSubsystemScript, oSittingObject);
                    NWNX_Events_AddObjectToDispatchList(SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, sSubsystemScript, oSittingObject);
                }

                ES_Util_Log(OBJSIT_SYSTEM_TAG, "* Found '" + IntToString(--nNth) + "' Sitting Objects");

                object oConversation = SimpleDialog_CreateConversation(OBJSIT_SYSTEM_TAG);
                SimpleDialog_AddPage(oConversation, "Sitting Action Menu.", TRUE);
                    SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Rotate clockwise]"));
                    SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Rotate counter-clockwise]"));
                    SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Do nothing]"));

                break;
            }

            case EVENT_SCRIPT_PLACEABLE_ON_USED:
            {
                object oSittingObject = OBJECT_SELF;
                object oPlayer = GetLastUsedBy();

                if (!GetIsObjectValid(GetSittingCreature(oSittingObject)))
                {
                    SimpleDialog_StartConversation(oPlayer, oSittingObject, OBJSIT_SYSTEM_TAG);
                    AssignCommand(oPlayer, ActionSit(oSittingObject));
                }

                break;
            }
        }
    }
}

