/*
    ScriptName: es_s_kobinv.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player]

    Description: Oh no, a kobold invasion!
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_toolbox"
#include "es_srv_instance"
#include "es_srv_simdialog"
#include "es_srv_gui"
#include "es_srv_spellhook"
#include "nwnx_player"

const string KI_LOG_TAG                     = "KoboldInvasion";
const string KI_SCRIPT_NAME                 = "es_s_kobinv";

const string KI_WAYPOINT_START_TAG          = "KI_WP_START";
const string KI_WAYPOINT_CATAPULT_TAG       = "KI_WP_CATAPULT";
const string KI_WAYPOINT_SPAWN_TAG          = "KI_WP_SPAWN";
const string KI_WAYPOINT_MOVETO_TAG         = "KI_WP_MOVETO";

const string KI_BRIDGE_GATE_TAG             = "KI_BRIDGE_GATE";

const string KI_CATAPULT_TAG                = "KI_CATAPULT_PLC";
const string KI_KOBOLD_TAG                  = "KI_KOBOLD_CREATURE";

const string KI_AREA_TEMPLATE_TAG           = "KI_AREA";
const string KI_START_NPC_TAG               = "KI_NPC";

const int KI_SPELL_ID                       = SPELL_FIREBALL;

const int KI_SPAWN_KOBOLD_AMOUNT            = 25;
const int KI_MAX_KOBOLDS_IN_AREA            = 250;

const int KI_GUI_NUM_IDS                    = 20;

void KI_SetupInstanceEvents(string sSubsystemScript);
void KI_SetupNPCAndConversationEvents(string sSubsystemScript);
void KI_SetupCatapultEvents(string sSubsystemScript);
void KI_SetupKoboldEvents(string sSubsystemScript);
void KI_SetupGUIEvents(string sSubsystemScript);

void KI_DrawStaticGUI(object oPlayer);
void KI_UpdateKoboldKillCount(object oPlayer, object oInstance);
void KI_UpdateGUI(object oPlayer);
void KI_HandleGUIEvent(object oPlayer, string sEvent);

void KI_StartConversation(object oPlayer, object oNPC);

string KI_GetPlayerInstanceTag(object oPlayer);
object KI_GetPlayerInstance(object oPlayer);
object KI_CreateInstanceForPlayer(object oPlayer);
void KI_SetupInstanceForPlayer(object oPlayer, object oInstance);
void KI_HandleInstanceCreatedEvent(object oInstance);
void KI_HandleInstanceDestroyedEvent(object oInstance);

void KI_HandleAreaEnter(object oPlayer, object oInstance);
void KI_HandleAreaExit(object oPlayer, object oInstance);

void KI_FireCatapults(object oPlayer);
void KI_HandleFireball(object oCatapult);

void KI_SpawnKobolds(object oInstance);
void KI_KillAllKobolds(object oInstance);
void KI_KoboldOnSpawn(object oKobold);
void KI_KoboldOnDeath(object oKobold);

// @Load
void KI_Load(string sSubsystemScript)
{
    ES_Util_Log(KI_LOG_TAG, "* Kobold Invasion Loading!");

    KI_SetupInstanceEvents(sSubsystemScript);
    KI_SetupNPCAndConversationEvents(sSubsystemScript);
    KI_SetupCatapultEvents(sSubsystemScript);
    KI_SetupKoboldEvents(sSubsystemScript);
    KI_SetupGUIEvents(sSubsystemScript);
}

// @Test
void KI_Test(string sSubsystemScript)
{
    object oObject = GetObjectByTag(KI_START_NPC_TAG);
    Test_Assert("NPC Exists", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_CREATURE));

    object oArea = GetObjectByTag(KI_AREA_TEMPLATE_TAG);
    Test_Assert("Template Area Exists", (GetIsObjectValid(oArea) && NWNX_Object_GetInternalObjectType(oArea) == NWNX_OBJECT_TYPE_INTERNAL_AREA));

        oObject = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_START_TAG, oArea);
        Test_Assert("Start Waypoint Exists In Template Area", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

        oObject = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_CATAPULT_TAG, oArea);
        Test_Assert("Catapult Waypoint Exists In Template Area", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

        oObject = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_SPAWN_TAG, oArea);
        Test_Assert("Spawn Waypoint Exists In Template Area", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

        oObject = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_MOVETO_TAG, oArea);
        Test_Assert("MoveTo Waypoint Exists In Template Area", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

        oObject = ES_Util_GetObjectByTagInArea(KI_BRIDGE_GATE_TAG, oArea);
        Test_Assert("Bridge Gate Exists In Template Area", (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_DOOR));

}

// @EventHandler
void KI_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_INPUT_WALK_TO_WAYPOINT_BEFORE")
        KI_FireCatapults(OBJECT_SELF);
    else
    if (sEvent == Spellhook_GetEventName(KI_SPELL_ID))
        KI_HandleFireball(OBJECT_SELF);
    else
    if (sEvent == "NWNX_ON_INPUT_KEYBOARD_BEFORE" || sEvent == "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE")
        KI_HandleGUIEvent(OBJECT_SELF, sEvent);
    else
    if (sEvent == "NWNX_ON_INPUT_ATTACK_OBJECT_BEFORE")
        Events_SkipEvent();
    else
    if(sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oNPC = OBJECT_SELF;
        object oPlayer = Events_GetEventData_NWNX_Object("PLAYER");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        switch (nOption)
        {
            case 1:// Player accepts, create instance
            {
                object oInstance = KI_GetPlayerInstance(oPlayer);

                if (!GetIsObjectValid(oInstance))
                {
                    oInstance = KI_CreateInstanceForPlayer(oPlayer);

                    KI_SetupInstanceForPlayer(oPlayer, oInstance);
                }

                if (GetIsObjectValid(oInstance))
                    Instance_AddPlayer(oPlayer, oInstance);
                else
                {
                    SendMessageToPC(oPlayer, KI_LOG_TAG + ": Tried to create an instance, but something went wrong :(");
                    ES_Util_Log(KI_LOG_TAG, "ERROR: Failed to create an instance for:  " + GetName(oPlayer));
                }

                break;
            }

            case 2:// Player doesn't accept, end conversation
                SimpleDialog_EndConversation(oPlayer);
                break;
        }
    }
    else
    if (sEvent == INSTANCE_EVENT_CREATED)
    {
        string sCreator = Events_GetEventData_NWNX_String("CREATOR");

        if (sCreator == sSubsystemScript)
            KI_HandleInstanceCreatedEvent(OBJECT_SELF);
    }
    else
    if (sEvent == INSTANCE_EVENT_DESTROYED)
        KI_HandleInstanceDestroyedEvent(OBJECT_SELF);
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_CREATURE_ON_DIALOGUE:
                KI_StartConversation(GetLastSpeaker(), OBJECT_SELF);
                break;

            case EVENT_SCRIPT_AREA_ON_ENTER:
                KI_HandleAreaEnter(GetEnteringObject(), OBJECT_SELF);
                break;

            case EVENT_SCRIPT_AREA_ON_EXIT:
                KI_HandleAreaExit(GetExitingObject(), OBJECT_SELF);
                break;

            case EVENT_SCRIPT_AREA_ON_HEARTBEAT:
                KI_SpawnKobolds(OBJECT_SELF);
                break;

            case EVENT_SCRIPT_CREATURE_ON_SPAWN_IN:
                KI_KoboldOnSpawn(OBJECT_SELF);
                break;

            case EVENT_SCRIPT_CREATURE_ON_DEATH:
                KI_KoboldOnDeath(OBJECT_SELF);
                break;
        }
    }
}

// *** SETUP FUNCTIONS
void KI_SetupInstanceEvents(string sSubsystemScript)
{
    Instance_Register(GetStringLowerCase(KI_AREA_TEMPLATE_TAG), KI_AREA_TEMPLATE_TAG);
    Instance_SubscribeEvent(sSubsystemScript, INSTANCE_EVENT_CREATED);
    Instance_SubscribeEvent(sSubsystemScript, INSTANCE_EVENT_DESTROYED, TRUE);

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_HEARTBEAT, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
}

void KI_SetupNPCAndConversationEvents(string sSubsystemScript)
{
    object oNPC = GetObjectByTag(KI_START_NPC_TAG);

    if (GetIsObjectValid(oNPC))
    {
        // NPC Event Stuff
        Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DIALOGUE, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
        Events_SetObjectEventScript(oNPC, EVENT_SCRIPT_CREATURE_ON_DIALOGUE, FALSE);
        Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DIALOGUE), oNPC);

        // Conversation Event Stuff
        SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
        Events_AddObjectToDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oNPC);

        // Create Conversation
        object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);

        SimpleDialog_AddPage(oConversation, "'ey, want to slaughter some kobolds?");
            SimpleDialog_AddOption(oConversation, "Heck yea, sign me up!");
            SimpleDialog_AddOption(oConversation, "Uh... what? No!");
    }
}

void KI_SetupCatapultEvents(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);

    struct Toolbox_PlaceableData pd;
    pd.nModel = 37;
    pd.sName = "Catapult";
    pd.sDescription = "A fierce looking catapult, ready to destroy masses of kobolds!";
    pd.sTag = KI_CATAPULT_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;

    SetLocalString(oDataObject, "CatapultString", Toolbox_GeneratePlaceable(pd));

    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_BEFORE", TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_ATTACK_OBJECT_BEFORE", TRUE);
    Spellhook_SubscribeEvent(sSubsystemScript, KI_SPELL_ID, TRUE);
}

void KI_SetupKobold(string sResRef)
{
    object oDataObject = ES_Util_GetDataObject(KI_SCRIPT_NAME);
    object oKobold = CreateObject(OBJECT_TYPE_CREATURE, sResRef, GetStartingLocation(), FALSE, KI_KOBOLD_TAG);

    Events_ClearCreatureEventScripts(oKobold);

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneGhost(), oKobold);

    Events_SetObjectEventScript(oKobold, EVENT_SCRIPT_CREATURE_ON_SPAWN_IN, FALSE);
    Events_SetObjectEventScript(oKobold, EVENT_SCRIPT_CREATURE_ON_DEATH, FALSE);

    string sKobold = NWNX_Object_Serialize(oKobold);

    StringArray_Insert(oDataObject, "Kobolds", sKobold);

    DestroyObject(oKobold);
}

void KI_SetupKoboldEvents(string sSubsystemScript)
{
    KI_SetupKobold("nw_kobold001");
    KI_SetupKobold("nw_kobold002");
    KI_SetupKobold("nw_kobold003");
    KI_SetupKobold("nw_kobold004");
    KI_SetupKobold("nw_kobold005");
    KI_SetupKobold("nw_kobold006");

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_SPAWN_IN, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_CREATURE_ON_DEATH, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
}

void KI_SetupGUIEvents(string sSubsystemScript)
{
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_KEYBOARD_BEFORE", TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE", TRUE);
    GUI_ReserveIDs(sSubsystemScript, KI_GUI_NUM_IDS);
}

// ** GUI FUNCTIONS
void KI_DrawStaticGUI(object oPlayer)
{
    int nID = GUI_GetEndID(KI_SCRIPT_NAME);
    int nTextColor = GUI_COLOR_WHITE;
    string sTextFont = GUI_FONT_TEXT_NAME;
    float fLifeTime = 0.0f;

    string sTitle = GetName(GetArea(oPlayer));
    int nTitleLength = GetStringLength(sTitle) + 1;

    //  Title Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 1, 0, nTitleLength, 1, fLifeTime, FALSE);

    // Title
    PostString(oPlayer, sTitle, 2, 1, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID--, sTextFont);

    // Menu Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 1, 3, 9, 2, fLifeTime, FALSE);

    // Kobold Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, 12, 3, 27, 1, fLifeTime, FALSE);
}

void KI_UpdateKoboldKillCount(object oPlayer, object oInstance)
{
    int nID = GUI_GetStartID(KI_SCRIPT_NAME) + 2; //This isn't a very nice way to do this, should fix at some point
    int nTextColor = GUI_COLOR_WHITE;
    string sTextFont = GUI_FONT_TEXT_NAME;
    float fLifeTime = 0.0f;

    string sKoboldsSlaughtered = "Kobolds slaughtered: " + IntToString(GetLocalInt(oInstance, "KoboldsSlaughtered"));
    PostString(oPlayer, sKoboldsSlaughtered, 13, 4, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);
}

void KI_UpdateGUI(object oPlayer)
{
    object oInstance = GetArea(oPlayer);
    int nID = GUI_GetStartID(KI_SCRIPT_NAME);
    int nTextColor = GUI_COLOR_WHITE;
    string sTextFont = GUI_FONT_TEXT_NAME;
    float fLifeTime = 0.0f;

    int nCurrentGUISelection = GetLocalInt(oInstance, "CurrentGUISelection");
    int nInvasionMode = GetLocalInt(oInstance, "InvasionMode");

    string sInvasionMode = nInvasionMode ? "Stop" : "Start";
    string sStartStop = nCurrentGUISelection == 0 ? "> " + sInvasionMode : "  " + sInvasionMode;
    PostString(oPlayer, sStartStop, 2, 4, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    string sExit = nCurrentGUISelection == 1 ? "> Exit" : "  Exit";
    PostString(oPlayer, sExit, 2, 5, SCREEN_ANCHOR_TOP_LEFT, fLifeTime, nTextColor, nTextColor, nID++, sTextFont);

    KI_UpdateKoboldKillCount(oPlayer, oInstance);
}

void KI_HandleGUIEvent(object oPlayer, string sEvent)
{
    if (!GUI_GetIsPlayerInputLocked(oPlayer))
        return;

    object oInstance = GetArea(oPlayer);

    string sKey;
    if (sEvent == "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE")
    {
        sKey = "SPACEBAR";

        Events_SkipEvent();
    }
    else
        sKey = Events_GetEventData_NWNX_String("KEY");

    int nCurrentGUISelection = GetLocalInt(oInstance, "CurrentGUISelection");
    int bRedraw;

    if (sKey == "W")
    {
        if (nCurrentGUISelection > 0)
        {
            NWNX_Player_PlaySound(oPlayer, "gui_select");

            nCurrentGUISelection--;
            bRedraw = TRUE;
        }
    }
    else
    if (sKey == "S")
    {
        if (nCurrentGUISelection < 1)
        {
            NWNX_Player_PlaySound(oPlayer, "gui_select");

            nCurrentGUISelection++;
            bRedraw = TRUE;
        }
    }
    else
    if (sKey == "SPACEBAR")
    {
        NWNX_Player_PlaySound(oPlayer, "gui_picklockopen");

        switch (nCurrentGUISelection)
        {
            case 0:
            {
                int nInvasionMode = GetLocalInt(oInstance, "InvasionMode");
                nInvasionMode = !nInvasionMode;

                if (nInvasionMode)
                {
                    FloatingTextStringOnCreature("Kobold Invasion: Start!", oPlayer, FALSE);

                    ES_Util_Log(KI_LOG_TAG, GetName(oPlayer) + " started the Kobold Invasion!");
                }
                else
                {
                    FloatingTextStringOnCreature("Kobold Invasion: Stop!", oPlayer, FALSE);

                    ES_Util_Log(KI_LOG_TAG, GetName(oPlayer) + " stopped the Kobold Invasion!");

                    KI_KillAllKobolds(oInstance);
                }

                SetLocalInt(oInstance, "InvasionMode", nInvasionMode);
                bRedraw = TRUE;

                break;
            }

            case 1:
                Instance_RemovePlayer(oPlayer, oInstance);
                break;
        }
    }

    SetLocalInt(oInstance, "CurrentGUISelection", nCurrentGUISelection);

    if (bRedraw)
        KI_UpdateGUI(oPlayer);
}

// ** NPC FUNCTIONS
void KI_StartConversation(object oPlayer, object oNPC)
{
    SimpleDialog_StartConversation(oPlayer, oNPC, KI_SCRIPT_NAME);
}

// *** INSTANCE FUNCTIONS
string KI_GetPlayerInstanceTag(object oPlayer)
{
    return KI_AREA_TEMPLATE_TAG + "_" + GetPCPublicCDKey(oPlayer);
}

object KI_GetPlayerInstance(object oPlayer)
{
    return GetObjectByTag(KI_GetPlayerInstanceTag(oPlayer));
}

object KI_CreateInstanceForPlayer(object oPlayer)
{
    struct InstanceData id;
    id.sName = "Kobold Invasion: " + GetName(oPlayer);
    id.sTag = KI_GetPlayerInstanceTag(oPlayer);
    id.oOwner = oPlayer;
    id.nDestroyType = INSTANCE_DESTROY_TYPE_OWNER_DISCONNECT;
    id.fDestroyDelay = 0.0f;
    id.sEntranceObjectTag = KI_WAYPOINT_START_TAG;
    id.locExit = GetLocation(oPlayer);

    return Instance_Create(KI_SCRIPT_NAME, GetStringLowerCase(KI_AREA_TEMPLATE_TAG), id);
}

void KI_SetupInstanceForPlayer(object oPlayer, object oInstance)
{
    if (!GetIsObjectValid(oInstance))
        return;

    object oDataObject = ES_Util_GetDataObject(KI_SCRIPT_NAME);
    object oWaypoint;
    int nNth = 0;

    // Flag so the spellhook fires for placeables
    SetLocalInt(oInstance, "X2_L_WILD_MAGIC", TRUE);

    // Spawn Catapults
    string sCatapult = GetLocalString(oDataObject, "CatapultString");
    string sSpellEvent = Spellhook_GetEventName(KI_SPELL_ID);
    while ((oWaypoint = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_CATAPULT_TAG, oInstance, nNth++)) != OBJECT_INVALID)
    {
        object oCatapult = Toolbox_CreatePlaceable(sCatapult, GetLocation(oWaypoint));

        Events_AddObjectToDispatchList(KI_SCRIPT_NAME, sSpellEvent, oCatapult);
        ObjectArray_Insert(oInstance, "Catapults", oCatapult);
    }

    // Get Spawnpoints
    oWaypoint = OBJECT_INVALID;
    nNth = 0;
    while ((oWaypoint = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_SPAWN_TAG, oInstance, nNth++)) != OBJECT_INVALID)
    {
        ObjectArray_Insert(oInstance, "Spawnpoints", oWaypoint);
    }

    // Get MoveTo Locations
    oWaypoint = OBJECT_INVALID;
    nNth = 0;
    while ((oWaypoint = ES_Util_GetObjectByTagInArea(KI_WAYPOINT_MOVETO_TAG, oInstance, nNth++)) != OBJECT_INVALID)
    {
        ObjectArray_Insert(oInstance, "MoveToPoints", oWaypoint);
    }

    // Get Gate
    object oGate = ES_Util_GetObjectByTagInArea(KI_BRIDGE_GATE_TAG, oInstance, 0);
    SetLocalObject(oInstance, "BridgeGate", oGate);
}

void KI_HandleInstanceCreatedEvent(object oInstance)
{
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, INSTANCE_EVENT_DESTROYED, oInstance);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER), oInstance);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT), oInstance);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_HEARTBEAT), oInstance);
}

void KI_HandleInstanceDestroyedEvent(object oInstance)
{
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, INSTANCE_EVENT_DESTROYED, oInstance);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER), oInstance);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT), oInstance);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_HEARTBEAT), oInstance);
}

// *** AREA FUNCTIONS
void KI_HandleAreaEnter(object oPlayer, object oInstance)
{
    if (Instance_GetOwner(oInstance) != oPlayer)
        return;

    GUI_LockPlayerInput(oPlayer);
    SetPlotFlag(oPlayer, TRUE);
    Effects_ToggleCutsceneInvisibility(oPlayer, TRUE);

    if (GetPlayerBuildVersionMajor(oPlayer) >= 8193 && GetPlayerBuildVersionMinor(oPlayer) >= 11)
        KI_DrawStaticGUI(oPlayer);

    KI_UpdateGUI(oPlayer);

    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_BEFORE", oPlayer);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_ATTACK_OBJECT_BEFORE", oPlayer);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_KEYBOARD_BEFORE", oPlayer);
    Events_AddObjectToDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE", oPlayer);


    SendMessageToPC(oPlayer, "Hello! If you look to the top left you'll see a little menu with two options, you can switch between them with the 'W' and 'S' keys and select an option with the 'Spacebar'!");
}

void KI_HandleAreaExit(object oPlayer, object oInstance)
{
    if (Instance_GetOwner(oInstance) != oPlayer)
        return;

    GUI_UnlockPlayerInput(oPlayer);
    SetPlotFlag(oPlayer, FALSE);
    Effects_ToggleCutsceneInvisibility(oPlayer, FALSE);

    GUI_ClearBySubsystem(oPlayer, KI_SCRIPT_NAME);

    DeleteLocalInt(oInstance, "CurrentGUISelection");
    DeleteLocalInt(oInstance, "InvasionMode");
    DeleteLocalInt(oInstance, "KoboldsSlaughtered");
    DeleteLocalInt(oInstance, "KillStreak");

    KI_KillAllKobolds(oInstance);

    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_WALK_TO_WAYPOINT_BEFORE", oPlayer);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_ATTACK_OBJECT_BEFORE", oPlayer);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_KEYBOARD_BEFORE", oPlayer);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE", oPlayer);
}

// ** CATAPULT FUNCTIONS
void KI_FireCatapult(object oCatapult, location locTarget)
{
    locTarget = ES_Util_GetRandomLocationAroundPoint(locTarget, (Random(25) + 1) / 10.0f);

    AssignCommand(oCatapult, ActionCastSpellAtLocation(KI_SPELL_ID, locTarget, METAMAGIC_ANY, TRUE, PROJECTILE_PATH_TYPE_BALLISTIC));

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SCREEN_BUMP), oCatapult);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DUST_EXPLOSION), oCatapult);

    AssignCommand(oCatapult, PlaySound("sim_pulsnatr"));
}

void KI_FireCatapults(object oPlayer)
{
    object oInstance = GetArea(oPlayer);
    location locTarget = Events_GetEventData_NWNX_Location("AREA", "POS_X", "POS_Y", "POS_Z");

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_PULSE_FIRE), locTarget);

    int nNumCatapults = ObjectArray_Size(oInstance, "Catapults"), nCatapult;

    for(nCatapult = 0; nCatapult < nNumCatapults; nCatapult++)
    {
        object oCatapult = ObjectArray_At(oInstance, "Catapults", nCatapult);

        DelayCommand((Random(10) + 1) / 10.0f, KI_FireCatapult(oCatapult, locTarget));
    }

    Events_SkipEvent();
}

void KI_AnnounceKills(int nAmount)
{
    string sSound;

    if (nAmount < 2)
        sSound = "";
    else
    if (nAmount < 9)
        sSound = "kob_k" + IntToString(nAmount);
    else
        sSound = "kob_k8";

    if (sSound != "")
        NWNX_Player_PlaySound(Instance_GetOwner(GetArea(OBJECT_SELF)), sSound);
}

void KI_HandleFireball(object oCatapult)
{
    location locTarget = GetSpellTargetLocation();

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_FIREBALL), locTarget);

    object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, RADIUS_SIZE_HUGE, locTarget, FALSE, OBJECT_TYPE_CREATURE);

    int nNumKobolds;
    while (GetIsObjectValid(oTarget))
    {
        if (GetTag(oTarget) == KI_KOBOLD_TAG && !GetIsDead(oTarget))
        {
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oTarget);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_FLAME_M), oTarget);

            nNumKobolds++;
        }

        oTarget = GetNextObjectInShape(SHAPE_SPHERE, RADIUS_SIZE_HUGE, locTarget, FALSE, OBJECT_TYPE_CREATURE);
    }

    KI_AnnounceKills(nNumKobolds);

    Spellhook_SkipEvent();
}

// *** KOBOLD FUNCTIONS
void KI_SpawnKobolds(object oInstance)
{
    int nInvasionMode = GetLocalInt(oInstance, "InvasionMode");

    if (nInvasionMode)
    {
        int nKoboldsInArea = GetLocalInt(oInstance, "KoboldsInArea");

        if (nKoboldsInArea > KI_MAX_KOBOLDS_IN_AREA)
            return;

        object oDataObject = ES_Util_GetDataObject(KI_SCRIPT_NAME);
        object oSpawnpoint = ObjectArray_At(oInstance, "Spawnpoints", Random( ObjectArray_Size(oInstance, "Spawnpoints")));
        vector vSpawnpoint = GetPosition(oSpawnpoint);

        string sOnSpawnEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN);
        string sOnDeathEvent = Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DEATH);

        int nNumKoboldTemplates = StringArray_Size(oDataObject, "Kobolds");
        int nNumKobolds = Random(KI_SPAWN_KOBOLD_AMOUNT) + 1;

        int nKobold;
        for(nKobold = 0; nKobold < nNumKobolds; nKobold++)
        {
            string sKobold = StringArray_At(oDataObject, "Kobolds", Random(nNumKoboldTemplates));
            object oKobold = NWNX_Object_Deserialize(sKobold);

            if (GetIsObjectValid(oKobold))
            {
                NWNX_Object_AddToArea(oKobold, oInstance, vSpawnpoint);

                Events_AddObjectToDispatchList(KI_SCRIPT_NAME, sOnSpawnEvent, oKobold);
                Events_AddObjectToDispatchList(KI_SCRIPT_NAME, sOnDeathEvent, oKobold);
            }
        }

        SetLocalInt(oInstance, "KoboldsInArea", nKoboldsInArea + nNumKobolds);
    }
}

void KI_KillAllKobolds(object oInstance)
{
    object oKobold = GetFirstObjectInArea(oInstance);
    while (GetIsObjectValid(oKobold))
    {
        if (GetTag(oKobold) == KI_KOBOLD_TAG)
        {
            AssignCommand(oKobold, SetIsDestroyable(TRUE));
            DestroyObject(oKobold);
        }

        oKobold = GetNextObjectInArea(oInstance);
    }

    DeleteLocalInt(oInstance, "KoboldsInArea");
}

void KI_KoboldOnSpawn(object oKobold)
{
    object oInstance = GetArea(oKobold);
    object oBridgeGate = GetLocalObject(oInstance, "BridgeGate");
    object oMoveToPoint = ObjectArray_At(oInstance, "MoveToPoints", Random(ObjectArray_Size(oInstance, "MoveToPoints")));
    location locMoveToPoint = ES_Util_GetRandomLocationAroundPoint(GetLocation(oMoveToPoint), (Random(75) / 10.0f));

    ActionWait((Random(25) / 10.0f));
    ActionForceMoveToLocation(locMoveToPoint, TRUE, 30.0f);
    ActionAttack(oBridgeGate);

    //if (Random(101) < 10)
    SetIsDestroyable(FALSE, FALSE, FALSE);
}

void KI_AnnounceStreak(int nKoboldsSlaughtered)
{
    int nStreak;

    if (nKoboldsSlaughtered >= 100 && nKoboldsSlaughtered < 200)
        nStreak = 1;
    else
    if (nKoboldsSlaughtered >= 200 && nKoboldsSlaughtered < 300)
        nStreak = 2;
    else
    if (nKoboldsSlaughtered >= 300 && nKoboldsSlaughtered < 400)
        nStreak = 3;
    else
    if (nKoboldsSlaughtered >= 400 && nKoboldsSlaughtered < 500)
        nStreak = 4;
    else
    if (nKoboldsSlaughtered >= 500 && nKoboldsSlaughtered < 600)
        nStreak = 5;
    else
    if (nKoboldsSlaughtered >= 600)
        nStreak = 6;

    if (nStreak)
    {
        object oArea = GetArea(OBJECT_SELF);

        if (GetLocalInt(oArea, "KillStreak") < nStreak)
        {
            SetLocalInt(oArea, "KillStreak", nStreak);
            DelayCommand(2.5f, NWNX_Player_PlaySound(Instance_GetOwner(oArea), "kob_s" + IntToString(nStreak)));
        }
    }
}

void KI_DelayedDestroy(object oKobold)
{
    AssignCommand(oKobold, SetIsDestroyable(TRUE));
    DestroyObject(oKobold);
}

void KI_KoboldOnDeath(object oKobold)
{
    object oInstance = GetArea(oKobold);

    int nKoboldsSlaughtered = GetLocalInt(oInstance, "KoboldsSlaughtered");
    SetLocalInt(oInstance, "KoboldsSlaughtered", ++nKoboldsSlaughtered);

    int nKoboldsInArea = GetLocalInt(oInstance, "KoboldsInArea");
    SetLocalInt(oInstance, "KoboldsInArea", --nKoboldsInArea);

    KI_UpdateKoboldKillCount(Instance_GetOwner(oInstance), oInstance);

    KI_AnnounceStreak(nKoboldsSlaughtered);

    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_SPAWN_IN), oKobold);
    Events_RemoveObjectFromDispatchList(KI_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_CREATURE_ON_DEATH), oKobold);

    effect eBlood = Effects_GetBloodEffect(oKobold);
    Effects_ApplyImpactVisualEffects(oKobold, eBlood, Random(15) + 1, 0.0f, 0.5f);

    DelayCommand(10.0f, KI_DelayedDestroy(oKobold));
}

