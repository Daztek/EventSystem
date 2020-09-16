/*
    ScriptName: es_s_areacreator.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player Tileset]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_cc_profiler"
#include "es_srv_chatcom"
#include "es_srv_toolbox"
#include "es_srv_wangtiles"

#include "nwnx_player"
#include "nwnx_tileset"

const string AREACREATOR_LOG_TAG                    = "AreaCreator";
const string AREACREATOR_SCRIPT_NAME                = "es_s_areacreator";

const string AREACREATOR_TEMPLATE_RESREF            = "are_cretemp";

const string AREACREATOR_TILE_GRID_TAG              = "AC_TILE_GRID_START";
const string AREACREATOR_PREVIEW_GRID_TAG           = "AC_PREVIEW_GRID_START";

const float AREACREATOR_TILE_SIZE                   = 10.0f;
const float AREACREATOR_TILE_SCALE                  = 0.25f;

const int AREACREATOR_TILESET_MAX_TILES             = 2000;
const int AREACREATOR_EFFECT_START                  = 1000;
const float AREACREATOR_TILE_EFFECT_APPLY_DELAY     = 0.1f;
const string AREACREATOR_VISUALEFFECT_DUMMY_NAME    = "dummy_tile_";

const int AREACREATOR_TILES_MAX_WIDTH               = 16;
const int AREACREATOR_TILES_MAX_HEIGHT              = 16;

const int AREACREATOR_TILES_DEFAULT_WIDTH           = 8;
const int AREACREATOR_TILES_DEFAULT_HEIGHT          = 8;

const int AREACREATOR_PREVIEW_WIDTH                 = 5;
const int AREACREATOR_PREVIEW_HEIGHT                = 5;

const string AREACREATOR_TILE_TAG_PREFIX            = "AC_TILE_";
const string AREACREATOR_PYLON_TAG_PREFIX           = "AC_PYLON_";
const string AREACREATOR_CONSOLE_TAG                = "AC_CONSOLE";
const string AREACREATOR_PREVIEW_TILE_TAG           = "AC_PREVIEW_TILE";
const string AREACREATOR_PREVIEW_LEVER_TAG          = "AC_PREVIEW_LEVER";

const string AREACREATOR_TILESET_NAME               = TILESET_RESREF_RURAL;
const string AREACREATOR_INVALID_TILE_EDGE          = "";

void AreaCreator_CreateTiles(string sSubsystemScript);
void AreaCreator_CreatePylons(string sSubsystemScript);
void AreaCreator_CreateConsole(string sSubsystemScript);
void AreaCreator_CreatePreviewTiles(string sSubsystemScript);
void AreaCreator_CreatePreviewLevers(string sSubsystemScript);

void AreaCreator_HandleTile(object oPlayer, object oTile);
int AreaCreator_HandlePylon(object oPlayer, object oPylon);
void AreaCreator_HandlePreviewTile(object oPlayer, object oPreviewTile);
void AreaCreator_HandlePreviewLever(object oPlayer, object oLever);

void AreaCreator_SetCustomTileData(object oTile);
void AreaCreator_UpdateAllCustomTileData();
void AreaCreator_UpdateTile(object oTile);
void AreaCreator_SetPylonState(string sType, int nPylonNum);
void AreaCreator_UpdateTileGridSize();
string AreaCreator_GetTileset();
string AreaCreator_GetOverrideName();
void AreaCreator_SetCustomAreaData();
void AreaCreator_SetTileset(string sTileset);
void AreaCreator_ApplyEffect_PreviewTile(object oPreviewTile);
void AreaCreator_UpdatePreviewTiles();
void AreaCreator_SetTileEffectOverrides(object oPlayer, int bCheckPreviewTiles, int bCheckTiles);

struct WangTiles_Tile AreaCreator_GetRandomTile(object oTile);
void AreaCreator_GenerateRandomArea(object oPlayer);
void AreaCreator_ClearAllTiles(object oPlayer);

// @Load
void AreaCreator_Load(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_USED, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT);

    Events_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_SERVER_SEND_AREA_BEFORE");
    SetLocalInt(GetArea(GetObjectByTag(AREACREATOR_TILE_GRID_TAG)), sSubsystemScript, TRUE);

    AreaCreator_CreateTiles(sSubsystemScript);
    AreaCreator_CreatePylons(sSubsystemScript);
    AreaCreator_CreateConsole(sSubsystemScript);
    AreaCreator_CreatePreviewTiles(sSubsystemScript);
    AreaCreator_CreatePreviewLevers(sSubsystemScript);

    AreaCreator_SetTileset(AREACREATOR_TILESET_NAME);

    AreaCreator_SetPylonState("X", AREACREATOR_TILES_DEFAULT_WIDTH);
    AreaCreator_SetPylonState("Y", AREACREATOR_TILES_DEFAULT_HEIGHT);
    AreaCreator_UpdateTileGridSize();
    AreaCreator_UpdatePreviewTiles();

    AreaCreator_SetCustomAreaData();

    NWNX_Tileset_OverrideAreaTiles(AREACREATOR_TEMPLATE_RESREF, AreaCreator_GetOverrideName());
    DestroyArea(GetObjectByTag(AREACREATOR_TEMPLATE_RESREF));

    WangTiles_ProcessTileset(AREACREATOR_TILESET_NAME);

    ChatCommand_Register(sSubsystemScript, "AreaCreator_ChatCommand", CHATCOMMAND_GLOBAL_PREFIX + "ac", "", "Area Creation Stuff!");
}

// @EventHandler
void AreaCreator_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_SERVER_SEND_AREA_BEFORE")
    {
        object oPlayer = OBJECT_SELF;
        object oArea = Events_GetEventData_NWNX_Object("AREA");

        if (GetLocalInt(oArea, sSubsystemScript))
            AreaCreator_SetTileEffectOverrides(oPlayer, TRUE, TRUE);
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_PLACEABLE_ON_USED:
            {
                object oPlayer = GetLastUsedBy();
                object oPlaceable = OBJECT_SELF;

                if (GetTag(oPlaceable) == AREACREATOR_CONSOLE_TAG)
                    FloatingTextStringOnCreature("Area Creation Console!", oPlayer, FALSE);

                break;
            }

            case EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK:
            {
                object oPlayer = GetPlaceableLastClickedBy();
                object oPlaceable = OBJECT_SELF;
                string sTag = GetTag(oPlaceable);

                AssignCommand(oPlayer, ClearAllActions());

                if (GetLocalInt(oPlaceable, "PYLON_NUM"))
                {
                    if (AreaCreator_HandlePylon(oPlayer, oPlaceable))
                    {
                        AreaCreator_UpdateTileGridSize();
                        AreaCreator_SetCustomAreaData();
                        AreaCreator_UpdateAllCustomTileData();
                    }
                }
                else
                if (GetStringLeft(sTag, GetStringLength(AREACREATOR_TILE_TAG_PREFIX)) == AREACREATOR_TILE_TAG_PREFIX)
                    AreaCreator_HandleTile(oPlayer, oPlaceable);
                if (sTag == AREACREATOR_PREVIEW_TILE_TAG)
                    AreaCreator_HandlePreviewTile(oPlayer, oPlaceable);
                else if (sTag == AREACREATOR_PREVIEW_LEVER_TAG)
                    AreaCreator_HandlePreviewLever(oPlayer, oPlaceable);

                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                object oPlayer = GetExitingObject();

                ES_Util_DestroyDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
                break;
            }
        }
    }
}

void AreaCreator_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);

    if (sParams == "c")
    {
        object oArea = GetObjectByTag("TEST_CREATION");

        if (GetIsObjectValid(oArea))
            DestroyArea(oArea);

        oArea = CreateArea(AREACREATOR_TEMPLATE_RESREF, "TEST_CREATION", "My Cool New Area");

        if (GetIsObjectValid(oArea) && AreaCreator_GetTileset() == TILESET_RESREF_RURAL)
        {
            SetSkyBox(SKYBOX_GRASS_CLEAR, oArea);
        }
    }
    else if (sParams == "w")
        SetLocalInt(oPlayer, "WANG", !GetLocalInt(oPlayer, "WANG"));
    else if (sParams == "r")
        AreaCreator_GenerateRandomArea(oPlayer);
    else if (sParams == "e")
        AreaCreator_ClearAllTiles(oPlayer);
    else if (sParams == "cl")
        SetLocalInt(oPlayer, "CLEAR_TILE", !GetLocalInt(oPlayer, "CLEAR_TILE"));

    SetPCChatMessage("");
}

void AreaCreator_CreateTiles(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oTileGridStart = GetObjectByTag(AREACREATOR_TILE_GRID_TAG);
    object oArea = GetArea(oTileGridStart);
    vector vStartPosition = GetPosition(oTileGridStart);
    vStartPosition.x += (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vector vPosition = vStartPosition;
    vPosition.y += (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vPosition.z -= 0.3f;
    struct Toolbox_PlaceableData pd;

    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_TILE_TAG_PREFIX;
    pd.bPlot = TRUE;
    pd.bUseable = FALSE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nX, nY, nCount;
    for (nY = 0; nY < AREACREATOR_TILES_MAX_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREACREATOR_TILES_MAX_WIDTH; nX++)
        {
            vPosition.x = vStartPosition.x + (nX * (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE));
            location locSpawn = Location(oArea, vPosition, 0.0f);
            object oTile = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            SetLocalInt(oTile, "TILE_COUNT", nCount);
            SetTag(oTile, AREACREATOR_TILE_TAG_PREFIX + IntToString(nCount++));
            SetLocalInt(oTile, "TILE_ID", -1);
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -200.0f);
            ObjectArray_Insert(oDataObject, "TILES", oTile);

            Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oTile);
        }

        vPosition.y += AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE;
    }
}

void AreaCreator_CreatePylons(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oTileGridStart = GetObjectByTag(AREACREATOR_TILE_GRID_TAG);
    object oArea = GetArea(oTileGridStart);
    struct Toolbox_PlaceableData pd;

    pd.nModel = 467;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PYLON_TAG_PREFIX;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nX, nY, nCount;
    vector vStartPosition = GetPosition(oTileGridStart);
    vStartPosition.x += (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vStartPosition.y -= (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vector vPosition = vStartPosition;

    for (nX = 0; nX < AREACREATOR_TILES_MAX_WIDTH; nX++)
    {
        vPosition.x = vStartPosition.x + (nX * (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE));
        location locSpawn = Location(oArea, vPosition, 0.0f);
        object oPylon = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

        SetTag(oPylon, AREACREATOR_PYLON_TAG_PREFIX + "X" + IntToString(++nCount));
        SetName(oPylon, IntToString(nCount));
        SetLocalString(oPylon, "PYLON_TYPE", "X");
        SetLocalInt(oPylon, "PYLON_NUM", nCount);

        Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oPylon);
    }

    nCount = 0;
    vStartPosition = GetPosition(oTileGridStart);
    vStartPosition.x -= (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vStartPosition.y += (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE) * 0.5f;
    vPosition = vStartPosition;

    for (nY = 0; nY < AREACREATOR_TILES_MAX_HEIGHT; nY++)
    {
        vPosition.y = vStartPosition.y + (nY * (AREACREATOR_TILE_SCALE * AREACREATOR_TILE_SIZE));
        location locSpawn = Location(oArea, vPosition, 0.0f);
        object oPylon = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

        SetTag(oPylon, AREACREATOR_PYLON_TAG_PREFIX + "Y" + IntToString(++nCount));
        SetName(oPylon, IntToString(nCount));
        SetLocalString(oPylon, "PYLON_TYPE", "Y");
        SetLocalInt(oPylon, "PYLON_NUM", nCount);

        if (nCount <= AREACREATOR_TILES_DEFAULT_HEIGHT)
        {
            SetLocalInt(oDataObject, "CURRENT_TILE_HEIGHT", nCount);
            AssignCommand(oPylon, PlayAnimation(ANIMATION_PLACEABLE_ACTIVATE));
        }

        Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oPylon);
    }
}

void AreaCreator_CreateConsole(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oTileGridStart = GetObjectByTag(AREACREATOR_TILE_GRID_TAG);
    object oArea = GetArea(oTileGridStart);
    struct Toolbox_PlaceableData pd;

    pd.nModel = 468;
    pd.sName = "Console";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_CONSOLE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnUsed = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    vector vPosition = GetPosition(oTileGridStart);
    vPosition.x -= 1.0f;
    vPosition.y -= 1.0f;

    location locSpawn = Location(oArea, vPosition, 45.0f);
    object oConsole = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_USED), oConsole);
}

void AreaCreator_CreatePreviewTiles(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oPreviewGridStart = GetObjectByTag(AREACREATOR_PREVIEW_GRID_TAG);
    object oArea = GetArea(oPreviewGridStart);
    vector vStartPosition = GetPosition(oPreviewGridStart), vPosition = vStartPosition;
    vPosition.z -= 0.3f;
    struct Toolbox_PlaceableData pd;

    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PREVIEW_TILE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nX, nY;
    for (nY = 0; nY < AREACREATOR_PREVIEW_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREACREATOR_PREVIEW_WIDTH; nX++)
        {
            vPosition.x = vStartPosition.x + (nX * 1.25f);
            location locSpawn = Location(oArea, vPosition, 0.0f);
            object oPreviewTile = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oPreviewTile);

            SetObjectVisualTransform(oPreviewTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.0f);

            ObjectArray_Insert(oDataObject, "PREVIEW_TILES", oPreviewTile);
        }

        vPosition.y -= 1.25f;
    }
}

void AreaCreator_CreatePreviewLevers(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oPreviewGridStart = GetObjectByTag(AREACREATOR_PREVIEW_GRID_TAG);
    object oArea = GetArea(oPreviewGridStart);
    vector vStartPosition = GetPosition(oPreviewGridStart), vPosition;

    struct Toolbox_PlaceableData pd;

    pd.nModel = 23;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = AREACREATOR_PREVIEW_LEVER_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    vPosition.x = vStartPosition.x + (((AREACREATOR_PREVIEW_WIDTH - 1) * 1.25f) + 1.5f);
    vPosition.y = vStartPosition.y - (((AREACREATOR_PREVIEW_WIDTH - 1) * 1.25) * 0.5f);
    location locSpawn = Location(oArea, vPosition, 0.0f);

    object oLever = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);
    SetName(oLever, "Next");
    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oLever);

    vPosition.x = vStartPosition.x - 1.5f;
    locSpawn = Location(oArea, vPosition, 180.0f);

    oLever = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);
    SetName(oLever, "Previous");
    Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oLever);
}

void AreaCreator_HandleTile(object oPlayer, object oTile)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    float fTileHeightTransition = GetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION");
    int nSelectedTileID = GetLocalInt(oPlayer, "SELECTED_TILE");
    int bUpdate = TRUE;

    if (GetLocalInt(oPlayer, "CLEAR_TILE"))
    {
        SetLocalInt(oTile, "TILE_ID", -1);
        DeleteLocalInt(oTile, "TILE_ORIENTATION");
        DeleteLocalInt(oTile, "TILE_HEIGHT");
        DeleteLocalString(oTile, "TILE_MODEL");

        Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");
    }
    else
    if (GetLocalInt(oPlayer, "WANG"))
    {
        struct WangTiles_Tile tile = AreaCreator_GetRandomTile(oTile);

        if (tile.nTileID != -1)
        {
            string sTileModel = NWNX_Tileset_GetTileModel(AreaCreator_GetTileset(), tile.nTileID);

            SetLocalInt(oTile, "TILE_ID", tile.nTileID);
            SetLocalString(oTile, "TILE_MODEL", sTileModel);
            SetLocalInt(oTile, "TILE_ORIENTATION", tile.nOrientation);

            // TEMP
            object oPlayerDataObject = ES_Util_GetDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));

            if (!GetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(tile.nTileID)))
            {
                NWNX_Player_SetResManOverride(oPlayer, 2002, AREACREATOR_VISUALEFFECT_DUMMY_NAME + IntToString(tile.nTileID), sTileModel);
                SetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(tile.nTileID), TRUE);
            }
            // ***

            vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (GetLocalInt(oTile, "TILE_HEIGHT") * (fTileHeightTransition * AREACREATOR_TILE_SCALE)));
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_BREACH, FALSE, 1.0f, vTranslate), oTile);
        }
        else
            bUpdate = FALSE;
    }
    else
    if (GetLocalInt(oTile, "TILE_ID") == nSelectedTileID)
    {
        int nOrientation = GetLocalInt(oTile, "TILE_ORIENTATION") + 1;

        if (nOrientation > 3)
            nOrientation = 0;

        SetLocalInt(oTile, "TILE_ORIENTATION", nOrientation);
        SetLocalInt(oTile, "TILE_HEIGHT", GetLocalInt(oDataObject, "CURRENT_HEIGHT"));

        vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (GetLocalInt(oTile, "TILE_HEIGHT") * (fTileHeightTransition * AREACREATOR_TILE_SCALE)));
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_AC_BONUS, FALSE, 1.0f, vTranslate), oTile);
    }
    else
    {
        SetLocalInt(oTile, "TILE_ID", nSelectedTileID);
        SetLocalString(oTile, "TILE_MODEL", GetLocalString(oPlayer, "SELECTED_TILE_MODEL"));
        SetLocalInt(oTile, "TILE_HEIGHT", GetLocalInt(oDataObject, "CURRENT_HEIGHT"));

        vector vTranslate = Vector(0.0f, 0.0f, 1.5f + (GetLocalInt(oTile, "TILE_HEIGHT") * (fTileHeightTransition * AREACREATOR_TILE_SCALE)));
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE, FALSE, 1.0f, vTranslate), oTile);
    }

    if (bUpdate)
        AreaCreator_UpdateTile(oTile);
}

int AreaCreator_HandlePylon(object oPlayer, object oPylon)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int bReturn;
    string sType = GetLocalString(oPylon, "PYLON_TYPE");
    int nPylonNum = GetLocalInt(oPylon, "PYLON_NUM");
    string sCurrentXYVarName = sType == "X" ? "CURRENT_TILE_WIDTH" : "CURRENT_TILE_HEIGHT";
    int nCurrentXY = GetLocalInt(oDataObject, sCurrentXYVarName);

    if (nPylonNum != nCurrentXY)
    {
        NWNX_Player_PlaySound(oPlayer, "gui_traparm");
        Effects_PlaySoundAndApplySparks(oPylon, "");

        AreaCreator_SetPylonState(sType, nPylonNum);

        bReturn = TRUE;
    }

    return bReturn;
}

void AreaCreator_HandlePreviewTile(object oPlayer, object oPreviewTile)
{
    SetLocalInt(oPlayer, "SELECTED_TILE", GetLocalInt(oPreviewTile, "TILE_ID"));
    SetLocalString(oPlayer, "SELECTED_TILE_MODEL", GetLocalString(oPreviewTile, "TILE_MODEL"));

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEAD_SONIC, FALSE, 1.0f, [0.0f, 0.0f, 1.25f]), oPreviewTile);
}

void AreaCreator_HandlePreviewLever(object oPlayer, object oLever)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);

    if (GetName(oLever) == "Next")
    {
        int nNumTileData = GetLocalInt(oDataObject, "TILESET_NUM_TILE_DATA");
        int nMax = floor(IntToFloat(nNumTileData) / (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT)) * (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT);
        int nCurrent = GetLocalInt(oDataObject, "TILE_ID_RANGE") + (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT);

        if (nCurrent <= nMax)
        {
            Effects_PlaySoundAndApplySparks(oLever, "gui_quick_add");

            SetLocalInt(oDataObject, "TILE_ID_RANGE", nCurrent);
            AreaCreator_UpdatePreviewTiles();
            // TEMP
            AreaCreator_SetTileEffectOverrides(oPlayer, TRUE, FALSE);
            PostString(oPlayer, "Preview Tiles: " + IntToString(nCurrent) + "-" + IntToString(nCurrent + (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT) - 1), 1, 4, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 1);
        }
    }
    else
    {
        int nCurrent = GetLocalInt(oDataObject, "TILE_ID_RANGE") - (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT);

        if (nCurrent >= 0)
        {
            Effects_PlaySoundAndApplySparks(oLever, "gui_quick_erase");

            SetLocalInt(oDataObject, "TILE_ID_RANGE", nCurrent);
            AreaCreator_UpdatePreviewTiles();
            // TEMP
            AreaCreator_SetTileEffectOverrides(oPlayer, TRUE, FALSE);
            PostString(oPlayer, "Preview Tiles: " + IntToString(nCurrent) + "-" + IntToString(nCurrent + (AREACREATOR_PREVIEW_WIDTH * AREACREATOR_PREVIEW_HEIGHT) - 1), 1, 4, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 1);
        }
    }
}

void AreaCreator_SetCustomTileData(object oTile)
{
    int nTileNum = GetLocalInt(oTile, "TILE_NUM");
    int nTileID = GetLocalInt(oTile, "TILE_ID");
    int nTileOrientation = GetLocalInt(oTile, "TILE_ORIENTATION");
    int nTileHeight = GetLocalInt(oTile, "TILE_HEIGHT");

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
        NWNX_Tileset_SetCustomTileData(AreaCreator_GetOverrideName(), nTileNum, ctd);
}

void AreaCreator_UpdateAllCustomTileData()
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int nMaxTiles = AREACREATOR_TILES_MAX_WIDTH * AREACREATOR_TILES_MAX_HEIGHT;
    int nTile;

    NWNX_Tileset_DeleteCustomTileData(AreaCreator_GetOverrideName(), -1);

    for (nTile = 0; nTile < nMaxTiles; nTile++)
    {
        object oTile = GetObjectByTag(AREACREATOR_TILE_TAG_PREFIX + IntToString(nTile));

        if (GetUseableFlag(oTile))
            AreaCreator_SetCustomTileData(oTile);
    }
}

void AreaCreator_UpdateTile(object oTile)
{
    Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");

    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int nTileID = GetLocalInt(oTile, "TILE_ID");
    int nTileOrientation = GetLocalInt(oTile, "TILE_ORIENTATION");
    int nTileHeight = GetLocalInt(oTile, "TILE_HEIGHT");
    float fTileHeightTransition = GetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION");

    float fOrientation;
    switch (nTileOrientation)
    {
        case 0: fOrientation = 90.0f; break;
        case 1: fOrientation = 180.0f; break;
        case 2: fOrientation = 270.0f; break;
        case 3: fOrientation = 0.0f; break;
    }

    vector vRotate = Vector(fOrientation, 0.0f, 0.0f);
    float fHeight = 1.75f + (nTileHeight * (fTileHeightTransition * AREACREATOR_TILE_SCALE));
    vector vTranslate = Vector(0.0f, 0.0f, fHeight);

    effect eTile = EffectVisualEffect(AREACREATOR_EFFECT_START + nTileID, FALSE, AREACREATOR_TILE_SCALE, vTranslate, vRotate);
    eTile = TagEffect(eTile, "TILE_EFFECT");

    AreaCreator_SetCustomTileData(oTile);

    DelayCommand(AREACREATOR_TILE_EFFECT_APPLY_DELAY, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oTile));
}

void AreaCreator_SetPylonState(string sType, int nPylonNum)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    string sCurrentXYVarName = sType == "X" ? "CURRENT_TILE_WIDTH" : "CURRENT_TILE_HEIGHT";
    int nCount;
    object oOtherPylon;
    while ((oOtherPylon = GetObjectByTag(AREACREATOR_PYLON_TAG_PREFIX + sType + IntToString(++nCount))) != OBJECT_INVALID)
    {
        int nOtherPylonNum = GetLocalInt(oOtherPylon, "PYLON_NUM");

        AssignCommand(oOtherPylon, PlayAnimation(nOtherPylonNum <= nPylonNum ? ANIMATION_PLACEABLE_ACTIVATE : ANIMATION_PLACEABLE_DEACTIVATE));
    }

    SetLocalInt(oDataObject, sCurrentXYVarName, nPylonNum);
}

void AreaCreator_UpdateTileGridSize()
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int nWidth = GetLocalInt(oDataObject, "CURRENT_TILE_WIDTH");
    int nHeight = GetLocalInt(oDataObject, "CURRENT_TILE_HEIGHT");
    int nMaxTiles = AREACREATOR_TILES_MAX_WIDTH * AREACREATOR_TILES_MAX_HEIGHT;

    ObjectArray_Clear(oDataObject, "CURRENT_TILES");

    int nTile, nCount;
    for (nTile = 0; nTile < nMaxTiles; nTile++)
    {
        object oTile = GetObjectByTag(AREACREATOR_TILE_TAG_PREFIX + IntToString(nTile));
        int nX = nTile % AREACREATOR_TILES_MAX_WIDTH;
        int nY = nTile / AREACREATOR_TILES_MAX_WIDTH;

        if (nX < nWidth && nY < nHeight)
        {
            ObjectArray_Insert(oDataObject, "CURRENT_TILES", oTile);
            SetLocalInt(oTile, "TILE_NUM", nCount++);
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.0f);
            SetUseableFlag(oTile, TRUE);

        }
        else
        {
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -200.0f);
            SetUseableFlag(oTile, FALSE);
        }
    }
}

string AreaCreator_GetTileset()
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    return GetLocalString(oDataObject, "TILESET_NAME");
}

void AreaCreator_SetTileset(string sTileset)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    struct NWNX_Tileset_TilesetInfo tsi = NWNX_Tileset_GetTilesetInfo(sTileset);

    if (tsi.nNumTileData > AREACREATOR_TILESET_MAX_TILES)
        ES_Util_Log(AREACREATOR_LOG_TAG , "WARNING: Tileset '" + sTileset + "' has more than " + IntToString(AREACREATOR_TILESET_MAX_TILES) + " tiles!");

    SetLocalString(oDataObject, "TILESET_NAME", sTileset);
    SetLocalInt(oDataObject, "TILESET_NUM_TILE_DATA", tsi.nNumTileData);
    SetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION", tsi.fHeightTransition);
}

string AreaCreator_GetOverrideName()
{
    return "AreaTileOverrideData";
}

void AreaCreator_SetCustomAreaData()
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    string sOverrideName = AreaCreator_GetOverrideName();
    string sTileset = AreaCreator_GetTileset();
    int nWidth = GetLocalInt(oDataObject , "CURRENT_TILE_WIDTH");
    int nHeight = GetLocalInt(oDataObject , "CURRENT_TILE_HEIGHT");

    NWNX_Tileset_SetCustomAreaData(sOverrideName, sTileset, nWidth, nHeight);
}

void AreaCreator_ApplyEffect_PreviewTile(object oPreviewTile)
{
    Effects_RemoveEffectsWithTag(oPreviewTile, "TILE_EFFECT_PREVIEW");

    int nTileID = GetLocalInt(oPreviewTile, "TILE_ID");

    effect eTileEffect = EffectVisualEffect(AREACREATOR_EFFECT_START + nTileID, FALSE, 0.1f, [0.0f, 0.0f, 1.75f]);
    eTileEffect = TagEffect(eTileEffect, "TILE_EFFECT_PREVIEW");

    DelayCommand(AREACREATOR_TILE_EFFECT_APPLY_DELAY, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTileEffect, oPreviewTile));
}

void AreaCreator_UpdatePreviewTiles()
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    string sTileset = AreaCreator_GetTileset();
    int nRange = GetLocalInt(oDataObject, "TILE_ID_RANGE");
    int nNumPreviewTiles = ObjectArray_Size(oDataObject, "PREVIEW_TILES");

    int nPreviewTile;
    for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
    {
        object oPreviewTile = ObjectArray_At(oDataObject, "PREVIEW_TILES", nPreviewTile);
        int nTileID = nRange + nPreviewTile;
        string sTileModel = NWNX_Tileset_GetTileModel(sTileset, nTileID);

        SetLocalInt(oPreviewTile, "TILE_ID", nTileID);
        SetLocalString(oPreviewTile, "TILE_MODEL", sTileModel);

        if (sTileModel != "")
        {
            SetName(oPreviewTile, "[" + IntToString(nTileID) + "] " + sTileModel);

            AreaCreator_ApplyEffect_PreviewTile(oPreviewTile);

            SetUseableFlag(oPreviewTile, TRUE);
        }
        else
        {
            SetUseableFlag(oPreviewTile, FALSE);
            Effects_RemoveEffectsWithTag(oPreviewTile, "TILE_EFFECT_PREVIEW");
        }
    }
}

void AreaCreator_SetTileEffectOverrides(object oPlayer, int bCheckPreviewTiles, int bCheckTiles)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    object oPlayerDataObject = ES_Util_GetDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));

    if (bCheckPreviewTiles)
    {
        int nRange = GetLocalInt(oDataObject, "TILE_ID_RANGE");
        int nNumPreviewTiles = ObjectArray_Size(oDataObject, "PREVIEW_TILES");

        int nPreviewTile;
        for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
        {
            object oPreviewTile = ObjectArray_At(oDataObject, "PREVIEW_TILES", nPreviewTile);

            if (GetUseableFlag(oPreviewTile))
            {
                int nTileID = GetLocalInt(oPreviewTile, "TILE_ID");
                string sTileModel = GetLocalString(oPreviewTile, "TILE_MODEL");

                if (!GetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(nTileID)))
                {
                    NWNX_Player_SetResManOverride(oPlayer, 2002, AREACREATOR_VISUALEFFECT_DUMMY_NAME + IntToString(nTileID), sTileModel);
                    SetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(nTileID), TRUE);
                }
            }
        }
    }

    if (bCheckTiles)
    {
        int nMaxTiles = AREACREATOR_TILES_MAX_WIDTH * AREACREATOR_TILES_MAX_HEIGHT;
        int nTile;
        for (nTile = 0; nTile < nMaxTiles; nTile++)
        {
            object oTile = GetObjectByTag(AREACREATOR_TILE_TAG_PREFIX + IntToString(nTile));

            int nTileID = GetLocalInt(oTile, "TILE_ID");
            string sTileModel = GetLocalString(oTile, "TILE_MODEL");

            if (nTileID != -1)
            {
                if (!GetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(nTileID)))
                {
                    NWNX_Player_SetResManOverride(oPlayer, 2002, AREACREATOR_VISUALEFFECT_DUMMY_NAME + IntToString(nTileID), sTileModel);
                    SetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(nTileID), TRUE);
                }
            }
        }
    }
}

object AreaCreator_GetNeighborTile(object oTile, int nDirection)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int nTileNum = GetLocalInt(oTile, "TILE_NUM");
    int nCurrentWidth = GetLocalInt(oDataObject, "CURRENT_TILE_WIDTH");
    int nCurrentHeight = GetLocalInt(oDataObject, "CURRENT_TILE_HEIGHT");
    int nTileX = nTileNum % nCurrentWidth;
    int nTileY = nTileNum / nCurrentWidth;

    //PrintString("X=" + IntToString(nTileX) + ", Y=" + IntToString(nTileY));

    switch (nDirection)
    {
        case 0:
        {
            if (nTileY == (nCurrentHeight - 1))
                return OBJECT_INVALID;
            else
                nTileNum += nCurrentWidth;
            break;
        }

        case 1:
        {
            if (nTileX == (nCurrentWidth - 1))
                return OBJECT_INVALID;
            else
                nTileNum += 1;
            break;
        }

        case 2:
        {
            if (nTileY == 0)
                return OBJECT_INVALID;
            else
                nTileNum -= nCurrentWidth;
            break;
        }

        case 3:
        {
            if (nTileX == 0)
                return OBJECT_INVALID;
            else
                nTileNum -= 1;
            break;
        }
    }

    return ObjectArray_At(oDataObject, "CURRENT_TILES", nTileNum);
}

void PrintStruct(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    PrintString("STRUCT:");
    PrintString("TL: " + str.sTopLeft);
    PrintString("T: " + str.sTop);
    PrintString("TR: " + str.sTopRight);
    PrintString("R: " + str.sRight);
    PrintString("BR: " + str.sBottomRight);
    PrintString("B: " + str.sBottom);
    PrintString("BL: " + str.sBottomLeft);
    PrintString("L: " + str.sLeft);
}

struct NWNX_Tileset_TileEdgesAndCorners AreaCreator_GetNeighborEdgesAndCorners(object oTile, int nDirection)
{
    struct NWNX_Tileset_TileEdgesAndCorners str;
    object oNeightbor = AreaCreator_GetNeighborTile(oTile, nDirection);

    if (oNeightbor != OBJECT_INVALID)
    {
        int nTileID = GetLocalInt(oNeightbor, "TILE_ID");
        int nOrientation = GetLocalInt(oNeightbor, "TILE_ORIENTATION");
        int nHeight = GetLocalInt(oNeightbor, "TILE_HEIGHT");

        if (nTileID != -1)
            str = WangTiles_GetCornersAndEdgesByOrientation(AreaCreator_GetTileset(), nTileID, nOrientation);

        // HACK
        if (AreaCreator_GetTileset() == TILESET_RESREF_RURAL && nHeight == 1)
            str = WangTiles_ReplaceTerrainOrCrosser(str, "Grass", "Grass+");
    }
    else
    {
        switch (nDirection)
        {
            case 0:
            {
                str.sBottomLeft = AREACREATOR_INVALID_TILE_EDGE;
                str.sBottom = AREACREATOR_INVALID_TILE_EDGE;
                str.sBottomRight = AREACREATOR_INVALID_TILE_EDGE;
                break;
            }

            case 1:
            {
                str.sTopLeft = AREACREATOR_INVALID_TILE_EDGE;
                str.sLeft = AREACREATOR_INVALID_TILE_EDGE;
                str.sBottomLeft = AREACREATOR_INVALID_TILE_EDGE;
                break;
            }

            case 2:
            {
                str.sTopLeft = AREACREATOR_INVALID_TILE_EDGE;
                str.sTop = AREACREATOR_INVALID_TILE_EDGE;
                str.sTopRight = AREACREATOR_INVALID_TILE_EDGE;
                break;
            }

            case 3:
            {
                str.sTopRight = AREACREATOR_INVALID_TILE_EDGE;
                str.sRight = AREACREATOR_INVALID_TILE_EDGE;
                str.sBottomRight = AREACREATOR_INVALID_TILE_EDGE;
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

struct WangTiles_Tile AreaCreator_GetRandomTile(object oTile)
{
    struct NWNX_Tileset_TileEdgesAndCorners strQuery;

    struct NWNX_Tileset_TileEdgesAndCorners strTop = AreaCreator_GetNeighborEdgesAndCorners(oTile, 0);
    struct NWNX_Tileset_TileEdgesAndCorners strRight = AreaCreator_GetNeighborEdgesAndCorners(oTile, 1);
    struct NWNX_Tileset_TileEdgesAndCorners strBottom = AreaCreator_GetNeighborEdgesAndCorners(oTile, 2);
    struct NWNX_Tileset_TileEdgesAndCorners strLeft = AreaCreator_GetNeighborEdgesAndCorners(oTile, 3);

    strQuery.sTop = strTop.sBottom;
    strQuery.sRight = strRight.sLeft;
    strQuery.sBottom = strBottom.sTop;
    strQuery.sLeft = strLeft.sRight;

    strQuery.sTopLeft = AreaCreator_HandleCornerConflict(strTop.sBottomLeft, strLeft.sTopRight);
    strQuery.sTopRight = AreaCreator_HandleCornerConflict(strTop.sBottomRight, strRight.sTopLeft);
    strQuery.sBottomRight = AreaCreator_HandleCornerConflict(strRight.sBottomLeft, strBottom.sTopRight);
    strQuery.sBottomLeft = AreaCreator_HandleCornerConflict(strBottom.sTopLeft, strLeft.sBottomRight);

    if (strQuery.sTopLeft == "") strQuery.sTopLeft = "IGNORE";
    if (strQuery.sTop == "") strQuery.sTop = "IGNORE";
    if (strQuery.sTopRight == "") strQuery.sTopRight = "IGNORE";
    if (strQuery.sRight == "") strQuery.sRight = "IGNORE";
    if (strQuery.sBottomRight == "") strQuery.sBottomRight = "IGNORE";
    if (strQuery.sBottom == "") strQuery.sBottom = "IGNORE";
    if (strQuery.sBottomLeft == "") strQuery.sBottomLeft = "IGNORE";
    if (strQuery.sLeft == "") strQuery.sLeft = "IGNORE";

    PrintStruct(strQuery);

    return WangTiles_GetRandomMatchingTile(AreaCreator_GetTileset(), strQuery);
}

void AreaCreator_GenerateRandomArea(object oPlayer)
{
    NWNX_Util_SetInstructionLimit(524288 * 4);

    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    float fTileHeightTransition = GetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION");
    int nNumTiles = ObjectArray_Size(oDataObject, "CURRENT_TILES");
    int nTile;

    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        object oTile = ObjectArray_At(oDataObject, "CURRENT_TILES", nTile);

        if (GetLocalInt(oTile, "TILE_ID") != -1)
            continue;

        struct WangTiles_Tile tile = AreaCreator_GetRandomTile(oTile);

        if (tile.nTileID != -1)
        {
            string sTileModel = NWNX_Tileset_GetTileModel(AreaCreator_GetTileset(), tile.nTileID);

            SetLocalInt(oTile, "TILE_ID", tile.nTileID);
            SetLocalInt(oTile, "TILE_ORIENTATION", tile.nOrientation);
            SetLocalInt(oTile, "TILE_HEIGHT", tile.nHeight);
            SetLocalString(oTile, "TILE_MODEL", sTileModel);

            // TEMP
            object oPlayerDataObject = ES_Util_GetDataObject("AC_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));

            if (!GetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(tile.nTileID)))
            {
                NWNX_Player_SetResManOverride(oPlayer, 2002, AREACREATOR_VISUALEFFECT_DUMMY_NAME + IntToString(tile.nTileID), sTileModel);
                SetLocalInt(oPlayerDataObject, "TILE_ID_" + IntToString(tile.nTileID), TRUE);
            }
            // ***

            vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (GetLocalInt(oTile, "TILE_HEIGHT") * (fTileHeightTransition * AREACREATOR_TILE_SCALE)));
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DAZED_S, FALSE, 1.0f, vTranslate), oTile);

            AreaCreator_UpdateTile(oTile);
        }
    }

    NWNX_Util_SetInstructionLimit(-1);
}

void AreaCreator_ClearAllTiles(object oPlayer)
{
    object oDataObject = ES_Util_GetDataObject(AREACREATOR_SCRIPT_NAME);
    int nNumTiles = ObjectArray_Size(oDataObject, "TILES");

    int nTile;
    for (nTile = 0; nTile < nNumTiles; nTile++)
    {
        object oTile = ObjectArray_At(oDataObject, "TILES", nTile);

        SetLocalInt(oTile, "TILE_ID", -1);
        DeleteLocalInt(oTile, "TILE_ORIENTATION");
        DeleteLocalInt(oTile, "TILE_HEIGHT");
        DeleteLocalString(oTile, "TILE_MODEL");

        Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");
    }
}

