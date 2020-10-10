/*
    ScriptName: es_s_areacreator.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player Tileset Visibility Area]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_profiler"
#include "es_srv_chatcom"
#include "es_srv_gui"
#include "es_srv_toolbox"
#include "es_srv_tiles"
#include "es_srv_simdialog"

#include "nwnx_player"
#include "nwnx_tileset"
#include "nwnx_visibility"
#include "nwnx_area"

const string AREACREATOR_LOG_TAG                    = "AreaCreator";
const string AREACREATOR_SCRIPT_NAME                = "es_s_areacreator";
object AREACREATOR_DATA_OBJECT                      = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);

const string AREACREATOR_TEMPLATE_RESREF            = "are_cretemp";

const string AREACREATOR_TILES_WAYPOINT_TAG         = "AC_TILES_WP";
const string AREACREATOR_PREVIEW_WAYPOINT_TAG       = "AC_PREVIEW_WP";

const float AREACREATOR_TILES_TILE_SIZE             = 10.0f;
const float AREACREATOR_TILES_TILE_SCALE            = 0.25f;

const string AREACREATOR_TILES_ARRAY_NAME           = "TILES";
const string AREACREATOR_PREVIEW_TILES_ARRAY_NAME   = "PREVIEW_TILES";
const string AREACREATOR_CURRENT_TILES_ARRAY_NAME   = "CURRENT_TILES";
const string AREACREATOR_FAILED_TILES_ARRAY_NAME    = "FAILED_TILES";

const string AREACREATOR_TILES_TILE_TAG             = "AC_TILE";
const string AREACREATOR_PYLON_TAG_PREFIX           = "AC_PYLON_";
const string AREACREATOR_CONSOLE_TAG                = "AC_CONSOLE";
const string AREACREATOR_PREVIEW_TILE_TAG           = "AC_PREVIEW_TILE";
const string AREACREATOR_PREVIEW_LEVER_TAG          = "AC_PREVIEW_LEVER";
const string AREACREATOR_TRIGGER_TAG                = "AC_TRIGGER";

const int AREACREATOR_GUI_NUM_IDS                   = 20;
const int AREACREATOR_TILESET_MAX_TILES             = 2000;
const int AREACREATOR_VISUALEFFECT_START_ROW        = 1000;
const string AREACREATOR_VISUALEFFECT_DUMMY_NAME    = "dummy_tile_";
const float AREACREATOR_TILE_EFFECT_APPLY_DELAY     = 0.1f;
const int AREACREATOR_MAX_TILE_HEIGHT               = 15;

const int AREACREATOR_RANDOM_AREA_MAX_ATTEMPTS      = 15;

const int AREACREATOR_TILES_MAX_WIDTH               = 12;
const int AREACREATOR_TILES_MAX_HEIGHT              = 12;
const int AREACREATOR_TILES_DEFAULT_WIDTH           = 6;
const int AREACREATOR_TILES_DEFAULT_HEIGHT          = 6;

const int AREACREATOR_PREVIEW_WIDTH                 = 5;
const int AREACREATOR_PREVIEW_HEIGHT                = 5;

const int AREACREATOR_MODE_PAINT                    = 0;
const int AREACREATOR_MODE_CLEAR                    = 1;
const int AREACREATOR_MODE_ROTATE                   = 2;
const int AREACREATOR_MODE_HEIGHT                   = 3;
const int AREACREATOR_MODE_LOCK                     = 4;
const int AREACREATOR_MODE_MATCH                    = 5;

const int AREACREATOR_NEIGHBOR_TILE_TOP_LEFT        = 0;
const int AREACREATOR_NEIGHBOR_TILE_TOP             = 1;
const int AREACREATOR_NEIGHBOR_TILE_TOP_RIGHT       = 2;
const int AREACREATOR_NEIGHBOR_TILE_RIGHT           = 3;
const int AREACREATOR_NEIGHBOR_TILE_BOTTOM_RIGHT    = 4;
const int AREACREATOR_NEIGHBOR_TILE_BOTTOM          = 5;
const int AREACREATOR_NEIGHBOR_TILE_BOTTOM_LEFT     = 6;
const int AREACREATOR_NEIGHBOR_TILE_LEFT            = 7;

// ***
void AreaCreator_SetTileset(string sTileset, string sEdgeTerrainType, int bInitialSet = FALSE);
string AreaCreator_GetOverrideName();
string AreaCreator_GetModeName(int nMode);
void AreaCreator_ApplyVFXAndPlaySoundForArea(object oTarget, int nVisualEffect, string sSound = "");
void AreaCreator_DeleteAllTileEffectOverrideDataObjects();
vector AreaCreator_ConvertTilesGridVectorToAreaVector(vector vTile);
vector AreaCreator_ConvertAreaVectorToTilesGridVector(vector vArea);
int AreaCreator_PositionIsInTilesGrid(vector vPosition);
object AreaCreator_UpdatePreviewArea();

void AreaCreator_CreateTiles(string sSubsystemScript);
void AreaCreator_CreatePylons(string sSubsystemScript);
void AreaCreator_CreateConsole(string sSubsystemScript);
void AreaCreator_CreatePreviewTiles(string sSubsystemScript);
void AreaCreator_CreatePreviewLevers(string sSubsystemScript);

void AreaCreator_HandleAreaOnEnter(object oPlayer, object oArea);
void AreaCreator_HandleAreaOnExit(object oPlayer, object oArea);

void AreaCreator_UpdateTileGridSize();
void AreaCreator_SetTileGridSize(int nWidth, int nHeight);
void AreaCreator_ClearAllTiles(int bClearLocked = FALSE, int bUpdateCustomTileData = FALSE);

void AreaCreator_HandleTile(object oPlayer, object oTile);
void AreaCreator_UpdateTile(object oTile);
void AreaCreator_ClearTile(object oTile, int bClearLock, int bUpdateCustomTileData);
void AreaCreator_RotateTile(object oTile);
void AreaCreator_LockTile(object oTile);

void AreaCreator_SetPylonState(string sType, int nPylonNum);
int AreaCreator_HandlePylon(object oPlayer, object oPylon);

void AreaCreator_DrawStaticGUI(object oPlayer);
void AreaCreator_UpdateGUIPreviewTilesRange(object oPlayer, int nRange, int nNumTilesetTiles);
void AreaCreator_UpdateGUIPreviewTilesRangeForArea(int nRange, int nNumTilesetTiles);
void AreaCreator_UpdateGUISelectedTile(object oPlayer);
void AreaCreator_ResetGUISelectedTileForArea();
void AreaCreator_UpdateGUISelectedTileHeight(object oPlayer);
void AreaCreator_UpdateGUISelectedMode(object oPlayer);
void AreaCreator_UpdateGUIEdgeTerrain(object oPlayer);
void AreaCreator_UpdateGUIEdgeTerrainForArea();
void AreaCreator_UpdateFullGUI(object oPlayer);

void AreaCreator_HandlePreviewLever(object oPlayer, object oLever);
void AreaCreator_HandlePreviewTile(object oPlayer, object oPreviewTile);
void AreaCreator_UpdatePreviewTiles();
void AreaCreator_ClearPreviewTiles();

void AreaCreator_UpdateTileEffectOverrides(object oPlayer, int bCheckPreviewTiles, int bCheckTiles);
void AreaCreator_UpdateTileEffectOverridesForArea(int bCheckPreviewTiles, int bCheckTiles);
void AreaCreator_SetTileEffectOverride(object oPlayer, object oOverrideDataObject, int nTileID, string sTileModel);
void AreaCreator_SetTileEffectOverrideForArea(int nTileID, string sTileModel);
object AreaCreator_GetTileEffectOverrideDataObject(object oPlayer);
void AreaCreator_DestroyTileEffectOverrideDataObject(object oPlayer);
void AreaCreator_DestroyAllTileEffectOverrideDataObjects();

void AreaCreator_CreateTileOverride();
void AreaCreator_SetCustomTileData(object oTile);
void AreaCreator_UpdateAllCustomTileData();

void AreaCreator_CreateConversation(string sSubsystemScript);
void AreaCreator_StartConversation(object oPlayer, object oPlaceable);
void AreaCreator_HandleConversation(string sEvent);

object AreaCreator_GetNeighborTile(object oTile, int nDirection);
struct NWNX_Tileset_TileEdgesAndCorners AreaCreator_GetNeighborEdgesAndCorners(object oTile, int nDirection);
string AreaCreator_HandleCornerConflict(string sCorner1, string sCorner2);
struct Tiles_Tile AreaCreator_GetRandomMatchingTile(object oTile);
void AreaCreator_ClearNeighborTiles(object oTile);
int AreaCreator_GenerateRandomTiles();
void AreaCreator_GenerateRandomArea(object oPlayer);

void AreaCreator_UpdateTrigger();
void AreaCreator_HandleTrigger(int nEvent);

// @Load
void AreaCreator_Load(string sSubsystemScript)
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));

    SetLocalInt(oArea, sSubsystemScript, TRUE);

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_SERVER_SEND_AREA_BEFORE");
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_DM_PLAYERDM_LOGIN_AFTER");
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_DM_PLAYERDM_LOGOUT_AFTER");
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE");
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT, TRUE);

    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER), oArea);
    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT), oArea);

    GUI_ReserveIDs(sSubsystemScript, AREACREATOR_GUI_NUM_IDS);

    AreaCreator_CreateTiles(sSubsystemScript);
    AreaCreator_CreatePylons(sSubsystemScript);
    AreaCreator_CreateConsole(sSubsystemScript);
    AreaCreator_CreatePreviewTiles(sSubsystemScript);
    AreaCreator_CreatePreviewLevers(sSubsystemScript);

    AreaCreator_CreateConversation(sSubsystemScript);

    AreaCreator_SetTileGridSize(AREACREATOR_TILES_DEFAULT_WIDTH, AREACREATOR_TILES_DEFAULT_HEIGHT);
    AreaCreator_SetTileset(TILESET_RESREF_RURAL, "", TRUE);

    DestroyArea(GetObjectByTag(AREACREATOR_TEMPLATE_RESREF));
}

// @Test
void AreaCreator_Test(string sSubsystemScript)
{
    object oObject;

    oObject = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
        Test_Assert("Waypoint With Tag '" + AREACREATOR_TILES_WAYPOINT_TAG + "' Exists",
            (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

    oObject = GetObjectByTag(AREACREATOR_PREVIEW_WAYPOINT_TAG);
        Test_Assert("Waypoint With Tag '" + AREACREATOR_PREVIEW_WAYPOINT_TAG + "' Exists",
            (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));

    oObject = GetObjectByTag(AREACREATOR_TEMPLATE_RESREF);
        Test_Assert("Template Area With Tag '" + AREACREATOR_TEMPLATE_RESREF + "' Exists",
            (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_AREA));
}

// @EventHandler
void AreaCreator_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_SERVER_SEND_AREA_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oArea = Events_GetEventData_NWNX_Object("AREA");

        if (GetLocalInt(oArea, sSubsystemScript))
            AreaCreator_UpdateTileEffectOverrides(oPlayer, TRUE, TRUE);
    }
    else if (sEvent == "NWNX_ON_DM_PLAYERDM_LOGIN_AFTER" || sEvent == "NWNX_ON_DM_PLAYERDM_LOGOUT_AFTER")
    {
        object oPlayer = OBJECT_SELF;

        if (GetLocalInt(GetArea(oPlayer), sSubsystemScript))
            AreaCreator_UpdateFullGUI(oPlayer);
    }
    else if (sEvent == "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE")
    {
        object oPlayer = OBJECT_SELF;

        if (GetArea(oPlayer) == GetObjectByTag("AC_PREVIEW_AREA"))
        {
            vector vPlayer = GetPosition(oPlayer);
            vector vTile = AreaCreator_ConvertAreaVectorToTilesGridVector(vPlayer);
            location locTile = Location(GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG)), vTile, GetFacing(oPlayer));

            AssignCommand(oPlayer, JumpToLocation(locTile));

            Events_SkipEvent();
        }
    }
    else if (SimpleDialog_GetIsDialogEvent(sEvent))
    {
        AreaCreator_HandleConversation(sEvent);
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK:
            {
                object oPlayer = GetPlaceableLastClickedBy();
                object oPlaceable = OBJECT_SELF;
                string sTag = GetTag(oPlaceable);

                AssignCommand(oPlayer, ClearAllActions());

                if (GetStringLeft(sTag, GetStringLength(AREACREATOR_PYLON_TAG_PREFIX)) == AREACREATOR_PYLON_TAG_PREFIX)
                {
                    if (AreaCreator_HandlePylon(oPlayer, oPlaceable))
                    {
                        AreaCreator_UpdateTileGridSize();
                        AreaCreator_CreateTileOverride();
                        AreaCreator_UpdateAllCustomTileData();
                    }
                }
                else if (sTag == AREACREATOR_PREVIEW_LEVER_TAG)
                    AreaCreator_HandlePreviewLever(oPlayer, oPlaceable);
                else if (sTag == AREACREATOR_PREVIEW_TILE_TAG)
                    AreaCreator_HandlePreviewTile(oPlayer, oPlaceable);
                else if (sTag == AREACREATOR_TILES_TILE_TAG)
                    AreaCreator_HandleTile(oPlayer, oPlaceable);
                else if (sTag == AREACREATOR_CONSOLE_TAG)
                    AreaCreator_StartConversation(oPlayer, oPlaceable);

                break;
            }

            case EVENT_SCRIPT_AREA_ON_ENTER:
            {
                object oPlayer = GetEnteringObject();
                object oArea = OBJECT_SELF;

                if (ES_Util_GetIsPC(oPlayer))
                    AreaCreator_HandleAreaOnEnter(oPlayer, oArea);

                break;
            }

            case EVENT_SCRIPT_AREA_ON_EXIT:
            {
                object oPlayer = GetExitingObject();
                object oArea = OBJECT_SELF;

                if (ES_Util_GetIsPC(oPlayer))
                    AreaCreator_HandleAreaOnExit(oPlayer, oArea);

                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
            {
                object oPlayer = GetEnteringObject();

                // Preload the icon texture because stuff is dumb.
                PostString(oPlayer, "a", 0, 0, SCREEN_ANCHOR_TOP_LEFT, 0.1f, GUI_COLOR_TRANSPARENT, GUI_COLOR_TRANSPARENT, 0, GUI_FONT_ICON_32X32);
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                object oPlayer = GetExitingObject();

                AreaCreator_DestroyTileEffectOverrideDataObject(oPlayer);
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_PLAYER_TARGET:
            {
                object oPlayer = GetLastPlayerToSelectTarget();
                vector vPosition = GetTargetingModeSelectedPosition();

                if (Events_GetCurrentTargetingMode(oPlayer) == sSubsystemScript)
                {
                    if (AreaCreator_PositionIsInTilesGrid(vPosition))
                    {
                        object oArea = AreaCreator_UpdatePreviewArea();

                        if (GetIsObjectValid(oArea))
                        {
                            location locArea = Location(oArea, AreaCreator_ConvertTilesGridVectorToAreaVector(vPosition), GetFacing(oPlayer));
                            AssignCommand(oPlayer, JumpToLocation(locArea));
                        }
                    }
                }

                break;
            }

            case EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER:
            case EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT:
            {
                AreaCreator_HandleTrigger(StringToInt(sEvent));
                break;
            }
        }
    }
}

// *** Helper Functions
int AreaCreator_Tile_GetTileID(object oTile)                                { return GetLocalInt(oTile, "TILE_ID"); }
void AreaCreator_Tile_SetTileID(object oTile, int nTileID)                  { SetLocalInt(oTile, "TILE_ID", nTileID); }
string AreaCreator_Tile_GetTileModel(object oTile)                          { return GetLocalString(oTile, "TILE_MODEL"); }
void AreaCreator_Tile_SetTileModel(object oTile, string sModel)             { SetLocalString(oTile, "TILE_MODEL", sModel); }
int AreaCreator_Tile_GetTileNum(object oTile)                               { return GetLocalInt(oTile, "TILE_NUM"); }
void AreaCreator_Tile_SetTileNum(object oTile, int nNum)                    { SetLocalInt(oTile, "TILE_NUM", nNum); }
int AreaCreator_Tile_GetTileOrientation(object oTile)                       { return GetLocalInt(oTile, "TILE_ORIENTATION"); }
void AreaCreator_Tile_SetTileOrientation(object oTile, int nOrientation)    { SetLocalInt(oTile, "TILE_ORIENTATION", nOrientation); }
int AreaCreator_Tile_GetTileHeight(object oTile)                            { return GetLocalInt(oTile, "TILE_HEIGHT"); }
void AreaCreator_Tile_SetTileHeight(object oTile, int nHeight)              { SetLocalInt(oTile, "TILE_HEIGHT", nHeight); }
int AreaCreator_Tile_GetTileLock(object oTile)                              { return GetLocalInt(oTile, "TILE_LOCK"); }
void AreaCreator_Tile_SetTileLock(object oTile, int bLocked)                { SetLocalInt(oTile, "TILE_LOCK", bLocked); }

int AreaCreator_Player_GetSelectedTileID(object oPlayer)                    { return GetLocalInt(oPlayer, "AC_SELECTED_TILE_ID"); }
void AreaCreator_Player_SetSelectedTileID(object oPlayer, int nTileID)      { SetLocalInt(oPlayer, "AC_SELECTED_TILE_ID", nTileID); }
string AreaCreator_Player_GetSelectedTileModel(object oPlayer)              { return GetLocalString(oPlayer, "AC_SELECTED_TILE_MODEL"); }
void AreaCreator_Player_SetSelectedTileModel(object oPlayer, string sModel) { SetLocalString(oPlayer, "AC_SELECTED_TILE_MODEL", sModel); }
int AreaCreator_Player_GetSelectedTileHeight(object oPlayer)                { return GetLocalInt(oPlayer, "AC_SELECTED_TILE_HEIGHT"); }
void AreaCreator_Player_SetSelectedTileHeight(object oPlayer, int nHeight)  { SetLocalInt(oPlayer, "AC_SELECTED_TILE_HEIGHT", nHeight); }
int AreaCreator_Player_GetSelectedMode(object oPlayer)                      { return GetLocalInt(oPlayer, "AC_SELECTED_MODE"); }
void AreaCreator_Player_SetSelectedMode(object oPlayer, int nMode)          { SetLocalInt(oPlayer, "AC_SELECTED_MODE", nMode); }

int AreaCreator_Player_GetGUIXPadding(object oPlayer)                       { return GetLocalInt(oPlayer, "AC_GUI_X_PADDING"); }
void AreaCreator_Player_SetGUIXPadding(object oPlayer, int nXPadding)       { SetLocalInt(oPlayer, "AC_GUI_X_PADDING", nXPadding); }
int AreaCreator_Player_GetGUIYPadding(object oPlayer)                       { return GetLocalInt(oPlayer, "AC_GUI_Y_PADDING"); }
void AreaCreator_Player_SetGUIYPadding(object oPlayer, int nYPadding)       { SetLocalInt(oPlayer, "AC_GUI_Y_PADDING", nYPadding); }

int AreaCreator_GetMaxTiles()                                               { return (AREACREATOR_TILES_MAX_WIDTH * AREACREATOR_TILES_MAX_HEIGHT); }
int AreaCreator_GetMaxPreviewTiles()                                        { return (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT); }
int AreaCreator_GetCurrentWidth()                                           { return GetLocalInt(AREACREATOR_DATA_OBJECT, "CURRENT_TILE_WIDTH"); }
int AreaCreator_GetCurrentHeight()                                          { return GetLocalInt(AREACREATOR_DATA_OBJECT, "CURRENT_TILE_HEIGHT"); }

int AreaCreator_GetPreviewTileRange()                                       { return GetLocalInt(AREACREATOR_DATA_OBJECT, "PREVIEW_TILE_ID_RANGE"); }
void AreaCreator_SetPreviewTileRange(int nRange)                            { SetLocalInt(AREACREATOR_DATA_OBJECT, "PREVIEW_TILE_ID_RANGE", nRange); }

string AreaCreator_GetTileset()                                             { return GetLocalString(AREACREATOR_DATA_OBJECT, "TILESET_NAME"); }
int AreaCreator_GetTilesetNumTileData()                                     { return GetLocalInt(AREACREATOR_DATA_OBJECT, "TILESET_NUM_TILE_DATA"); }
float AreaCreator_GetTilesetHeightTransition()                              { return GetLocalFloat(AREACREATOR_DATA_OBJECT, "TILESET_HEIGHT_TRANSITION"); }
string AreaCreator_GetTilesetEdgeTerrainType()                              { return GetLocalString(AREACREATOR_DATA_OBJECT, "TILESET_EDGE_TERRAIN_TYPE"); }
void AreaCreator_SetTilesetEdgeTerrainType(string sTerrain)                 { SetLocalString(AREACREATOR_DATA_OBJECT, "TILESET_EDGE_TERRAIN_TYPE", sTerrain); }

void AreaCreator_SetTileset(string sTileset, string sEdgeTerrainType, int bInitialSet = FALSE)
{
    string sOverrideName = AreaCreator_GetOverrideName();
    int nNumTileData = Tiles_GetTilesetNumTileData(sTileset);
    float fHeightTransition = Tiles_GetTilesetHeightTransition(sTileset);

    if (nNumTileData > AREACREATOR_TILESET_MAX_TILES)
        ES_Util_Log(AREACREATOR_LOG_TAG , "WARNING: Tileset '" + sTileset + "' has more than " + IntToString(AREACREATOR_TILESET_MAX_TILES) + " tiles! (" + IntToString(nNumTileData) + ")");

    NWNX_Tileset_SetAreaTileOverride(AREACREATOR_TEMPLATE_RESREF, sOverrideName);

    if (!bInitialSet)
    {
        NWNX_Tileset_DeleteTileOverride(sOverrideName);
        AreaCreator_ClearAllTiles(TRUE);
        AreaCreator_DestroyAllTileEffectOverrideDataObjects();
    }

    SetLocalString(AREACREATOR_DATA_OBJECT, "TILESET_NAME", sTileset);
    AreaCreator_SetTilesetEdgeTerrainType(sEdgeTerrainType);
    SetLocalInt(AREACREATOR_DATA_OBJECT, "TILESET_NUM_TILE_DATA", nNumTileData);
    SetLocalFloat(AREACREATOR_DATA_OBJECT, "TILESET_HEIGHT_TRANSITION", fHeightTransition);
    AreaCreator_CreateTileOverride();

    if (!bInitialSet)
    {
        AreaCreator_ResetGUISelectedTileForArea();
        // Dumb workaround
        int nTileRange = !AreaCreator_GetPreviewTileRange() ? AreaCreator_GetMaxPreviewTiles() : 0;
        AreaCreator_SetPreviewTileRange(nTileRange);
        AreaCreator_UpdateGUIPreviewTilesRangeForArea(nTileRange, AreaCreator_GetTilesetNumTileData());
        AreaCreator_UpdateGUIEdgeTerrainForArea();
    }

    AreaCreator_UpdatePreviewTiles();

    if (!bInitialSet)
    {
        AreaCreator_UpdateTileEffectOverridesForArea(TRUE, FALSE);
    }
}

string AreaCreator_GetOverrideName()
{
    return "AreaTileOverride";
}

string AreaCreator_GetModeName(int nMode)
{
    switch (nMode)
    {
        case AREACREATOR_MODE_PAINT:    return "Paint";
        case AREACREATOR_MODE_CLEAR:    return "Clear";
        case AREACREATOR_MODE_ROTATE:   return "Rotate";
        case AREACREATOR_MODE_HEIGHT:   return "Height";
        case AREACREATOR_MODE_LOCK:     return "Lock";
        case AREACREATOR_MODE_MATCH:    return "Match";
    }

    return "Invalid Mode";
}

void AreaCreator_ApplyVFXAndPlaySoundForArea(object oTarget, int nVisualEffect, string sSound = "")
{
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(nVisualEffect), oTarget);

    if (sSound != "")
    {
        object oArea = GetArea(oTarget);
        object oPlayer = GetFirstPC();

        while (oPlayer != OBJECT_INVALID)
        {
            if (GetArea(oPlayer) == oArea)
                NWNX_Player_PlaySound(oPlayer, sSound, oTarget);

            oPlayer = GetNextPC();
        }
    }
}

vector AreaCreator_ConvertTilesGridVectorToAreaVector(vector vTile)
{
    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    vector vTilesWaypointPosition = GetPosition(oTilesWaypoint);
    vector vPosition = vTile - vTilesWaypointPosition;
    vPosition.x /= AREACREATOR_TILES_TILE_SCALE;
    vPosition.y /= AREACREATOR_TILES_TILE_SCALE;

    return vPosition;
}

vector AreaCreator_ConvertAreaVectorToTilesGridVector(vector vArea)
{
    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    vector vTilesWaypointPosition = GetPosition(oTilesWaypoint);
    vArea.x *= AREACREATOR_TILES_TILE_SCALE;
    vArea.y *= AREACREATOR_TILES_TILE_SCALE;
    vector vPosition = vTilesWaypointPosition + vArea;;

    return vPosition;
}

int AreaCreator_PositionIsInTilesGrid(vector vPosition)
{
    vector vTiles = GetPosition(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));

    return vPosition.x >= vTiles.x &&
            vPosition.x <= (vTiles.x + (AreaCreator_GetCurrentWidth() * (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE))) &&
            vPosition.y >= vTiles.y &&
            vPosition.y <= (vTiles.y + (AreaCreator_GetCurrentHeight() * (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE)));
}

object AreaCreator_UpdatePreviewArea()
{
    object oArea = GetObjectByTag("AC_PREVIEW_AREA");

    if (GetIsObjectValid(oArea))
        DestroyArea(oArea);

    oArea = CreateArea(AREACREATOR_TEMPLATE_RESREF, "AC_PREVIEW_AREA", "Area Creator - Preview Area");

    Events_SetAreaEventScripts(oArea, FALSE);

    return oArea;
}

// *** Placeable Creation Functions
void AreaCreator_CreateTiles(string sSubsystemScript)
{
    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    object oArea = GetArea(oTilesWaypoint);

    vector vTilesWaypointPosition = GetPosition(oTilesWaypoint);
    vTilesWaypointPosition.x += (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;

    vector vTilePosition = vTilesWaypointPosition;
    vTilePosition.y += (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;
    vTilePosition.z -= 0.3f;

    struct Toolbox_PlaceableData pd;
    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_TILES_TILE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = FALSE;
    pd.fFacingAdjustment = 90.0f;
    pd.scriptOnClick = TRUE;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    string sOnClickEventName = Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);

    int nX, nY;
    for (nY = 0; nY < AREACREATOR_TILES_MAX_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREACREATOR_TILES_MAX_WIDTH; nX++)
        {
            vTilePosition.x = vTilesWaypointPosition.x + (nX * (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE));

            location locSpawn = Location(oArea, vTilePosition, 0.0f);
            object oTile = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            AreaCreator_Tile_SetTileID(oTile, -1);
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -200.0f);
            ObjectArray_Insert(AREACREATOR_DATA_OBJECT, AREACREATOR_TILES_ARRAY_NAME, oTile);

            NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oTile, NWNX_VISIBILITY_ALWAYS_VISIBLE);

            Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oTile);
        }

        vTilePosition.y += AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE;
    }
}

void AreaCreator_CreatePylons(string sSubsystemScript)
{
    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    object oArea = GetArea(oTilesWaypoint);

    struct Toolbox_PlaceableData pd;
    pd.nModel = 467;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PYLON_TAG_PREFIX;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    string sOnClickEventName = Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);

    int nX, nY, nCount;
    vector vTilesWaypointPosition = GetPosition(oTilesWaypoint);
    vTilesWaypointPosition.x += (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;
    vTilesWaypointPosition.y -= (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;
    vector vPylonPosition = vTilesWaypointPosition;

    for (nX = 0; nX < AREACREATOR_TILES_MAX_WIDTH; nX++)
    {
        vPylonPosition.x = vTilesWaypointPosition.x + (nX * (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE));
        location locSpawn = Location(oArea, vPylonPosition, 0.0f);
        object oPylon = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

        SetTag(oPylon, AREACREATOR_PYLON_TAG_PREFIX + "X" + IntToString(++nCount));
        SetName(oPylon, IntToString(nCount));
        SetLocalString(oPylon, "PYLON_TYPE", "X");
        SetLocalInt(oPylon, "PYLON_NUM", nCount);

        NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oPylon, NWNX_VISIBILITY_ALWAYS_VISIBLE);

        Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oPylon);
    }

    nCount = 0;
    vTilesWaypointPosition = GetPosition(oTilesWaypoint);
    vTilesWaypointPosition.x -= (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;
    vTilesWaypointPosition.y += (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE) * 0.5f;
    vPylonPosition = vTilesWaypointPosition;

    for (nY = 0; nY < AREACREATOR_TILES_MAX_HEIGHT; nY++)
    {
        vPylonPosition.y = vTilesWaypointPosition.y + (nY * (AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE));
        location locSpawn = Location(oArea, vPylonPosition, 0.0f);
        object oPylon = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

        SetTag(oPylon, AREACREATOR_PYLON_TAG_PREFIX + "Y" + IntToString(++nCount));
        SetName(oPylon, IntToString(nCount));
        SetLocalString(oPylon, "PYLON_TYPE", "Y");
        SetLocalInt(oPylon, "PYLON_NUM", nCount);

        NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oPylon, NWNX_VISIBILITY_ALWAYS_VISIBLE);

        Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oPylon);
    }
}

void AreaCreator_CreateConsole(string sSubsystemScript)
{
    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    object oArea = GetArea(oTilesWaypoint);

    struct Toolbox_PlaceableData pd;
    pd.nModel = 468;
    pd.sName = "Console";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_CONSOLE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    vector vPosition = GetPosition(oTilesWaypoint);
    vPosition.x -= 1.0f;
    vPosition.y -= 1.0f;

    location locSpawn = Location(oArea, vPosition, 45.0f);
    object oConsole = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

    NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oConsole, NWNX_VISIBILITY_ALWAYS_VISIBLE);

    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oConsole);
}

void AreaCreator_CreatePreviewTiles(string sSubsystemScript)
{
    object oPreviewWaypoint = GetObjectByTag(AREACREATOR_PREVIEW_WAYPOINT_TAG);
    object oArea = GetArea(oPreviewWaypoint);
    vector vPreviewWaypointPosition = GetPosition(oPreviewWaypoint), vPreviewTilePosition = vPreviewWaypointPosition;
    vPreviewTilePosition.z -= 0.3f;

    struct Toolbox_PlaceableData pd;
    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PREVIEW_TILE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;
    pd.fFacingAdjustment = 90.0f;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    string sOnClickEventName = Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);

    int nX, nY;
    for (nY = 0; nY < AREACREATOR_PREVIEW_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREACREATOR_PREVIEW_WIDTH; nX++)
        {
            vPreviewTilePosition.x = vPreviewWaypointPosition.x + (nX * 1.25f);
            location locSpawn = Location(oArea, vPreviewTilePosition, 0.0f);
            object oPreviewTile = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oPreviewTile);

            NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oPreviewTile, NWNX_VISIBILITY_ALWAYS_VISIBLE);

            SetObjectVisualTransform(oPreviewTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.0f);

            ObjectArray_Insert(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME, oPreviewTile);
        }

        vPreviewTilePosition.y -= 1.25f;
    }
}

void AreaCreator_CreatePreviewLevers(string sSubsystemScript)
{
    object oPreviewWaypoint = GetObjectByTag(AREACREATOR_PREVIEW_WAYPOINT_TAG);
    object oArea = GetArea(oPreviewWaypoint);
    vector vPreviewWaypointPosition = GetPosition(oPreviewWaypoint), vLeverPosition;

    struct Toolbox_PlaceableData pd;
    pd.nModel = 23;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PREVIEW_LEVER_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    string sOnClickEventName = Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK);

    vLeverPosition.x = vPreviewWaypointPosition.x + (((AREACREATOR_PREVIEW_WIDTH - 1) * 1.25f) + 1.5f);
    vLeverPosition.y = vPreviewWaypointPosition.y - (((AREACREATOR_PREVIEW_WIDTH - 1) * 1.25) * 0.5f);
    location locSpawn = Location(oArea, vLeverPosition, 0.0f);

    object oLever = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);
    SetName(oLever, "Next");
    NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oLever, NWNX_VISIBILITY_ALWAYS_VISIBLE);
    Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oLever);

    vLeverPosition.x = vPreviewWaypointPosition.x - 1.5f;
    locSpawn = Location(oArea, vLeverPosition, 180.0f);

    oLever = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);
    SetName(oLever, "Previous");
    NWNX_Visibility_SetVisibilityOverride(OBJECT_INVALID, oLever, NWNX_VISIBILITY_ALWAYS_VISIBLE);
    Events_AddObjectToDispatchList(sSubsystemScript, sOnClickEventName, oLever);
}

// *** Area Event Functions
void AreaCreator_HandleAreaOnEnter(object oPlayer, object oArea)
{
    AreaCreator_UpdateFullGUI(oPlayer);

    Events_AddObjectToDispatchList(AREACREATOR_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
    Events_AddObjectToDispatchList(AREACREATOR_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, oPlayer);
}

void AreaCreator_HandleAreaOnExit(object oPlayer, object oArea)
{
    GUI_ClearBySubsystem(oPlayer, AREACREATOR_SCRIPT_NAME);

    if (SimpleDialog_IsInConversation(oPlayer, AREACREATOR_SCRIPT_NAME))
        SimpleDialog_AbortConversation(oPlayer);

    Events_RemoveObjectFromDispatchList(AREACREATOR_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
    Events_RemoveObjectFromDispatchList(AREACREATOR_SCRIPT_NAME, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, oPlayer);
}

// *** Tile Grid Functions
void AreaCreator_UpdateTileGridSize()
{
    int nMaxTiles = AreaCreator_GetMaxTiles();
    int nWidth = AreaCreator_GetCurrentWidth();
    int nHeight = AreaCreator_GetCurrentHeight();

    ObjectArray_Clear(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME, TRUE);

    int nTile, nCount;
    for (nTile = 0; nTile < nMaxTiles; nTile++)
    {
        object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_TILES_ARRAY_NAME, nTile);
        int nX = nTile % AREACREATOR_TILES_MAX_WIDTH;
        int nY = nTile / AREACREATOR_TILES_MAX_WIDTH;

        if (nX < nWidth && nY < nHeight)
        {
            ObjectArray_Insert(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME, oTile);
            AreaCreator_Tile_SetTileNum(oTile, nCount++);
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.0f);
            SetUseableFlag(oTile, TRUE);
        }
        else
        {
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -200.0f);
            SetUseableFlag(oTile, FALSE);
        }
    }

    AreaCreator_UpdateTrigger();
}

void AreaCreator_SetTileGridSize(int nWidth, int nHeight)
{
    AreaCreator_SetPylonState("X", nWidth);
    AreaCreator_SetPylonState("Y", nHeight);
    AreaCreator_UpdateTileGridSize();
}

void AreaCreator_ClearAllTiles(int bClearLocked = FALSE, int bUpdateCustomTileData =  FALSE)
{
    int nMaxTiles = AreaCreator_GetMaxTiles();

    int nTile;
    for (nTile = 0; nTile < nMaxTiles; nTile++)
    {
        object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_TILES_ARRAY_NAME, nTile);

        if (!bClearLocked && AreaCreator_Tile_GetTileLock(oTile))
            continue;

        AreaCreator_ClearTile(oTile, bClearLocked, bUpdateCustomTileData);
    }

    AreaCreator_UpdateAllCustomTileData();
}

// *** Tile Functions
void AreaCreator_HandleTile(object oPlayer, object oTile)
{
    float fTileHeightTransition = AreaCreator_GetTilesetHeightTransition();
    int nSelectedTileID = AreaCreator_Player_GetSelectedTileID(oPlayer);
    int nSelectedTileHeight = AreaCreator_Player_GetSelectedTileHeight(oPlayer);
    string sSelectedTileModel = AreaCreator_Player_GetSelectedTileModel(oPlayer);
    int nSelectedMode = AreaCreator_Player_GetSelectedMode(oPlayer);
    int bUpdateTile;

    switch (nSelectedMode)
    {
        case AREACREATOR_MODE_PAINT:
        {
            if (AreaCreator_Tile_GetTileID(oTile) == nSelectedTileID)
            {
                AreaCreator_RotateTile(oTile);

                bUpdateTile = TRUE;
            }
            else
            {
                AreaCreator_Tile_SetTileID(oTile, nSelectedTileID);
                AreaCreator_Tile_SetTileModel(oTile, sSelectedTileModel);
                AreaCreator_Tile_SetTileHeight(oTile, nSelectedTileHeight);

                vector vTranslate = Vector(0.0f, 0.0f, 1.5f + (AreaCreator_Tile_GetTileHeight(oTile) * (fTileHeightTransition * AREACREATOR_TILES_TILE_SCALE)));
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE, FALSE, 1.0f, vTranslate), oTile);

                bUpdateTile = TRUE;
            }

            break;
        }

        case AREACREATOR_MODE_CLEAR:
        {
            AreaCreator_ClearTile(oTile, TRUE, FALSE);
            bUpdateTile = TRUE;
            break;
        }

        case AREACREATOR_MODE_ROTATE:
        {
            AreaCreator_RotateTile(oTile);
            bUpdateTile = TRUE;
            break;
        }

        case AREACREATOR_MODE_HEIGHT:
        {
            AreaCreator_Tile_SetTileHeight(oTile, nSelectedTileHeight);
            bUpdateTile = TRUE;
            break;
        }

        case AREACREATOR_MODE_LOCK:
            AreaCreator_LockTile(oTile);
        break;

        case AREACREATOR_MODE_MATCH:
        {
            struct Tiles_Tile tile = AreaCreator_GetRandomMatchingTile(oTile);

            if (tile.nTileID != -1)
            {
                string sTileModel = NWNX_Tileset_GetTileModel(AreaCreator_GetTileset(), tile.nTileID);

                AreaCreator_Tile_SetTileID(oTile, tile.nTileID);
                AreaCreator_Tile_SetTileModel(oTile, sTileModel);
                AreaCreator_Tile_SetTileOrientation(oTile, tile.nOrientation);
                AreaCreator_Tile_SetTileHeight(oTile, tile.nHeight);

                AreaCreator_SetTileEffectOverrideForArea(tile.nTileID, sTileModel);

                vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (tile.nHeight* (fTileHeightTransition * AREACREATOR_TILES_TILE_SCALE)));
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_BREACH, FALSE, 1.0f, vTranslate), oTile);

                bUpdateTile = TRUE;
            }

            break;
        }
    }

    if (bUpdateTile)
        AreaCreator_UpdateTile(oTile);
}

void AreaCreator_UpdateTile(object oTile)
{
    Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");

    int nTileID = AreaCreator_Tile_GetTileID(oTile);
    int nTileOrientation = AreaCreator_Tile_GetTileOrientation(oTile);
    int nTileHeight = AreaCreator_Tile_GetTileHeight(oTile);
    float fTileHeightTransition = AreaCreator_GetTilesetHeightTransition();

    float fOrientation;
    switch (nTileOrientation)
    {
        case 0: fOrientation = 0.0f; break;
        case 1: fOrientation = 90.0f; break;
        case 2: fOrientation = 180.0f; break;
        case 3: fOrientation = 270.0f; break;
    }

    vector vRotate = Vector(fOrientation, 0.0f, 0.0f);
    float fHeight = 1.75f + (nTileHeight * (fTileHeightTransition * AREACREATOR_TILES_TILE_SCALE));
    vector vTranslate = Vector(0.0f, 0.0f, fHeight);

    effect eTile = EffectVisualEffect(AREACREATOR_VISUALEFFECT_START_ROW + nTileID, FALSE, AREACREATOR_TILES_TILE_SCALE, vTranslate, vRotate);
    eTile = TagEffect(eTile, "TILE_EFFECT");

    AreaCreator_SetCustomTileData(oTile);

    if (nTileID != -1)
        DelayCommand(AREACREATOR_TILE_EFFECT_APPLY_DELAY, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oTile));
}

void AreaCreator_ClearTile(object oTile, int bClearLock, int bUpdateCustomTileData)
{
    AreaCreator_Tile_SetTileID(oTile, -1);
    AreaCreator_Tile_SetTileOrientation(oTile, 0);
    AreaCreator_Tile_SetTileHeight(oTile, 0);
    AreaCreator_Tile_SetTileModel(oTile, "");

    Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");

    if (bClearLock)
    {
        AreaCreator_Tile_SetTileLock(oTile, FALSE);
        Effects_RemoveEffectsWithTag(oTile, "TILE_LOCK");
    }

    if (bUpdateCustomTileData)
        AreaCreator_SetCustomTileData(oTile);
}

void AreaCreator_RotateTile(object oTile)
{
    int nOrientation = AreaCreator_Tile_GetTileOrientation(oTile) + 1;

    if (nOrientation > 3)
        nOrientation = 0;

    AreaCreator_Tile_SetTileOrientation(oTile, nOrientation);

    vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (AreaCreator_Tile_GetTileHeight(oTile) * (AreaCreator_GetTilesetHeightTransition() * AREACREATOR_TILES_TILE_SCALE)));
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_AC_BONUS, FALSE, 1.0f, vTranslate), oTile);
}

void AreaCreator_LockTile(object oTile)
{
    if (AreaCreator_Tile_GetTileLock(oTile))
    {
        AreaCreator_Tile_SetTileLock(oTile, FALSE);
        Effects_RemoveEffectsWithTag(oTile, "TILE_LOCK");
    }
    else
    {
        AreaCreator_Tile_SetTileLock(oTile, TRUE);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, TagEffect(EffectVisualEffect(VFX_DUR_GLOW_WHITE), "TILE_LOCK"), oTile);
    }
}

// *** Pylon Functions
void AreaCreator_SetPylonState(string sType, int nPylonNum)
{
    string sCurrentXYVarName = sType == "X" ? "CURRENT_TILE_WIDTH" : "CURRENT_TILE_HEIGHT";
    int nCount;
    object oOtherPylon;
    while ((oOtherPylon = GetObjectByTag(AREACREATOR_PYLON_TAG_PREFIX + sType + IntToString(++nCount))) != OBJECT_INVALID)
    {
        int nOtherPylonNum = GetLocalInt(oOtherPylon, "PYLON_NUM");

        AssignCommand(oOtherPylon, PlayAnimation(nOtherPylonNum <= nPylonNum ? ANIMATION_PLACEABLE_ACTIVATE : ANIMATION_PLACEABLE_DEACTIVATE));
    }

    SetLocalInt(AREACREATOR_DATA_OBJECT, sCurrentXYVarName, nPylonNum);
}

int AreaCreator_HandlePylon(object oPlayer, object oPylon)
{
    int bReturn;
    string sType = GetLocalString(oPylon, "PYLON_TYPE");
    int nPylonNum = GetLocalInt(oPylon, "PYLON_NUM");
    string sCurrentXYVarName = sType == "X" ? "CURRENT_TILE_WIDTH" : "CURRENT_TILE_HEIGHT";
    int nCurrentXY = GetLocalInt(AREACREATOR_DATA_OBJECT, sCurrentXYVarName);

    if (nPylonNum != nCurrentXY)
    {
        AreaCreator_ApplyVFXAndPlaySoundForArea(oPylon, VFX_COM_BLOOD_SPARK_LARGE, "gui_traparm");
        AreaCreator_SetPylonState(sType, nPylonNum);
        bReturn = TRUE;
    }

    return bReturn;
}

// *** GUI Functions
const int AREACREATOR_GUI_ID_PREVIEW_TILES_RANGE    = 0;
const int AREACREATOR_GUI_ID_SELECTED_TILE_NAME     = 1;
const int AREACREATOR_GUI_ID_SELECTED_TILE_ID       = 2;
const int AREACREATOR_GUI_ID_SELECTED_TILE_HEIGHT   = 3;
const int AREACREATOR_GUI_ID_SELECTED_MODE          = 4;
const int AREACREATOR_GUI_ID_EDGE_TERRAIN           = 5;

const int AREA_CREATOR_GUI_X_PADDING                = 36;
const int AREA_CREATOR_GUI_Y_PADDING_DM             = 2;

void AreaCreator_DrawStaticGUI(object oPlayer)
{
    int nID = GUI_GetEndID(AREACREATOR_SCRIPT_NAME);
    int nXPadding = GetLocalInt(oPlayer, "AC_GUI_X_PADDING");
    int nYPadding = GetLocalInt(oPlayer, "AC_GUI_Y_PADDING");

    // Window
    nID -= GUI_DrawWindow(oPlayer, nID, SCREEN_ANCHOR_TOP_LEFT, nXPadding, nYPadding, 30, 7, 0.0f, FALSE);

    PostString(oPlayer, "a", nXPadding + 1, nYPadding + 1, SCREEN_ANCHOR_TOP_LEFT, 0.0f, GUI_COLOR_WHITE, GUI_COLOR_WHITE, nID--, GUI_FONT_ICON_32X32);
}

void AreaCreator_UpdateGUIPreviewTilesRange(object oPlayer, int nRange, int nNumTilesetTiles)
{
    int nID = GUI_GetStartID(AREACREATOR_SCRIPT_NAME) + AREACREATOR_GUI_ID_PREVIEW_TILES_RANGE;
    int nXPadding = AreaCreator_Player_GetGUIXPadding(oPlayer);
    int nYPadding = AreaCreator_Player_GetGUIYPadding(oPlayer);
    int nTextColor = GUI_COLOR_WHITE;
    int nEnd = nRange + AreaCreator_GetMaxPreviewTiles() - 1;

    string sText = "Preview Tiles: " + IntToString(nRange) + "-" + IntToString(nNumTilesetTiles < nEnd ? (nNumTilesetTiles - 1) : nEnd) + " of " + IntToString(nNumTilesetTiles);

    PostString(oPlayer, sText, nXPadding + 1, nYPadding + 4, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nID, GUI_FONT_TEXT_NAME);
}

void AreaCreator_UpdateGUIPreviewTilesRangeForArea(int nRange, int nNumTilesetTiles)
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
            AreaCreator_UpdateGUIPreviewTilesRange(oPlayer, nRange, nNumTilesetTiles);

        oPlayer = GetNextPC();
    }
}

void AreaCreator_UpdateGUISelectedTile(object oPlayer)
{
    int nID = GUI_GetStartID(AREACREATOR_SCRIPT_NAME);
    int nXPadding = AreaCreator_Player_GetGUIXPadding(oPlayer);
    int nYPadding = AreaCreator_Player_GetGUIYPadding(oPlayer);
    int nSelectedTileNameID = nID + AREACREATOR_GUI_ID_SELECTED_TILE_NAME;
    int nSelectedTileIDID = nID + AREACREATOR_GUI_ID_SELECTED_TILE_ID;
    int nTextColor = GUI_COLOR_WHITE;
    int nTileID = AreaCreator_Player_GetSelectedTileID(oPlayer);
    string sTileset = AreaCreator_GetTileset();
    string sMinimapTexture = NWNX_Tileset_GetTileMinimapTexture(sTileset, nTileID);
    string sSelectedTileNameText = "TileName: " + NWNX_Tileset_GetTileModel(sTileset, nTileID);
    string SelectedTileIDText = "TileID: " + IntToString(nTileID);

    PostString(oPlayer, sSelectedTileNameText, nXPadding + 5, nYPadding + 1, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nSelectedTileNameID, GUI_FONT_TEXT_NAME);
    PostString(oPlayer, SelectedTileIDText, nXPadding + 5, nYPadding + 2, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nSelectedTileIDID, GUI_FONT_TEXT_NAME);
    SetTextureOverride(GUI_FONT_ICON_32X32, sMinimapTexture, oPlayer);
}

void AreaCreator_ResetGUISelectedTileForArea()
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
        {
            AreaCreator_Player_SetSelectedTileID(oPlayer, 0);
            AreaCreator_Player_SetSelectedTileModel(oPlayer, NWNX_Tileset_GetTileModel(AreaCreator_GetTileset(), 0));
            AreaCreator_UpdateGUISelectedTile(oPlayer);
        }

        oPlayer = GetNextPC();
    }
}

void AreaCreator_UpdateGUISelectedTileHeight(object oPlayer)
{
    int nID = GUI_GetStartID(AREACREATOR_SCRIPT_NAME) + AREACREATOR_GUI_ID_SELECTED_TILE_HEIGHT;
    int nXPadding = AreaCreator_Player_GetGUIXPadding(oPlayer);
    int nYPadding = AreaCreator_Player_GetGUIYPadding(oPlayer);
    int nTextColor = GUI_COLOR_WHITE;
    int nSelectedTileHeight = AreaCreator_Player_GetSelectedTileHeight(oPlayer);

    string sText = "Tile Height: " + IntToString(nSelectedTileHeight);

    PostString(oPlayer, sText, nXPadding + 1, nYPadding + 5, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nID, GUI_FONT_TEXT_NAME);
}

void AreaCreator_UpdateGUISelectedMode(object oPlayer)
{
    int nID = GUI_GetStartID(AREACREATOR_SCRIPT_NAME) + AREACREATOR_GUI_ID_SELECTED_MODE;
    int nXPadding = AreaCreator_Player_GetGUIXPadding(oPlayer);
    int nYPadding = AreaCreator_Player_GetGUIYPadding(oPlayer);
    int nTextColor = GUI_COLOR_WHITE;
    int nSelectedMode = AreaCreator_Player_GetSelectedMode(oPlayer);

    string sText = "Mode: " + AreaCreator_GetModeName(nSelectedMode);

    PostString(oPlayer, sText, nXPadding + 1, nYPadding + 6, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nID, GUI_FONT_TEXT_NAME);
}

void AreaCreator_UpdateGUIEdgeTerrain(object oPlayer)
{
    int nID = GUI_GetStartID(AREACREATOR_SCRIPT_NAME) + AREACREATOR_GUI_ID_EDGE_TERRAIN;
    int nXPadding = AreaCreator_Player_GetGUIXPadding(oPlayer);
    int nYPadding = AreaCreator_Player_GetGUIYPadding(oPlayer);
    int nTextColor = GUI_COLOR_WHITE;

    string sTerrain = AreaCreator_GetTilesetEdgeTerrainType();
    string sText = "Edge Terrain: " + (sTerrain == "" ? "None" : sTerrain);

    PostString(oPlayer, sText, nXPadding + 1, nYPadding + 7, SCREEN_ANCHOR_TOP_LEFT, 0.0f, nTextColor, nTextColor, nID, GUI_FONT_TEXT_NAME);
}

void AreaCreator_UpdateGUIEdgeTerrainForArea()
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
            AreaCreator_UpdateGUIEdgeTerrain(oPlayer);

        oPlayer = GetNextPC();
    }
}

void AreaCreator_UpdateFullGUI(object oPlayer)
{
    if (GetIsDM(oPlayer))
        AreaCreator_Player_SetGUIYPadding(oPlayer, AREA_CREATOR_GUI_Y_PADDING_DM);
    else
        AreaCreator_Player_SetGUIYPadding(oPlayer, 0);

    AreaCreator_Player_SetGUIXPadding(oPlayer, AREA_CREATOR_GUI_X_PADDING);

    AreaCreator_DrawStaticGUI(oPlayer);
    AreaCreator_UpdateGUIPreviewTilesRange(oPlayer, AreaCreator_GetPreviewTileRange(), AreaCreator_GetTilesetNumTileData());
    AreaCreator_UpdateGUISelectedTile(oPlayer);
    AreaCreator_UpdateGUISelectedTileHeight(oPlayer);
    AreaCreator_UpdateGUISelectedMode(oPlayer);
    AreaCreator_UpdateGUIEdgeTerrain(oPlayer);
}

// *** Tile Preview Functions
void AreaCreator_HandlePreviewLever(object oPlayer, object oLever)
{
    int nNumPreviewTiles = AreaCreator_GetMaxPreviewTiles();
    int nRange = AreaCreator_GetPreviewTileRange();
    int nNumTileData = AreaCreator_GetTilesetNumTileData();
    int nNewRange, bUpdate;

    if (GetName(oLever) == "Next")
    {
        int nMax = floor(IntToFloat(nNumTileData) / nNumPreviewTiles) * nNumPreviewTiles;

        nNewRange = nRange + nNumPreviewTiles;
        bUpdate = nNewRange <= nMax;
    }
    else
    {
        nNewRange = nRange - nNumPreviewTiles;
        bUpdate = nNewRange >= 0;
    }

    if (bUpdate)
    {
        AreaCreator_ApplyVFXAndPlaySoundForArea(oLever, VFX_COM_BLOOD_SPARK_LARGE, "gui_quick_erase");
        AreaCreator_SetPreviewTileRange(nNewRange);
        AreaCreator_UpdateGUIPreviewTilesRangeForArea(nNewRange, nNumTileData);
        AreaCreator_UpdatePreviewTiles();
        AreaCreator_UpdateTileEffectOverridesForArea(TRUE, FALSE);
    }
}

void AreaCreator_HandlePreviewTile(object oPlayer, object oPreviewTile)
{
    AreaCreator_Player_SetSelectedTileID(oPlayer, AreaCreator_Tile_GetTileID(oPreviewTile));
    AreaCreator_Player_SetSelectedTileModel(oPlayer, AreaCreator_Tile_GetTileModel(oPreviewTile));

    AreaCreator_UpdateGUISelectedTile(oPlayer);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEAD_SONIC, FALSE, 1.0f, [0.0f, 0.0f, 1.25f]), oPreviewTile);
}

void AreaCreator_ApplyPreviewTileEffect(object oPreviewTile)
{
    Effects_RemoveEffectsWithTag(oPreviewTile, "TILE_EFFECT_PREVIEW");

    int nTileID = AreaCreator_Tile_GetTileID(oPreviewTile);

    effect eTileEffect = EffectVisualEffect(AREACREATOR_VISUALEFFECT_START_ROW + nTileID, FALSE, 0.1f, [0.0f, 0.0f, 1.75f]);
    eTileEffect = TagEffect(eTileEffect, "TILE_EFFECT_PREVIEW");

    DelayCommand(AREACREATOR_TILE_EFFECT_APPLY_DELAY, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTileEffect, oPreviewTile));
}

void AreaCreator_UpdatePreviewTiles()
{
    string sTileset = AreaCreator_GetTileset();
    int nRange = AreaCreator_GetPreviewTileRange();
    int nNumPreviewTiles = ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME);

    int nPreviewTile;
    for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
    {
        object oPreviewTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME, nPreviewTile);
        int nTileID = nRange + nPreviewTile;
        string sTileModel = NWNX_Tileset_GetTileModel(sTileset, nTileID);

        AreaCreator_Tile_SetTileID(oPreviewTile, nTileID);
        AreaCreator_Tile_SetTileModel(oPreviewTile, sTileModel);

        if (sTileModel != "")
        {
            SetName(oPreviewTile, "[" + IntToString(nTileID) + "] " + sTileModel);

            AreaCreator_ApplyPreviewTileEffect(oPreviewTile);

            SetUseableFlag(oPreviewTile, TRUE);
        }
        else
        {
            SetUseableFlag(oPreviewTile, FALSE);
            Effects_RemoveEffectsWithTag(oPreviewTile, "TILE_EFFECT_PREVIEW");
        }
    }
}

void AreaCreator_ClearPreviewTiles()
{
    int nNumPreviewTiles = ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME);

    int nPreviewTile;
    for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
    {
        object oPreviewTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME, nPreviewTile);

        AreaCreator_Tile_SetTileID(oPreviewTile, 0);
        AreaCreator_Tile_SetTileModel(oPreviewTile, "");
        SetUseableFlag(oPreviewTile, TRUE);
        Effects_RemoveEffectsWithTag(oPreviewTile, "TILE_EFFECT_PREVIEW");
    }
}

// *** Tile Effect Model Override Functions
void AreaCreator_UpdateTileEffectOverrides(object oPlayer, int bCheckPreviewTiles, int bCheckTiles)
{
    object oPlayerDataObject = AreaCreator_GetTileEffectOverrideDataObject(oPlayer);

    if (bCheckPreviewTiles)
    {
        int nRange = AreaCreator_GetPreviewTileRange();
        int nNumPreviewTiles = ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME);

        int nPreviewTile;
        for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
        {
            object oPreviewTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_PREVIEW_TILES_ARRAY_NAME, nPreviewTile);

            if (GetUseableFlag(oPreviewTile))
            {
                int nTileID = AreaCreator_Tile_GetTileID(oPreviewTile);

                if (nTileID != -1)
                {
                    string sTileModel = AreaCreator_Tile_GetTileModel(oPreviewTile);
                    AreaCreator_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTileID, sTileModel);
                }
            }
        }
    }

    if (bCheckTiles)
    {
        int nMaxTiles = AreaCreator_GetMaxTiles();
        int nTile;
        for (nTile = 0; nTile < nMaxTiles; nTile++)
        {
            object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_TILES_ARRAY_NAME, nTile);
            int nTileID = AreaCreator_Tile_GetTileID(oTile);

            if (nTileID != -1)
            {
                string sTileModel = AreaCreator_Tile_GetTileModel(oTile);
                AreaCreator_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTileID, sTileModel);
            }
        }
    }
}

void AreaCreator_UpdateTileEffectOverridesForArea(int bCheckPreviewTiles, int bCheckTiles)
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
            DelayCommand(0.0f, AreaCreator_UpdateTileEffectOverrides(oPlayer, bCheckPreviewTiles, bCheckTiles));

        oPlayer = GetNextPC();
    }
}

void AreaCreator_SetTileEffectOverride(object oPlayer, object oOverrideDataObject, int nTileID, string sTileModel)
{
    if (!GetLocalInt(oOverrideDataObject, "TILE_ID_" + IntToString(nTileID)))
    {
        NWNX_Player_SetResManOverride(oPlayer, 2002, AREACREATOR_VISUALEFFECT_DUMMY_NAME + IntToString(nTileID), sTileModel);
        SetLocalInt(oOverrideDataObject, "TILE_ID_" + IntToString(nTileID), TRUE);
    }
}

void AreaCreator_SetTileEffectOverrideForArea(int nTileID, string sTileModel)
{
    object oArea = GetArea(GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
        {
            object oPlayerDataObject = AreaCreator_GetTileEffectOverrideDataObject(oPlayer);
            AreaCreator_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTileID, sTileModel);
        }

        oPlayer = GetNextPC();
    }
}

object AreaCreator_GetTileEffectOverrideDataObject(object oPlayer)
{
    return ES_Util_GetDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
}

void AreaCreator_DestroyTileEffectOverrideDataObject(object oPlayer)
{
    ES_Util_DestroyDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
}

void AreaCreator_DestroyAllTileEffectOverrideDataObjects()
{
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        AreaCreator_DestroyTileEffectOverrideDataObject(oPlayer);
        oPlayer = GetNextPC();
    }
}

// *** Custom Area/Tile Data Functions
void AreaCreator_CreateTileOverride()
{
    string sOverrideName = AreaCreator_GetOverrideName();
    string sTileset = AreaCreator_GetTileset();
    int nWidth = AreaCreator_GetCurrentWidth();
    int nHeight = AreaCreator_GetCurrentHeight();

    NWNX_Tileset_CreateTileOverride(sOverrideName, sTileset, nWidth, nHeight);
}

void AreaCreator_SetCustomTileData(object oTile)
{
    int nTileNum = AreaCreator_Tile_GetTileNum(oTile);
    int nTileID = AreaCreator_Tile_GetTileID(oTile);
    int nTileOrientation = AreaCreator_Tile_GetTileOrientation(oTile);
    int nTileHeight = AreaCreator_Tile_GetTileHeight(oTile);

    struct NWNX_Tileset_CustomTileData ctd;
    ctd.nTileID = nTileID;
    ctd.nOrientation = nTileOrientation;
    ctd.nHeight = nTileHeight;
    ctd.nMainLightColor1 = TILE_MAIN_LIGHT_COLOR_BRIGHT_WHITE;
    ctd.nMainLightColor2 = TILE_MAIN_LIGHT_COLOR_BRIGHT_WHITE;
    ctd.nSourceLightColor1 = TILE_SOURCE_LIGHT_COLOR_PALE_YELLOW;
    ctd.nSourceLightColor2 = TILE_SOURCE_LIGHT_COLOR_PALE_YELLOW;
    ctd.bAnimLoop1 = TRUE;
    ctd.bAnimLoop2 = TRUE;
    ctd.bAnimLoop3 = TRUE;

    if (nTileID != -1)
        NWNX_Tileset_SetOverrideTileData(AreaCreator_GetOverrideName(), nTileNum, ctd);
}

void AreaCreator_UpdateAllCustomTileData()
{
    int nMaxTiles = AreaCreator_GetMaxTiles();

    NWNX_Tileset_DeleteOverrideTileData(AreaCreator_GetOverrideName(), -1);

    int nTile;
    for (nTile = 0; nTile < nMaxTiles; nTile++)
    {
        object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_TILES_ARRAY_NAME, nTile);

        if (GetUseableFlag(oTile))
            AreaCreator_SetCustomTileData(oTile);
    }
}

// *** Conversation Functions
void AreaCreator_CreateConversation(string sSubsystemScript)
{
    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);

    SimpleDialog_AddPage(oConversation, "Area Creator - Main Menu");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[General Functions]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Tile Mode Selection]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Adjust Tile Paint Height]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Close]"));

    SimpleDialog_AddPage(oConversation, "Area Creator - General Functions");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Update Preview Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Clear All Tiles]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Generate Random Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Tileset Selection]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Edge Terrain Selection]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Jump To Location In Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Creator - Select Tile Mode");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_PAINT) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_CLEAR) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_ROTATE) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_HEIGHT) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_LOCK) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Mode: " + AreaCreator_GetModeName(AREACREATOR_MODE_MATCH) + "]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Creator - Adjust Tile Paint Height");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Increase]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Decrease]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Creator - Select Tileset");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Rural]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Crypt]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Castle Interior]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Creator - Select Tile Edge");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[None]"));
        SimpleDialog_AddOption(oConversation, "Terrain0", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain1", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain2", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain3", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain4", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain5", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain6", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain7", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain8", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain9", TRUE);
        SimpleDialog_AddOption(oConversation, "Terrain10", TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));
}

void AreaCreator_StartConversation(object oPlayer, object oPlaceable)
{
    SimpleDialog_StartConversation(oPlayer, oPlayer, AREACREATOR_SCRIPT_NAME);

    DelayCommand(0.25f, AreaCreator_UpdateFullGUI(oPlayer));
}

void AreaCreator_HandleConversation(string sEvent)
{
    object oPlayer = OBJECT_SELF;
    string sConversation = Events_GetEventData_NWNX_String("CONVERSATION_TAG");

    if (sConversation != AREACREATOR_SCRIPT_NAME)
        return;

    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION)
    {
        int nPage = Events_GetEventData_NWNX_Int("PAGE");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        switch (nPage)
        {
            case 6: // Edge Terrain Menu
            {
                switch (nOption)
                {
                    case 2: // Terrain0
                    case 3: // Terrain1
                    case 4: // Terrain2
                    case 5: // Terrain3
                    case 6: // Terrain4
                    case 7: // Terrain5
                    case 8: // Terrain6
                    case 9: // Terrain7
                    case 10:// Terrain8
                    case 11:// Terrain9
                    case 12:// Terrain10
                    {
                        string sTerrain = Tiles_GetTilesetTerrain(AreaCreator_GetTileset(), nOption - 2);

                        if (sTerrain != "")
                        {
                            SimpleDialog_SetResult(TRUE);
                            SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[" + sTerrain + "]"));
                        }
                    }
                }

                break;
            }
        }
    }
    else if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        int nPage = Events_GetEventData_NWNX_Int("PAGE");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        NWNX_Player_PlaySound(oPlayer, "gui_select");

        switch (nPage)
        {
            case 1: // Main Menu
            {
                switch (nOption)
                {
                    case 1: // General Functions Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;

                    case 2: // Tile Mode Selection Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 3);
                        break;

                    case 3:// Adjust Tile Paint Height Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 4);
                        break;

                    case 4:// Close
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                }

                break;
            }

            case 2: // General Functions Menu
            {
                switch (nOption)
                {
                    case 1:// Update Preview Area
                        AreaCreator_UpdatePreviewArea();
                        break;

                    case 2:// Clear All Tiles
                        AreaCreator_ClearAllTiles();
                        break;

                    case 3:// Generate Random Area
                        AreaCreator_GenerateRandomArea(oPlayer);
                        break;

                    case 4:// Select Tileset Menu
                         SimpleDialog_SetCurrentPage(oPlayer, 5);
                         break;

                    case 5:// Edge Terrain Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 6);
                        break;

                    case 6:// Jump To Location In Area
                        Events_EnterTargetingMode(oPlayer, AREACREATOR_SCRIPT_NAME, OBJECT_TYPE_TILE | OBJECT_TYPE_PLACEABLE);
                        break;

                    case 7:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 1);
                        break;
                }

                break;
            }

            case 3: // Tile Mode Selection Menu
            {
                switch (nOption)
                {
                    case 1:// Paint
                    case 2:// Clear
                    case 3:// Rotate
                    case 4:// Height
                    case 5:// Lock
                    case 6:// Match
                    {
                        AreaCreator_Player_SetSelectedMode(oPlayer, (nOption - 1));
                        AreaCreator_UpdateGUISelectedMode(oPlayer);
                        break;
                    }

                    case 7:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 1);
                        break;
                }

                break;
            }

            case 4: // Adjust Tile Paint Height Menu
            {
                switch (nOption)
                {
                    case 1:// Increase Tile Height
                    {
                        int nHeight = AreaCreator_Player_GetSelectedTileHeight(oPlayer) + 1;

                        if (nHeight > AREACREATOR_MAX_TILE_HEIGHT)
                            nHeight = AREACREATOR_MAX_TILE_HEIGHT;

                        AreaCreator_Player_SetSelectedTileHeight(oPlayer, nHeight);
                        AreaCreator_UpdateGUISelectedTileHeight(oPlayer);

                        break;
                    }

                    case 2:// Decrease Tile Height
                    {
                        int nHeight = AreaCreator_Player_GetSelectedTileHeight(oPlayer) - 1;

                        if (nHeight < 0)
                            nHeight = 0;

                        AreaCreator_Player_SetSelectedTileHeight(oPlayer, nHeight);
                        AreaCreator_UpdateGUISelectedTileHeight(oPlayer);

                        break;
                    }

                    case 3:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 1);
                        break;
                }

                break;
            }

            case 5: // Tileset Selection Menu
            {
                switch (nOption)
                {
                    case 1:// Rural
                    {
                        if (AreaCreator_GetTileset() != TILESET_RESREF_RURAL)
                            AreaCreator_SetTileset(TILESET_RESREF_RURAL, "");
                        break;
                    }

                    case 2:// Crypt
                    {
                        if (AreaCreator_GetTileset() != TILESET_RESREF_CRYPT)
                            AreaCreator_SetTileset(TILESET_RESREF_CRYPT, "");
                        break;
                    }

                    case 3:// Castle Interior
                    {
                        if (AreaCreator_GetTileset() != TILESET_RESREF_CASTLE_INTERIOR)
                            AreaCreator_SetTileset(TILESET_RESREF_CASTLE_INTERIOR, "");
                        break;
                    }

                    case 4:// Back to General Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;
                }

                break;
            }

            case 6: // Edge Terrain Menu
            {
                switch (nOption)
                {
                    case 1:// None
                    {
                        AreaCreator_SetTilesetEdgeTerrainType("");
                        AreaCreator_UpdateGUIEdgeTerrainForArea();
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;
                    }

                    case 2: // Terrain0
                    case 3: // Terrain1
                    case 4: // Terrain2
                    case 5: // Terrain3
                    case 6: // Terrain4
                    case 7: // Terrain5
                    case 8: // Terrain6
                    case 9: // Terrain7
                    case 10:// Terrain8
                    case 11:// Terrain9
                    case 12:// Terrain10
                    {
                        AreaCreator_SetTilesetEdgeTerrainType(Tiles_GetTilesetTerrain(AreaCreator_GetTileset(), nOption - 2));
                        AreaCreator_UpdateGUIEdgeTerrainForArea();
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;
                    }

                    case 13:// Back to General Menu
                        SimpleDialog_SetCurrentPage(oPlayer, 2);
                        break;
                }

                break;
            }
        }
    }
}

// *** Random Area Functions
object AreaCreator_GetNeighborTile(object oTile, int nDirection)
{
    int nTileNum = AreaCreator_Tile_GetTileNum(oTile);
    int nCurrentWidth =  AreaCreator_GetCurrentWidth();
    int nCurrentHeight = AreaCreator_GetCurrentHeight();
    int nTileX = nTileNum % nCurrentWidth;
    int nTileY = nTileNum / nCurrentWidth;

    switch (nDirection)
    {
        case AREACREATOR_NEIGHBOR_TILE_TOP_LEFT:
        {
            if (nTileY == (nCurrentHeight - 1) || nTileX == 0)
                return OBJECT_INVALID;
            else
                nTileNum += (nCurrentWidth - 1);
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_TOP:
        {
            if (nTileY == (nCurrentHeight - 1))
                return OBJECT_INVALID;
            else
                nTileNum += nCurrentWidth;
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_TOP_RIGHT:
        {
            if (nTileY == (nCurrentHeight - 1) || nTileX == (nCurrentWidth - 1))
                return OBJECT_INVALID;
            else
                nTileNum += (nCurrentWidth + 1);
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_RIGHT:
        {
            if (nTileX == (nCurrentWidth - 1))
                return OBJECT_INVALID;
            else
                nTileNum += 1;
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_BOTTOM_RIGHT:
        {
            if (nTileY == 0 || nTileX == (nCurrentWidth - 1))
                return OBJECT_INVALID;
            else
                nTileNum -= (nCurrentWidth - 1);
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_BOTTOM:
        {
            if (nTileY == 0)
                return OBJECT_INVALID;
            else
                nTileNum -= nCurrentWidth;
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_BOTTOM_LEFT:
        {
            if (nTileY == 0 || nTileX == 0)
                return OBJECT_INVALID;
            else
                nTileNum -= (nCurrentWidth + 1);
            break;
        }

        case AREACREATOR_NEIGHBOR_TILE_LEFT:
        {
            if (nTileX == 0)
                return OBJECT_INVALID;
            else
                nTileNum -= 1;
            break;
        }
    }

    return ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME, nTileNum);
}

struct NWNX_Tileset_TileEdgesAndCorners AreaCreator_GetNeighborEdgesAndCorners(object oTile, int nDirection)
{
    struct NWNX_Tileset_TileEdgesAndCorners str;
    object oNeighborTile = AreaCreator_GetNeighborTile(oTile, nDirection);

    if (oNeighborTile != OBJECT_INVALID)
    {
        int nTileID = AreaCreator_Tile_GetTileID(oNeighborTile);
        int nOrientation = AreaCreator_Tile_GetTileOrientation(oNeighborTile);
        int nHeight = AreaCreator_Tile_GetTileHeight(oNeighborTile);

        if (nTileID != -1)
            str = Tiles_GetCornersAndEdgesByOrientation(AreaCreator_GetTileset(), nTileID, nOrientation);

        if (AreaCreator_GetTileset() == TILESET_RESREF_RURAL && nHeight == 1)
            str = Tiles_ReplaceTerrainOrCrosser(str, "Grass", "Grass+");
    }
    else
    {
        string sEdgeTerrainType = AreaCreator_GetTilesetEdgeTerrainType();

        switch (nDirection)
        {
            case AREACREATOR_NEIGHBOR_TILE_TOP:
            {
                str.sBottomLeft = sEdgeTerrainType;
                str.sBottom = sEdgeTerrainType;
                str.sBottomRight = sEdgeTerrainType;
                break;
            }

            case AREACREATOR_NEIGHBOR_TILE_RIGHT:
            {
                str.sTopLeft = sEdgeTerrainType;
                str.sLeft = sEdgeTerrainType;
                str.sBottomLeft = sEdgeTerrainType;
                break;
            }

            case AREACREATOR_NEIGHBOR_TILE_BOTTOM:
            {
                str.sTopLeft = sEdgeTerrainType;
                str.sTop = sEdgeTerrainType;
                str.sTopRight = sEdgeTerrainType;
                break;
            }

            case AREACREATOR_NEIGHBOR_TILE_LEFT:
            {
                str.sTopRight = sEdgeTerrainType;
                str.sRight = sEdgeTerrainType;
                str.sBottomRight = sEdgeTerrainType;
                break;
            }
        }
    }

    return str;
}

string AreaCreator_HandleCornerConflict(string sCorner1, string sCorner2)
{
    if (sCorner1 == sCorner2)
        return sCorner1;

    if (sCorner1 == "" && sCorner2 == "")
        return "";

    if (sCorner1 == "" && sCorner2 != "")
        return sCorner2;

    if (sCorner1 != "" && sCorner2 == "")
        return sCorner1;

    return "ERROR";
}

/*
void PrintTileStruct(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    PrintString("TILE STRUCT:");
    PrintString("TL: " + str.sTopLeft);
    PrintString("T: " + str.sTop);
    PrintString("TR: " + str.sTopRight);
    PrintString("R: " + str.sRight);
    PrintString("BR: " + str.sBottomRight);
    PrintString("B: " + str.sBottom);
    PrintString("BL: " + str.sBottomLeft);
    PrintString("L: " + str.sLeft);
}
*/

struct Tiles_Tile AreaCreator_GetRandomMatchingTile(object oTile)
{
    struct NWNX_Tileset_TileEdgesAndCorners strQuery;

    struct NWNX_Tileset_TileEdgesAndCorners strTop = AreaCreator_GetNeighborEdgesAndCorners(oTile, AREACREATOR_NEIGHBOR_TILE_TOP);
    struct NWNX_Tileset_TileEdgesAndCorners strRight = AreaCreator_GetNeighborEdgesAndCorners(oTile, AREACREATOR_NEIGHBOR_TILE_RIGHT);
    struct NWNX_Tileset_TileEdgesAndCorners strBottom = AreaCreator_GetNeighborEdgesAndCorners(oTile, AREACREATOR_NEIGHBOR_TILE_BOTTOM);
    struct NWNX_Tileset_TileEdgesAndCorners strLeft = AreaCreator_GetNeighborEdgesAndCorners(oTile, AREACREATOR_NEIGHBOR_TILE_LEFT);

    strQuery.sTop = strTop.sBottom;
    strQuery.sRight = strRight.sLeft;
    strQuery.sBottom = strBottom.sTop;
    strQuery.sLeft = strLeft.sRight;

    strQuery.sTopLeft = AreaCreator_HandleCornerConflict(strTop.sBottomLeft, strLeft.sTopRight);
    strQuery.sTopRight = AreaCreator_HandleCornerConflict(strTop.sBottomRight, strRight.sTopLeft);
    strQuery.sBottomRight = AreaCreator_HandleCornerConflict(strRight.sBottomLeft, strBottom.sTopRight);
    strQuery.sBottomLeft = AreaCreator_HandleCornerConflict(strBottom.sTopLeft, strLeft.sBottomRight);

    //PrintTileStruct(strQuery);

    return Tiles_GetRandomMatchingTile(AreaCreator_GetTileset(), strQuery);
}

void AreaCreator_ClearNeighborTiles(object oTile)
{
    int nDirection;
    for (nDirection = 0; nDirection < 8; nDirection++)
    {
        object oNeighborTile = AreaCreator_GetNeighborTile(oTile, nDirection);

        if (oNeighborTile != OBJECT_INVALID && !AreaCreator_Tile_GetTileLock(oNeighborTile))
            AreaCreator_ClearTile(oNeighborTile, FALSE, FALSE);
    }
}

int AreaCreator_GenerateRandomTiles()
{
    ObjectArray_Clear(AREACREATOR_DATA_OBJECT, AREACREATOR_FAILED_TILES_ARRAY_NAME, TRUE);

    int nTile, nNumTiles = ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME, nTile);

        if (AreaCreator_Tile_GetTileID(oTile) != -1)
            continue;

        struct Tiles_Tile tile = AreaCreator_GetRandomMatchingTile(oTile);

        if (tile.nTileID != -1)
        {
            string sTileModel = NWNX_Tileset_GetTileModel(AreaCreator_GetTileset(), tile.nTileID);

            AreaCreator_Tile_SetTileID(oTile, tile.nTileID);
            AreaCreator_Tile_SetTileOrientation(oTile, tile.nOrientation);
            AreaCreator_Tile_SetTileHeight(oTile, tile.nHeight);
            AreaCreator_Tile_SetTileModel(oTile, sTileModel);

            AreaCreator_SetTileEffectOverrideForArea(tile.nTileID, sTileModel);
        }
        else
        {
            ObjectArray_Insert(AREACREATOR_DATA_OBJECT, AREACREATOR_FAILED_TILES_ARRAY_NAME, oTile);
        }
    }

    return ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_FAILED_TILES_ARRAY_NAME);
}

void AreaCreator_GenerateRandomArea(object oPlayer)
{
    struct ProfilerData pd = Profiler_Start("AreaCreator_GenerateRandomArea");
    NWNX_Util_SetInstructionLimit(524288 * 10);

    SendMessageToPC(oPlayer, "* Generating Random Area");

    int nAttempt;
    for (nAttempt = 0; nAttempt < AREACREATOR_RANDOM_AREA_MAX_ATTEMPTS; nAttempt++)
    {
        int nMatchFailures = AreaCreator_GenerateRandomTiles();

        SendMessageToPC(oPlayer, " > Attempt " + IntToString(nAttempt + 1) + " of " + IntToString(AREACREATOR_RANDOM_AREA_MAX_ATTEMPTS) + ": " + IntToString(nMatchFailures) + " tile match failures");

        if (((nAttempt + 1) != AREACREATOR_RANDOM_AREA_MAX_ATTEMPTS) && nMatchFailures)
        {
            int nTile;
            for (nTile = 0; nTile < nMatchFailures; nTile++)
            {
                object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_FAILED_TILES_ARRAY_NAME, nTile);
                AreaCreator_ClearNeighborTiles(oTile);
            }
        }
        else
            break;
    }

    int nTile, nNumTiles = ObjectArray_Size(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME);
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        object oTile = ObjectArray_At(AREACREATOR_DATA_OBJECT, AREACREATOR_CURRENT_TILES_ARRAY_NAME, nTile);
        AreaCreator_UpdateTile(oTile);
    }

    NWNX_Util_SetInstructionLimit(-1);

    Profiler_Stop(pd);
}

// *** Trigger Functions
void AreaCreator_UpdateTrigger()
{
    object oTrigger = GetObjectByTag(AREACREATOR_TRIGGER_TAG);

    if (GetIsObjectValid(oTrigger))
    {
        Events_RemoveObjectFromDispatchList(AREACREATOR_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER), oTrigger);
        Events_RemoveObjectFromDispatchList(AREACREATOR_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT), oTrigger);
        DestroyObject(oTrigger);
    }

    object oTilesWaypoint = GetObjectByTag(AREACREATOR_TILES_WAYPOINT_TAG);
    vector vTilesWaypoint = GetPosition(oTilesWaypoint);
    object oArea = GetArea(oTilesWaypoint);
    int nCurrentWidth = AreaCreator_GetCurrentWidth();
    int nCurrentHeight = AreaCreator_GetCurrentHeight();
    float fTileSize = AREACREATOR_TILES_TILE_SIZE * AREACREATOR_TILES_TILE_SCALE;

    vector vCenter = vTilesWaypoint;
    vCenter.x += ((nCurrentWidth / 2) * fTileSize);
    vCenter.y += ((nCurrentHeight / 2) * fTileSize);

    oTrigger = NWNX_Area_CreateGenericTrigger(oArea, vCenter.x, vCenter.y, 0.0f, AREACREATOR_TRIGGER_TAG, 1.0f);

    string sGeometry = "{" + FloatToString(vTilesWaypoint.x) + ", " + FloatToString(vTilesWaypoint.y) + "}" +
                       "{" + FloatToString(vTilesWaypoint.x + (nCurrentWidth * fTileSize)) + ", " + FloatToString(vTilesWaypoint.y) + "}" +
                       "{" + FloatToString(vTilesWaypoint.x + (nCurrentWidth * fTileSize)) + ", " + FloatToString(vTilesWaypoint.y + (nCurrentHeight * fTileSize)) + "}" +
                       "{" + FloatToString(vTilesWaypoint.x) + ", " + FloatToString(vTilesWaypoint.y + (nCurrentHeight * fTileSize)) + "}";
    NWNX_Object_SetTriggerGeometry(oTrigger, sGeometry);

    Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER, FALSE);
    Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT, FALSE);

    Events_AddObjectToDispatchList(AREACREATOR_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER), oTrigger);
    Events_AddObjectToDispatchList(AREACREATOR_SCRIPT_NAME, Events_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT), oTrigger);
}

void AreaCreator_HandleTrigger(int nEvent)
{
    object oPlayer;
    location locPlayer;

    if (nEvent == EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER)
    {
        oPlayer = GetEnteringObject();
        locPlayer = GetLocation(oPlayer);

        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, 0.45f);
        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_SCALE, AREACREATOR_TILES_TILE_SCALE);
        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_ANIMATION_SPEED, 1 / AREACREATOR_TILES_TILE_SCALE);

        /*
        effect eMovementSpeedDecrease = TagEffect(EffectMovementSpeedDecrease(75), "AC_SLOW_EFFECT");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eMovementSpeedDecrease, oPlayer);

        float fCameraHeight = StringToFloat(Get2DAString("appearance", "HEIGHT", GetAppearanceType(oPlayer))) * 0.5f;
        SetCameraHeight(oPlayer, fCameraHeight);
        */

    }
    else if (nEvent == EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT)
    {
        oPlayer = GetExitingObject();
        locPlayer = GetLocation(oPlayer);

        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, 0.0f);
        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_SCALE, 1.0f);
        SetObjectVisualTransform(oPlayer, OBJECT_VISUAL_TRANSFORM_ANIMATION_SPEED, 1.0f);

        /*
        Effects_RemoveEffectsWithTag(oPlayer, "AC_SLOW_EFFECT");

        SetCameraHeight(oPlayer);
        */
    }

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_GAS_EXPLOSION_MIND), locPlayer);
}

