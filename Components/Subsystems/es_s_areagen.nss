/*
    ScriptName: es_s_areagen.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Area Player Tileset]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_toolbox"
#include "es_srv_tiles"
#include "es_srv_simdialog"

#include "nwnx_area"
#include "nwnx_player"
#include "nwnx_tileset"

const string AREAGENERATOR_LOG_TAG                      = "AreaGenerator";
const string AREAGENERATOR_SCRIPT_NAME                  = "es_s_areagen";
object AREAGENERATOR_DATA_OBJECT                        = ES_Util_GetDataObject(AREAGENERATOR_SCRIPT_NAME);

const string AREAGENERATOR_WP_CENTER_TAG                = "WP_AREAGEN_CENTER";

const int AREAGENERATOR_TILESET_MAX_TILES               = 2000;
const string AREAGENERATOR_VISUALEFFECT_DUMMY_NAME      = "dummy_tile_";
const int AREAGENERATOR_RANDOM_AREA_MAX_ATTEMPTS        = 99;
const float AREAGENERATOR_GENERATION_DELAY              = 0.1f;
const string AREAGENERATOR_DISPLAY_TAG                  = "AG_DISPLAY";
const string AREAGENERATOR_DISPLAY_TEMPLATE             = "AreaGeneratorDisplayTemplate";
const int AREAGENERATOR_VISUALEFFECT_START_ROW          = 1000;
const int AREAGENERATOR_INVALID_TILE_ID                 = -1;

const int AREAGENERATOR_TILES_MIN_WIDTH                 = 1;
const int AREAGENERATOR_TILES_MIN_HEIGHT                = 1;
const int AREAGENERATOR_TILES_MAX_WIDTH                 = 32;
const int AREAGENERATOR_TILES_MAX_HEIGHT                = 32;
const int AREAGENERATOR_TILES_DEFAULT_WIDTH             = 24;
const int AREAGENERATOR_TILES_DEFAULT_HEIGHT            = 12;
const float AREAGENERATOR_TILES_TILE_SIZE               = 10.0f;
const float AREAGENERATOR_TILES_TILE_SCALE              = 0.125f;
const float AREAGENERATOR_LERP_DURATION                 = 10.0f;

const string AREAGENERATOR_ARRAY_TILEID_NAME            = "AreaGeneratorTileIDArray_";
const string AREAGENERATOR_ARRAY_TILEMODEL_NAME         = "AreaGeneratorTileModelArray_";
const string AREAGENERATOR_ARRAY_TILEORIENTATION_NAME   = "AreaGeneratorTileOrientationArray_";
const string AREAGENERATOR_ARRAY_TILEHEIGHT_NAME        = "AreaGeneratorTileHeightArray_";
const string AREAGENERATOR_ARRAY_FAILED_TILES_NAME      = "AreaGeneratorFailedTiles";

const int AREAGENERATOR_NEIGHBOR_TILE_TOP_LEFT          = 0;
const int AREAGENERATOR_NEIGHBOR_TILE_TOP               = 1;
const int AREAGENERATOR_NEIGHBOR_TILE_TOP_RIGHT         = 2;
const int AREAGENERATOR_NEIGHBOR_TILE_RIGHT             = 3;
const int AREAGENERATOR_NEIGHBOR_TILE_BOTTOM_RIGHT      = 4;
const int AREAGENERATOR_NEIGHBOR_TILE_BOTTOM            = 5;
const int AREAGENERATOR_NEIGHBOR_TILE_BOTTOM_LEFT       = 6;
const int AREAGENERATOR_NEIGHBOR_TILE_LEFT              = 7;

void AreaGenerator_SetTileset(string sTileset, string sEdgeTerrainType);
void AreaGenerator_ClearTiles();

void AreaGenerator_CreateConversation(string sSubsystemScript);
void AreaGenerator_StartConversation(object oPlayer);
void AreaGenerator_HandleConversation(string sEvent);

void AreaGenerator_UpdateTileEffectOverrides(object oPlayer);
void AreaGenerator_UpdateTileEffectOverridesForArea();
void AreaGenerator_SetTileEffectOverride(object oPlayer, object oOverrideDataObject, int nTile, string sTileModel);
void AreaGenerator_SetTileEffectOverrideForArea(int nTile, string sTileModel);
object AreaGenerator_GetTileEffectOverrideDataObject(object oPlayer);
void AreaGenerator_DestroyTileEffectOverrideDataObject(object oPlayer);
void AreaGenerator_DestroyAllTileEffectOverrideDataObjects();

int AreaGenerator_GetNeighborTile(int nTile, int nDirection);
struct NWNX_Tileset_TileEdgesAndCorners AreaGenerator_GetNeighborEdgesAndCorners(int nTile, int nDirection);
string AreaGenerator_HandleCornerConflict(string sCorner1, string sCorner2);
struct Tiles_Tile AreaGenerator_GetRandomMatchingTile(int nTile);
void AreaGenerator_ClearNeighborTiles(int nTile);
int AreaGenerator_GenerateRandomTiles();
void AreaGenerator_DelayedGeneration(object oPlayer, int nAttempt = 0, int bDone = FALSE);
void AreaGenerator_GenerateArea(object oPlayer);

void AreaGenerator_InitSolver(cassowary cSolver);
void AreaGenerator_SetupSolvers();
float AreaGenerator_GetSolverValue(cassowary cSolver, float fInput);
void AreaGenerator_SetupDisplay();
void AreaGenerator_DisplayArea(object oPlayer);
void AreaGenerator_SetAreaDimensions(int nWidth, int nHeight);

void AreaGenerator_PreloadAreaList();
void AreaGenerator_LoadExistingArea(object oArea);

// @Load
void AreaGenerator_Load(string sSubsystemScript)
{
    object oArea = GetArea(GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG));
    SetLocalInt(oArea, sSubsystemScript, TRUE);

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_ENTER, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_AREA_ON_EXIT, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);
    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_ENTER), oArea);
    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_AREA_ON_EXIT), oArea);

    AreaGenerator_CreateConversation(sSubsystemScript);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, TRUE);
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE");
    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_SERVER_SEND_AREA_BEFORE");

    AreaGenerator_SetupSolvers();
    AreaGenerator_SetAreaDimensions(AREAGENERATOR_TILES_DEFAULT_WIDTH, AREAGENERATOR_TILES_DEFAULT_HEIGHT);

    // Process the Medieval Rural 2 Tileset if it is not done so in Tiles_Load()
    string sTileset = TILESET_RESREF_MEDIEVAL_RURAL_2;
    Tiles_ProcessTileset(sTileset);

    AreaGenerator_SetTileset(sTileset, "");
    // Ignoring these because I am lazy
    Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, "Chasm", TRUE);
    Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, "Road", TRUE);
    Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, "Wall", TRUE);
    Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, "Bridge", TRUE);
    Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, "Street", TRUE);

    AreaGenerator_SetupDisplay();
    AreaGenerator_PreloadAreaList();
}

// @Test
void AreaGenerator_Test(string sSubsystemScript)
{
    object oObject;

    oObject = GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG);
        Test_Assert("Waypoint With Tag '" + AREAGENERATOR_WP_CENTER_TAG + "' Exists",
            (GetIsObjectValid(oObject) && NWNX_Object_GetInternalObjectType(oObject) == NWNX_OBJECT_TYPE_INTERNAL_WAYPOINT));
}

// @EventHandler
void AreaGenerator_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_SERVER_SEND_AREA_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oArea = Events_GetEventData_NWNX_Object("AREA");

        if (GetLocalInt(oArea, sSubsystemScript))
            AreaGenerator_UpdateTileEffectOverrides(oPlayer);
    }
    else
    if (sEvent == "NWNX_ON_INPUT_TOGGLE_PAUSE_BEFORE")
    {
        object oPlayer = OBJECT_SELF;

        if (GetArea(oPlayer) == GetArea(GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG)))
        {
            AreaGenerator_StartConversation(oPlayer);
            Events_SkipEvent();
        }
    }
    else if (SimpleDialog_GetIsDialogEvent(sEvent))
    {
        AreaGenerator_HandleConversation(sEvent);
    }
    else
    {
        int nEvent = StringToInt(sEvent);
        switch (nEvent)
        {
            case EVENT_SCRIPT_AREA_ON_ENTER:
            {
                object oPlayer = GetEnteringObject();
                object oArea = OBJECT_SELF;

                if (ES_Util_GetIsPC(oPlayer))
                {
                    Events_AddObjectToDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
                    Events_AddObjectToDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, oPlayer);
                    Events_AddObjectToDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, oPlayer);
                }

                break;
            }

            case EVENT_SCRIPT_AREA_ON_EXIT:
            {
                object oPlayer = GetExitingObject();
                object oArea = OBJECT_SELF;

                if (ES_Util_GetIsPC(oPlayer))
                {
                    if (SimpleDialog_IsInConversation(oPlayer, sSubsystemScript))
                        SimpleDialog_AbortConversation(oPlayer);

                    Events_RemoveObjectFromDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, oPlayer);
                    Events_RemoveObjectFromDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, oPlayer);
                    Events_RemoveObjectFromDispatchList(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, oPlayer);

                    AreaGenerator_DestroyTileEffectOverrideDataObject(oPlayer);
                }

                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                object oPlayer = GetExitingObject();

                AreaGenerator_DestroyTileEffectOverrideDataObject(oPlayer);
                break;
            }
        }
    }
}

void AreaGenerator_SetCurrentWidth(int nWidth) { SetLocalInt(AREAGENERATOR_DATA_OBJECT, "CURRENT_WIDTH", nWidth); }
int AreaGenerator_GetCurrentWidth() { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, "CURRENT_WIDTH"); }
void AreaGenerator_SetCurrentHeight(int nHeight) { SetLocalInt(AREAGENERATOR_DATA_OBJECT, "CURRENT_HEIGHT", nHeight); }
int AreaGenerator_GetCurrentHeight() { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, "CURRENT_HEIGHT"); }
int AreaGenerator_GetNumTiles() { return AreaGenerator_GetCurrentWidth() * AreaGenerator_GetCurrentHeight(); }

void AreaGenerator_Tile_SetTileID(int nTile, int nTileID) { SetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEID_NAME + IntToString(nTile), nTileID); }
int AreaGenerator_Tile_GetTileID(int nTile) { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEID_NAME + IntToString(nTile)); }
void AreaGenerator_Tile_SetTileModel(int nTile, string sTileModel) { SetLocalString(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEMODEL_NAME + IntToString(nTile), sTileModel); }
string AreaGenerator_Tile_GetTileModel(int nTile) { return GetLocalString(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEMODEL_NAME + IntToString(nTile)); }
void AreaGenerator_Tile_SetTileOrientation(int nTile, int nOrientation) { SetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEORIENTATION_NAME + IntToString(nTile), nOrientation); }
int AreaGenerator_Tile_GetTileOrientation(int nTile) { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEORIENTATION_NAME + IntToString(nTile)); }
void AreaGenerator_Tile_SetTileHeight(int nTile, int nHeight) { SetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEHEIGHT_NAME + IntToString(nTile), nHeight); }
int AreaGenerator_Tile_GetTileHeight(int nTile) { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_TILEHEIGHT_NAME + IntToString(nTile)); }

int AreaGenerator_Player_GetTilesetPage(object oPlayer) { return GetLocalInt(oPlayer, "AG_TILESET_PAGE"); }
void AreaGenerator_Player_SetTilesetPage(object oPlayer, int nPage) { SetLocalInt(oPlayer, "AG_TILESET_PAGE", nPage); }
int AreaGenerator_Player_GetAreaSizeMode(object oPlayer) { return GetLocalInt(oPlayer, "AG_AREA_SIZE_MODE"); }
void AreaGenerator_Player_SetAreaSizeMode(object oPlayer, int nMode) { SetLocalInt(oPlayer, "AG_AREA_SIZE_MODE", nMode); }

string AreaGenerator_GetTileset() { return GetLocalString(AREAGENERATOR_DATA_OBJECT, "TILESET_NAME"); }
int AreaGenerator_GetTilesetNumTileData() { return GetLocalInt(AREAGENERATOR_DATA_OBJECT, "TILESET_NUM_TILE_DATA"); }
float AreaGenerator_GetTilesetHeightTransition() { return GetLocalFloat(AREAGENERATOR_DATA_OBJECT, "TILESET_HEIGHT_TRANSITION"); }
string AreaGenerator_GetTilesetEdgeTerrainType() { return GetLocalString(AREAGENERATOR_DATA_OBJECT, "TILESET_EDGE_TERRAIN_TYPE"); }
void AreaGenerator_SetTilesetEdgeTerrainType(string sTerrain) { SetLocalString(AREAGENERATOR_DATA_OBJECT, "TILESET_EDGE_TERRAIN_TYPE", sTerrain); }

cassowary AreaGenerator_GetXSolver() { return GetLocalCassowary(AREAGENERATOR_DATA_OBJECT, "AG_SOLVER_X"); }
cassowary AreaGenerator_GetYSolver() { return GetLocalCassowary(AREAGENERATOR_DATA_OBJECT, "AG_SOLVER_Y"); }

void AreaGenerator_SetTileset(string sTileset, string sEdgeTerrainType)
{
    if (AreaGenerator_GetTileset() == sTileset)
        return;

    int nNumTileData = Tiles_GetTilesetNumTileData(sTileset);
    float fHeightTransition = Tiles_GetTilesetHeightTransition(sTileset);

    if (nNumTileData > AREAGENERATOR_TILESET_MAX_TILES)
        ES_Util_Log(AREAGENERATOR_LOG_TAG , "WARNING: Tileset '" + sTileset + "' has more than " + IntToString(AREAGENERATOR_TILESET_MAX_TILES) + " tiles! (" + IntToString(nNumTileData) + ")");

    AreaGenerator_DestroyAllTileEffectOverrideDataObjects();

    AreaGenerator_ClearTiles();

    SetLocalString(AREAGENERATOR_DATA_OBJECT, "TILESET_NAME", sTileset);
    AreaGenerator_SetTilesetEdgeTerrainType(sEdgeTerrainType);
    SetLocalInt(AREAGENERATOR_DATA_OBJECT, "TILESET_NUM_TILE_DATA", nNumTileData);
    SetLocalFloat(AREAGENERATOR_DATA_OBJECT, "TILESET_HEIGHT_TRANSITION", fHeightTransition);
}

void AreaGenerator_ClearTiles()
{
    int nTile, nNumTiles = AreaGenerator_GetNumTiles();
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
         AreaGenerator_Tile_SetTileID(nTile, AREAGENERATOR_INVALID_TILE_ID);
    }
}

void AreaGenerator_SetAreaDimensions(int nWidth, int nHeight)
{
    cassowary cSolverX = AreaGenerator_GetXSolver();
    cassowary cSolverY = AreaGenerator_GetYSolver();

    nWidth = nWidth > AREAGENERATOR_TILES_MAX_WIDTH ? AREAGENERATOR_TILES_MAX_WIDTH :
             nWidth < AREAGENERATOR_TILES_MIN_WIDTH ? AREAGENERATOR_TILES_MIN_WIDTH : nWidth;
    nHeight = nHeight > AREAGENERATOR_TILES_MAX_HEIGHT ? AREAGENERATOR_TILES_MAX_HEIGHT :
              nHeight < AREAGENERATOR_TILES_MIN_HEIGHT ? AREAGENERATOR_TILES_MIN_HEIGHT : nHeight;

    AreaGenerator_SetCurrentWidth(nWidth);
    AreaGenerator_SetCurrentHeight(nHeight);

    CassowarySuggestValue(cSolverX, "LENGTH", IntToFloat(nWidth));
    CassowarySuggestValue(cSolverY, "LENGTH", IntToFloat(nHeight));
}

// *** Conversation Functions
const int AREAGENERATOR_CV_PAGE_MAINMENU = 1;
const int AREAGENERATOR_CV_PAGE_SELECTTILESET = 2;
const int AREAGENERATOR_CV_PAGE_SELECTTILEEDGE = 3;
const int AREAGENERATOR_CV_PAGE_IGNORETERRAIN = 4;
const int AREAGENERATOR_CV_PAGE_IGNORECROSSER = 5;
const int AREAGENERATOR_CV_PAGE_CHANGEAREASIZE = 6;
const int AREAGENERATOR_CV_PAGE_MODIFYAREASIZE = 7;
const int AREAGENERATOR_CV_PAGE_LOADEXISTINGAREA = 8;

void AreaGenerator_CreateConversation(string sSubsystemScript)
{
    object oConversation = SimpleDialog_CreateConversation(sSubsystemScript);

    SimpleDialog_AddPage(oConversation, "Area Generator - Main Menu"); // Page 1
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Generate Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Display Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Tileset Selection]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Edge Terrain Selection]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Ignore Terrain]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Ignore Crosser]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Change Area Size]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Load Existing Area]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Close]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Select Tileset"); // Page 2
        SimpleDialog_AddOptions(oConversation, "Tileset", 10, TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Next]"), TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Previous]"), TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Select Tile Edge"); // Page 3
        SimpleDialog_AddOption(oConversation, "None", TRUE);
        SimpleDialog_AddOptions(oConversation, "Terrain", 11, TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Ignore Terrain"); // Page 4
        SimpleDialog_AddOptions(oConversation, "Terrain", 11, TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Ignore Crosser"); // Page 5
        SimpleDialog_AddOptions(oConversation, "Crosser", 11, TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Change Area Size", TRUE); // Page 6
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Modify Width]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Modify Height]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Modify Area ", TRUE); // Page 7
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[+1]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[+5]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[+10]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[-1]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[-5]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[-10]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Area Generator - Load Existing Area"); // Page 8
        SimpleDialog_AddOptions(oConversation, "Area", 10, TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));
}

void AreaGenerator_StartConversation(object oPlayer)
{
    SimpleDialog_StartConversation(oPlayer, oPlayer, AREAGENERATOR_SCRIPT_NAME);
}

void AreaGenerator_HandleConversation(string sEvent)
{
    object oPlayer = OBJECT_SELF;
    string sConversation = Events_GetEventData_NWNX_String("CONVERSATION_TAG");

    if (sConversation != AREAGENERATOR_SCRIPT_NAME)
        return;

    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION)
    {
        int nPage = Events_GetEventData_NWNX_Int("PAGE");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        switch (nPage)
        {
            case AREAGENERATOR_CV_PAGE_SELECTTILESET: // Select Tileset Menu
            {
                switch (nOption)
                {
                    case 1:
                    case 2:
                    case 3:
                    case 4:
                    case 5:
                    case 6:
                    case 7:
                    case 8:
                    case 9:
                    case 10:
                    {
                        int nNumTilesets = Tiles_GetNumProcessedTilesets();
                        int nCurrentPage = AreaGenerator_Player_GetTilesetPage(oPlayer) * 10;
                        int nTilesetID = nCurrentPage + nOption - 1;

                        if (nTilesetID < nNumTilesets)
                        {
                            struct Tiles_TilesetInfo strTTI = Tiles_GetProcessedTilesetInfo(nTilesetID);

                            if (strTTI.sResRef != "")
                            {
                                if (AreaGenerator_GetTileset() == strTTI.sResRef)
                                    SimpleDialog_SetOverrideText(SimpleDialog_Token_Highlight("[" + strTTI.sName + "]"));
                                else
                                    SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[" + strTTI.sName + "]"));

                                SimpleDialog_SetResult(TRUE);
                            }
                        }

                        break;
                    }

                    case 11: // Next
                    {
                        int nCurrentPage = (AreaGenerator_Player_GetTilesetPage(oPlayer) * 10) + 10;
                        int nNumTilesets = Tiles_GetNumProcessedTilesets();

                        if (nNumTilesets > nCurrentPage)
                            SimpleDialog_SetResult(TRUE);

                        break;
                    }

                    case 12: // Previous
                    {
                        int nCurrentPage = AreaGenerator_Player_GetTilesetPage(oPlayer) * 10;
                        int nNumTilesets = Tiles_GetNumProcessedTilesets();

                        if (nCurrentPage > 0)
                            SimpleDialog_SetResult(TRUE);

                        break;
                    }
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_SELECTTILEEDGE: // Edge Terrain Menu
            {
                switch (nOption)
                {
                    case 1: // None
                    {
                        if (AreaGenerator_GetTilesetEdgeTerrainType() == "")
                            SimpleDialog_SetOverrideText(SimpleDialog_Token_Highlight("[None]"));
                        else
                            SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[None]"));

                        SimpleDialog_SetResult(TRUE);
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
                        string sTerrain = Tiles_GetTilesetTerrain(AreaGenerator_GetTileset(), nOption - 2);

                        if (sTerrain != "")
                        {
                            if (AreaGenerator_GetTilesetEdgeTerrainType() == sTerrain)
                                SimpleDialog_SetOverrideText(SimpleDialog_Token_Highlight("[" + sTerrain + "]"));
                            else
                                SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[" + sTerrain + "]"));

                            SimpleDialog_SetResult(TRUE);
                        }

                        break;
                    }
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_IGNORETERRAIN: // Ignore Terrain Menu
            case AREAGENERATOR_CV_PAGE_IGNORECROSSER: // Ignore Crosser Menu
            {
                switch (nOption)
                {
                    case 1: // TerrainOrCrosser0
                    case 2: // TerrainOrCrosser1
                    case 3: // TerrainOrCrosser2
                    case 4: // TerrainOrCrosser3
                    case 5: // TerrainOrCrosser4
                    case 6: // TerrainOrCrosser5
                    case 7: // TerrainOrCrosser6
                    case 8: // TerrainOrCrosser7
                    case 9: // TerrainOrCrosser8
                    case 10:// TerrainOrCrosser9
                    case 11:// TerrainOrCrosser10
                    {
                        string sTileset = AreaGenerator_GetTileset();
                        string sTerrainOrCrosser = (nPage == AREAGENERATOR_CV_PAGE_IGNORETERRAIN ? Tiles_GetTilesetTerrain(sTileset, nOption - 1) : Tiles_GetTilesetCrosser(sTileset, nOption - 1));

                        if (sTerrainOrCrosser != "")
                        {
                            SimpleDialog_SetResult(TRUE);
                            SimpleDialog_SetOverrideText(
                                Tiles_GetTilesetIgnoreTerrainOrCrosser(sTileset, sTerrainOrCrosser) ?
                                    SimpleDialog_Token_Check("[" + sTerrainOrCrosser + "]") : SimpleDialog_Token_Action("[" + sTerrainOrCrosser + "]"));
                        }

                        break;
                    }
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_LOADEXISTINGAREA:
            {
                object oArea = ObjectArray_At(AREAGENERATOR_DATA_OBJECT, "AREA_LIST", nOption - 1);

                if (GetIsObjectValid(oArea))
                {
                    SimpleDialog_SetResult(TRUE);
                    SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[" + GetName(oArea)  + "]"));
                }

                break;
            }
        }
    }
    else if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE)
    {
        int nPage = Events_GetEventData_NWNX_Int("PAGE");

        switch (nPage)
        {
            case AREAGENERATOR_CV_PAGE_CHANGEAREASIZE:
            {
                object oConversation = SimpleDialog_GetConversation(AREAGENERATOR_SCRIPT_NAME);

                SimpleDialog_SetResult(TRUE);
                SimpleDialog_SetOverrideText(SimpleDialog_GetPageText(oConversation, nPage) +
                    "\n\nCurrent Width: " + IntToString(AreaGenerator_GetCurrentWidth()) +
                    "\nCurrent Height: " + IntToString(AreaGenerator_GetCurrentHeight()));

                break;
            }

            case AREAGENERATOR_CV_PAGE_MODIFYAREASIZE:
            {
                object oConversation = SimpleDialog_GetConversation(AREAGENERATOR_SCRIPT_NAME);

                SimpleDialog_SetResult(TRUE);

                int nMode = AreaGenerator_Player_GetAreaSizeMode(oPlayer);
                string sAxis = nMode ? "Height" : "Width";
                int nCurrentValue = nMode ? AreaGenerator_GetCurrentHeight() : AreaGenerator_GetCurrentWidth();

                SimpleDialog_SetOverrideText(SimpleDialog_GetPageText(oConversation, nPage) + sAxis +
                    "\n\nCurrent " + sAxis + ": " + IntToString(nCurrentValue));

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
            case AREAGENERATOR_CV_PAGE_MAINMENU: // Main Menu
            {
                switch (nOption)
                {
                    case 1:// Generate Area
                        AreaGenerator_GenerateArea(oPlayer);
                        break;

                    case 2:// Display Area
                        AreaGenerator_DisplayArea(oPlayer);
                        break;

                    case 3:// Select Tileset Menu
                         SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_SELECTTILESET);
                         break;

                    case 4:// Edge Terrain Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_SELECTTILEEDGE);
                        break;

                    case 5:// Ignore Terrain Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_IGNORETERRAIN);
                        break;

                    case 6:// Ignore Crosser Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_IGNORECROSSER);
                        break;

                    case 7:// Area Size
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_CHANGEAREASIZE);
                        break;

                    case 8:// Load Existing Area
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_LOADEXISTINGAREA);
                        break;

                    case 9:// Close
                        SimpleDialog_EndConversation(oPlayer);
                        break;
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_SELECTTILESET: // Select Tileset Menu
            {
                switch (nOption)
                {
                    case 1:
                    case 2:
                    case 3:
                    case 4:
                    case 5:
                    case 6:
                    case 7:
                    case 8:
                    case 9:
                    case 10:
                    {
                        int nCurrentPage = AreaGenerator_Player_GetTilesetPage(oPlayer) * 10;
                        int nTilesetID = nCurrentPage + nOption - 1;
                        struct Tiles_TilesetInfo strTTI = Tiles_GetProcessedTilesetInfo(nTilesetID);

                        if (strTTI.sResRef != "")
                        {
                            AreaGenerator_SetTileset(strTTI.sResRef, strTTI.sEdgeTerrain);
                            SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        }

                        break;
                    }

                    case 11: // Next
                    case 12: // Previous
                    {
                        int nCurrentPage = AreaGenerator_Player_GetTilesetPage(oPlayer);
                        AreaGenerator_Player_SetTilesetPage(oPlayer, nCurrentPage + (nOption == 11 ? 1 : -1));

                        break;
                    }

                    case 13:// Back to General Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        break;
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_SELECTTILEEDGE: // Edge Terrain Menu
            {
                switch (nOption)
                {
                    case 1:// None
                    {
                        AreaGenerator_SetTilesetEdgeTerrainType("");
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
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
                        AreaGenerator_SetTilesetEdgeTerrainType(Tiles_GetTilesetTerrain(AreaGenerator_GetTileset(), nOption - 2));
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        break;
                    }

                    case 13:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        break;
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_IGNORETERRAIN: // Ignore Terrain Menu
            case AREAGENERATOR_CV_PAGE_IGNORECROSSER: // Ignore Crosser Menu
            {
                switch (nOption)
                {
                    case 1: // Terrain0
                    case 2: // Terrain1
                    case 3: // Terrain2
                    case 4: // Terrain3
                    case 5: // Terrain4
                    case 6: // Terrain5
                    case 7: // Terrain6
                    case 8: // Terrain7
                    case 9: // Terrain8
                    case 10:// Terrain9
                    case 11:// Terrain10
                    {
                        string sTileset = AreaGenerator_GetTileset();
                        string sTerrainOrCrosser = (nPage == AREAGENERATOR_CV_PAGE_IGNORETERRAIN ? Tiles_GetTilesetTerrain(sTileset, nOption - 1) : Tiles_GetTilesetCrosser(sTileset, nOption - 1));

                        Tiles_SetTilesetIgnoreTerrainOrCrosser(sTileset, sTerrainOrCrosser, !Tiles_GetTilesetIgnoreTerrainOrCrosser(sTileset, sTerrainOrCrosser));
                        break;
                    }

                    case 12:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        break;
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_CHANGEAREASIZE:
            {
                switch (nOption)
                {
                    case 1:// Width
                    case 2:// Height
                    {
                        AreaGenerator_Player_SetAreaSizeMode(oPlayer, (nOption - 1));
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MODIFYAREASIZE);
                        break;
                    }

                    case 3:// Back to Main Menu
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                        break;
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_MODIFYAREASIZE:
            {
                if (nOption == 7)// Back to Area Size Menu
                    SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_CHANGEAREASIZE);
                else
                {
                    int nModify = 0;
                    switch (nOption)
                    {
                        case 1: nModify = 1; break;
                        case 2: nModify = 5; break;
                        case 3: nModify = 10; break;
                        case 4: nModify = -1; break;
                        case 5: nModify = -5; break;
                        case 6: nModify = -10; break;
                     }

                     int nWidth = AreaGenerator_GetCurrentWidth();
                     int nHeight = AreaGenerator_GetCurrentHeight();

                     if (AreaGenerator_Player_GetAreaSizeMode(oPlayer))
                        nHeight += nModify;
                     else
                        nWidth += nModify;

                     AreaGenerator_SetAreaDimensions(nWidth, nHeight);
                }

                break;
            }

            case AREAGENERATOR_CV_PAGE_LOADEXISTINGAREA:
            {
                if (nOption == 11)// Back to Main Menu
                    SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                else
                {
                    object oArea = ObjectArray_At(AREAGENERATOR_DATA_OBJECT, "AREA_LIST", nOption - 1);

                    if (GetIsObjectValid(oArea))
                    {
                        AreaGenerator_LoadExistingArea(oArea);
                        SimpleDialog_SetCurrentPage(oPlayer, AREAGENERATOR_CV_PAGE_MAINMENU);
                    }
                }

                break;
            }
        }
    }
}

// *** Tile Effect Model Override Functions
void AreaGenerator_UpdateTileEffectOverrides(object oPlayer)
{
    object oPlayerDataObject = AreaGenerator_GetTileEffectOverrideDataObject(oPlayer);

    int nTile, nNumTiles = AreaGenerator_GetNumTiles();
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        int nTileID = AreaGenerator_Tile_GetTileID(nTile);

        if (nTileID != AREAGENERATOR_INVALID_TILE_ID)
        {
            string sTileModel = AreaGenerator_Tile_GetTileModel(nTile);
            AreaGenerator_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTile, sTileModel);
        }
    }
}

void AreaGenerator_UpdateTileEffectOverridesForArea()
{
    object oArea = GetArea(GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
        {
            DelayCommand(0.0f, AreaGenerator_UpdateTileEffectOverrides(oPlayer));
        }

        oPlayer = GetNextPC();
    }
}

void AreaGenerator_SetTileEffectOverride(object oPlayer, object oOverrideDataObject, int nTile, string sTileModel)
{
    if (!GetLocalInt(oOverrideDataObject, "TILE_" + IntToString(nTile)))
    {
        NWNX_Player_SetResManOverride(oPlayer, 2002, AREAGENERATOR_VISUALEFFECT_DUMMY_NAME + IntToString(nTile), sTileModel);
        SetLocalInt(oOverrideDataObject, "TILE_" + IntToString(nTile), TRUE);
    }
}

void AreaGenerator_SetTileEffectOverrideForArea(int nTile, string sTileModel)
{
    object oArea = GetArea(GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG));
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
        {
            object oPlayerDataObject = AreaGenerator_GetTileEffectOverrideDataObject(oPlayer);
            AreaGenerator_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTile, sTileModel);
        }

        oPlayer = GetNextPC();
    }
}

object AreaGenerator_GetTileEffectOverrideDataObject(object oPlayer)
{
    return ES_Util_GetDataObject("AG_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
}

void AreaGenerator_DestroyTileEffectOverrideDataObject(object oPlayer)
{
    ES_Util_DestroyDataObject("AG_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
}

void AreaGenerator_DestroyAllTileEffectOverrideDataObjects()
{
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        AreaGenerator_DestroyTileEffectOverrideDataObject(oPlayer);
        oPlayer = GetNextPC();
    }
}

// *** Generate Area Functions
int AreaGenerator_GetNeighborTile(int nTile, int nDirection)
{
    int nCurrentWidth = AreaGenerator_GetCurrentWidth();
    int nCurrentHeight = AreaGenerator_GetCurrentHeight();
    int nTileX = nTile % nCurrentWidth;
    int nTileY = nTile / nCurrentWidth;

    switch (nDirection)
    {
        case AREAGENERATOR_NEIGHBOR_TILE_TOP_LEFT:
        {
            if (nTileY == (nCurrentHeight - 1) || nTileX == 0)
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile += (nCurrentWidth - 1);
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_TOP:
        {
            if (nTileY == (nCurrentHeight - 1))
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile += nCurrentWidth;
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_TOP_RIGHT:
        {
            if (nTileY == (nCurrentHeight - 1) || nTileX == (nCurrentWidth - 1))
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile += (nCurrentWidth + 1);
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_RIGHT:
        {
            if (nTileX == (nCurrentWidth - 1))
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile += 1;
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_BOTTOM_RIGHT:
        {
            if (nTileY == 0 || nTileX == (nCurrentWidth - 1))
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile -= (nCurrentWidth - 1);
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_BOTTOM:
        {
            if (nTileY == 0)
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile -= nCurrentWidth;
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_BOTTOM_LEFT:
        {
            if (nTileY == 0 || nTileX == 0)
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile -= (nCurrentWidth + 1);
            break;
        }

        case AREAGENERATOR_NEIGHBOR_TILE_LEFT:
        {
            if (nTileX == 0)
                return AREAGENERATOR_INVALID_TILE_ID;
            else
                nTile -= 1;
            break;
        }
    }

    return nTile;
}

struct NWNX_Tileset_TileEdgesAndCorners AreaGenerator_GetNeighborEdgesAndCorners(int nTile, int nDirection)
{
    struct NWNX_Tileset_TileEdgesAndCorners str;
    int nNeighborTile = AreaGenerator_GetNeighborTile(nTile, nDirection);

    if (nNeighborTile != AREAGENERATOR_INVALID_TILE_ID)
    {
        string sTileset = AreaGenerator_GetTileset();
        int nTileID = AreaGenerator_Tile_GetTileID(nNeighborTile);
        int nOrientation = AreaGenerator_Tile_GetTileOrientation(nNeighborTile);
        int nHeight = AreaGenerator_Tile_GetTileHeight(nNeighborTile);

        if (nTileID != AREAGENERATOR_INVALID_TILE_ID)
            str = Tiles_GetCornersAndEdgesByOrientation(sTileset, nTileID, nOrientation);

        if (sTileset == TILESET_RESREF_RURAL && nHeight == 1)
            str = Tiles_ReplaceTerrainOrCrosser(str, "Grass", "Grass+");
    }
    else
    {
        string sEdgeTerrainType = AreaGenerator_GetTilesetEdgeTerrainType();

        switch (nDirection)
        {
            case AREAGENERATOR_NEIGHBOR_TILE_TOP:
            {
                str.sBottomLeft = sEdgeTerrainType;
                str.sBottom = sEdgeTerrainType;
                str.sBottomRight = sEdgeTerrainType;
                break;
            }

            case AREAGENERATOR_NEIGHBOR_TILE_RIGHT:
            {
                str.sTopLeft = sEdgeTerrainType;
                str.sLeft = sEdgeTerrainType;
                str.sBottomLeft = sEdgeTerrainType;
                break;
            }

            case AREAGENERATOR_NEIGHBOR_TILE_BOTTOM:
            {
                str.sTopLeft = sEdgeTerrainType;
                str.sTop = sEdgeTerrainType;
                str.sTopRight = sEdgeTerrainType;
                break;
            }

            case AREAGENERATOR_NEIGHBOR_TILE_LEFT:
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

string AreaGenerator_HandleCornerConflict(string sCorner1, string sCorner2)
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

struct Tiles_Tile AreaGenerator_GetRandomMatchingTile(int nTile)
{
    struct NWNX_Tileset_TileEdgesAndCorners strQuery;

    struct NWNX_Tileset_TileEdgesAndCorners strTop = AreaGenerator_GetNeighborEdgesAndCorners(nTile, AREAGENERATOR_NEIGHBOR_TILE_TOP);
    struct NWNX_Tileset_TileEdgesAndCorners strRight = AreaGenerator_GetNeighborEdgesAndCorners(nTile, AREAGENERATOR_NEIGHBOR_TILE_RIGHT);
    struct NWNX_Tileset_TileEdgesAndCorners strBottom = AreaGenerator_GetNeighborEdgesAndCorners(nTile, AREAGENERATOR_NEIGHBOR_TILE_BOTTOM);
    struct NWNX_Tileset_TileEdgesAndCorners strLeft = AreaGenerator_GetNeighborEdgesAndCorners(nTile, AREAGENERATOR_NEIGHBOR_TILE_LEFT);

    strQuery.sTop = strTop.sBottom;
    strQuery.sRight = strRight.sLeft;
    strQuery.sBottom = strBottom.sTop;
    strQuery.sLeft = strLeft.sRight;

    strQuery.sTopLeft = AreaGenerator_HandleCornerConflict(strTop.sBottomLeft, strLeft.sTopRight);
    strQuery.sTopRight = AreaGenerator_HandleCornerConflict(strTop.sBottomRight, strRight.sTopLeft);
    strQuery.sBottomRight = AreaGenerator_HandleCornerConflict(strRight.sBottomLeft, strBottom.sTopRight);
    strQuery.sBottomLeft = AreaGenerator_HandleCornerConflict(strBottom.sTopLeft, strLeft.sBottomRight);

    return Tiles_GetRandomMatchingTile(AreaGenerator_GetTileset(), strQuery);
}

void AreaGenerator_ClearNeighborTiles(int nTile)
{
    int nDirection;
    for (nDirection = 0; nDirection < 8; nDirection++)
    {
        int nNeighborTile = AreaGenerator_GetNeighborTile(nTile, nDirection);

        if (nNeighborTile != AREAGENERATOR_INVALID_TILE_ID)
            AreaGenerator_Tile_SetTileID(nNeighborTile, AREAGENERATOR_INVALID_TILE_ID);
    }
}

int AreaGenerator_GenerateRandomTiles()
{
    IntArray_Clear(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_FAILED_TILES_NAME, TRUE);

    int nTile, nNumTiles = AreaGenerator_GetNumTiles();
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        NWNX_Util_SetInstructionsExecuted(0);

        if (AreaGenerator_Tile_GetTileID(nTile) != AREAGENERATOR_INVALID_TILE_ID)
            continue;

        struct Tiles_Tile tile = AreaGenerator_GetRandomMatchingTile(nTile);

        if (tile.nTileID != AREAGENERATOR_INVALID_TILE_ID)
        {
            string sTileModel = Tiles_GetTileModel(AreaGenerator_GetTileset(), tile.nTileID);

            AreaGenerator_Tile_SetTileID(nTile, tile.nTileID);
            AreaGenerator_Tile_SetTileOrientation(nTile, tile.nOrientation);
            AreaGenerator_Tile_SetTileHeight(nTile, tile.nHeight);
            AreaGenerator_Tile_SetTileModel(nTile, sTileModel);
        }
        else
        {
            IntArray_Insert(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_FAILED_TILES_NAME, nTile);
        }
    }

    return IntArray_Size(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_FAILED_TILES_NAME);
}

void AreaGenerator_DelayedGeneration(object oPlayer, int nAttempt = 0, int bDone = FALSE)
{
    if (!bDone)
    {
        int nMatchFailures = AreaGenerator_GenerateRandomTiles();

        SendMessageToPC(oPlayer, " > Attempt " + IntToString(nAttempt + 1) + ": " + IntToString(nMatchFailures) + " tile match failures");

        if (nMatchFailures)
        {
            int nTileFailureIndex;
            for (nTileFailureIndex = 0; nTileFailureIndex < nMatchFailures; nTileFailureIndex++)
            {
                int nTile = IntArray_At(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_ARRAY_FAILED_TILES_NAME, nTileFailureIndex);
                AreaGenerator_ClearNeighborTiles(nTile);
            }
        }

        bDone = !nMatchFailures || nAttempt >= AREAGENERATOR_RANDOM_AREA_MAX_ATTEMPTS;

        DelayCommand(AREAGENERATOR_GENERATION_DELAY, AreaGenerator_DelayedGeneration(oPlayer, ++nAttempt, bDone));
    }
    else
    {
        AreaGenerator_DestroyAllTileEffectOverrideDataObjects();
        AreaGenerator_UpdateTileEffectOverridesForArea();

        DeleteLocalInt(AREAGENERATOR_DATA_OBJECT, "GENERATING_AREA");

        SendMessageToPC(oPlayer, "* Done!");
    }
}

void AreaGenerator_GenerateArea(object oPlayer)
{
    if (!GetLocalInt(AREAGENERATOR_DATA_OBJECT, "GENERATING_AREA"))
    {
        SendMessageToPC(oPlayer, "* Generating Area");

        SetLocalInt(AREAGENERATOR_DATA_OBJECT, "GENERATING_AREA", TRUE);

        AreaGenerator_ClearTiles();
        AreaGenerator_DelayedGeneration(oPlayer);
    }
    else
    {
        SendMessageToPC(oPlayer, "* Area is currently being generated!");
    }
}

// *** Display Area Functions
void AreaGenerator_InitSolver(cassowary cSolver)
{
    string sScale = FloatToString(AREAGENERATOR_TILES_TILE_SIZE * AREAGENERATOR_TILES_TILE_SCALE, 0, 2);

    CassowaryConstrain(cSolver, "MAX == (LENGTH - 1) * " + sScale);
    CassowaryConstrain(cSolver, "CENTER == MAX * 0.5");
    CassowaryConstrain(cSolver, "OUTPUT == (CENTER + (INPUT * " + sScale + ")) - MAX");
}

void AreaGenerator_SetupSolvers()
{
    cassowary cSolverX, cSolverY;

    AreaGenerator_InitSolver(cSolverX);
    AreaGenerator_InitSolver(cSolverY);

    SetLocalCassowary(AREAGENERATOR_DATA_OBJECT, "AG_SOLVER_X", cSolverX);
    SetLocalCassowary(AREAGENERATOR_DATA_OBJECT, "AG_SOLVER_Y", cSolverY);
}

float AreaGenerator_GetSolverValue(cassowary cSolver, float fInput)
{
    CassowarySuggestValue(cSolver, "INPUT", fInput);
    return CassowaryGetValue(cSolver, "OUTPUT");
}

void AreaGenerator_SetupDisplay()
{
    struct Toolbox_PlaceableData pd;
    pd.nModel = TOOLBOX_INVISIBLE_PLACEABLE_MODEL_ID;
    pd.sName = "AreaDisplay";
    pd.sTag = AREAGENERATOR_DISPLAY_TAG;
    pd.bPlot = TRUE;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    SetLocalString(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_DISPLAY_TEMPLATE, sPlaceableData);
}

void AreaGenerator_RotateDisplay(object oDisplay, int bStart)
{
    if (GetIsObjectValid(oDisplay))
    {
        SetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_X, GetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_X) + 90.0f,
                                 OBJECT_VISUAL_TRANSFORM_LERP_LINEAR, AREAGENERATOR_LERP_DURATION);

        if (bStart)
        {
            SetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_Y, GetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_Y) + 7.5f,
                                     OBJECT_VISUAL_TRANSFORM_LERP_LINEAR, AREAGENERATOR_LERP_DURATION);
            SetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, GetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z) + 1.0f,
                                     OBJECT_VISUAL_TRANSFORM_LERP_LINEAR, AREAGENERATOR_LERP_DURATION);
        }
        else
        {
            SetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_Y, GetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_ROTATE_Y) - 7.5f,
                                     OBJECT_VISUAL_TRANSFORM_LERP_LINEAR, AREAGENERATOR_LERP_DURATION);
            SetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, GetObjectVisualTransform(oDisplay, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z) - 1.0f,
                                     OBJECT_VISUAL_TRANSFORM_LERP_LINEAR, AREAGENERATOR_LERP_DURATION);
        }

        DelayCommand(AREAGENERATOR_LERP_DURATION, AreaGenerator_RotateDisplay(oDisplay, !bStart));
    }
}

void AreaGenerator_DelayedApplyEffect(object oDisplay, int nTile, cassowary cSolverX, cassowary cSolverY)
{
    int nTileID = AreaGenerator_Tile_GetTileID(nTile);

    if (nTileID == AREAGENERATOR_INVALID_TILE_ID)
        return;

    int nCurrentWidth = AreaGenerator_GetCurrentWidth();
    int tileX = nTile % nCurrentWidth;
    int tileY = nTile / nCurrentWidth;
    float fX = AreaGenerator_GetSolverValue(cSolverX, IntToFloat(tileX));
    float fY = AreaGenerator_GetSolverValue(cSolverY, IntToFloat(tileY));
    float fZ = 0.5f + (AreaGenerator_Tile_GetTileHeight(nTile) * (AreaGenerator_GetTilesetHeightTransition() * AREAGENERATOR_TILES_TILE_SCALE));
    vector vTranslate = Vector(fX, fY, fZ);
    vector vRotate = Vector((AreaGenerator_Tile_GetTileOrientation(nTile) * 90.0f), 0.0f, 0.0f);
    effect eTile = TagEffect(EffectVisualEffect(AREAGENERATOR_VISUALEFFECT_START_ROW + nTile, FALSE, AREAGENERATOR_TILES_TILE_SCALE, vTranslate, vRotate), "TILE_" + IntToString(nTile));

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oDisplay);
}

void AreaGenerator_DisplayArea(object oPlayer)
{
    if (!GetLocalInt(AREAGENERATOR_DATA_OBJECT, "GENERATING_AREA"))
    {
        object oDisplay = GetObjectByTag(AREAGENERATOR_DISPLAY_TAG);
        location locSpawn = GetLocation(GetObjectByTag(AREAGENERATOR_WP_CENTER_TAG));
        cassowary cSolverX = AreaGenerator_GetXSolver();
        cassowary cSolverY = AreaGenerator_GetYSolver();

        if (GetIsObjectValid(oDisplay))
            DestroyObject(oDisplay);

        oDisplay = Toolbox_CreatePlaceable(GetLocalString(AREAGENERATOR_DATA_OBJECT, AREAGENERATOR_DISPLAY_TEMPLATE), locSpawn);

        int nTile, nNumTiles = AreaGenerator_GetNumTiles();
        for (nTile = 0; nTile < nNumTiles; nTile++)
        {
            DelayCommand(0.01f * nTile, AreaGenerator_DelayedApplyEffect(oDisplay, nTile, cSolverX, cSolverY));
        }

        AssignCommand(GetModule(), AreaGenerator_RotateDisplay(oDisplay, TRUE));
    }
    else
    {
        SendMessageToPC(oPlayer, "* Area is currently being generated!");
    }
}

// *** Load Existing Area Functions
void AreaGenerator_PreloadAreaList()
{
    object oArea = GetFirstArea();
    while (oArea != OBJECT_INVALID)
    {
        ObjectArray_Insert(AREAGENERATOR_DATA_OBJECT, "AREA_LIST", oArea);

        oArea = GetNextArea();
    }
}

void AreaGenerator_LoadExistingArea(object oArea)
{
    string sTileset = GetTilesetResRef(oArea);
    int nWidth = GetAreaSize(AREA_WIDTH, oArea);
    int nHeight = GetAreaSize(AREA_HEIGHT, oArea);

    AreaGenerator_DestroyAllTileEffectOverrideDataObjects();
    AreaGenerator_SetTileset(sTileset, "");
    AreaGenerator_SetAreaDimensions(nWidth, nHeight);

    int nY, nX, nTile = 0;
    for (nY = 0; nY < nHeight; nY++)
    {
        for (nX = 0; nX < nWidth; nX++)
        {
            float fX = nX * 10.0f;
            float fY = nY * 10.0f;
            struct NWNX_Area_TileInfo strTI = NWNX_Area_GetTileInfo(oArea, fX, fY);

            AreaGenerator_Tile_SetTileID(nTile, strTI.nID);
            AreaGenerator_Tile_SetTileHeight(nTile, strTI.nHeight);
            AreaGenerator_Tile_SetTileOrientation(nTile, strTI.nOrientation);
            AreaGenerator_Tile_SetTileModel(nTile, Tiles_GetTileModel(sTileset, strTI.nID));

            nTile++;
        }
    }

    AreaGenerator_UpdateTileEffectOverridesForArea();
}

