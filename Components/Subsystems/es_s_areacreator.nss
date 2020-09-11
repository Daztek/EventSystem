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

#include "nwnx_player"
#include "nwnx_tileset"

const string AREA_CREATOR_LOG_TAG               = "AreaCreator";
const string AREA_CREATOR_SCRIPT_NAME           = "es_s_areacreator";

const string AREA_CREATOR_TEMPLATE_RESREF       = "are_cretemp";
const string AREA_CREATOR_OVERRIDE_NAME         = "my_override";
const string AREA_CREATOR_GRID_START_TAG        = "AC_GRID_START";
const string AREA_CREATOR_PREVIEW_START_TAG     = "AC_PREVIEW_START";

const int AREA_CREATOR_WIDTH                    = 5;
const int AREA_CREATOR_HEIGHT                   = 5;
const int AREA_CREATOR_PREVIEW_WIDTH            = 5;
const int AREA_CREATOR_PREVIEW_HEIGHT           = 5;

const int AREA_CREATOR_EFFECT_START             = 1000;
const float AREA_CREATOR_TILE_SIZE              = 10.0f;
const float AREA_CREATOR_TILE_SCALE             = 0.25f;

const string AREA_CREATOR_TILESET               = TILESET_RESREF_RURAL;//TILESET_RESREF_CASTLE_INTERIOR;

void AreaCreator_SpawnTiles(string sSubsystemScript);
void AreaCreator_SpawnPreviewTiles(string sSubsystemScript);
void AreaCreator_UpdateTile(object oTile);
void AreaCreator_UpdatePreviewTiles(object oPlayer);

// @Load
void AreaCreator_Load(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);

    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER, EVENTS_EVENT_FLAG_DEFAULT);

    NWNX_Tileset_OverrideAreaTiles(AREA_CREATOR_TEMPLATE_RESREF, AREA_CREATOR_OVERRIDE_NAME);

    struct NWNX_Tileset_TilesetInfo tsi = NWNX_Tileset_GetTilesetInfo(AREA_CREATOR_TILESET);
    SetLocalInt(oDataObject, "TILESET_NUM_TILE_DATA", tsi.nNumTileData);
    SetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION", tsi.fHeightTransition);

    AreaCreator_SpawnTiles(sSubsystemScript);
    AreaCreator_SpawnPreviewTiles(sSubsystemScript);

    ChatCommand_Register(sSubsystemScript, "AreaCreator_ChatCommand", CHATCOMMAND_GLOBAL_PREFIX + "ac", "", "Area Creation Stuff!");

    DestroyArea(GetObjectByTag(AREA_CREATOR_TEMPLATE_RESREF));
}

// @EventHandler
void AreaCreator_EventHandler(string sSubsystemScript, string sEvent)
{
    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
        {
            object oPlayer = GetEnteringObject();

            AreaCreator_UpdatePreviewTiles(oPlayer);

            break;
        }

        case EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK:
        {
            object oPlayer = GetPlaceableLastClickedBy();
            object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
            object oSelf = OBJECT_SELF;
            string sTag = GetTag(oSelf);
            float fHeightTransition = GetLocalFloat(oDataObject, "TILESET_HEIGHT_TRANSITION");

            AssignCommand(oPlayer, ClearAllActions());

            if (sTag == "AC_TILE")
            {
                if (GetLocalInt(oPlayer, "ROTATION") || GetLocalInt(oPlayer, "CURRENT_TILE") == GetLocalInt(oSelf, "TILE_ID"))
                {
                    int nOrientation = GetLocalInt(oSelf, "TILE_ORIENTATION") + 1;

                    if (nOrientation > 3)
                        nOrientation = 0;

                    SetLocalInt(oSelf, "TILE_ORIENTATION", nOrientation);
                    SetLocalInt(oSelf, "TILE_HEIGHT", GetLocalInt(oDataObject, "CURRENT_HEIGHT"));

                    vector vTranslate = Vector(0.0f, 0.0f, 1.0f + (GetLocalInt(oSelf, "TILE_HEIGHT") * (fHeightTransition * AREA_CREATOR_TILE_SCALE)));
                    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_AC_BONUS, FALSE, 1.0f, vTranslate), oSelf);
                }
                else
                {
                    SetLocalInt(oSelf, "TILE_ID", GetLocalInt(oPlayer, "CURRENT_TILE"));
                    SetLocalInt(oSelf, "TILE_HEIGHT", GetLocalInt(oDataObject, "CURRENT_HEIGHT"));

                    vector vTranslate = Vector(0.0f, 0.0f, 1.5f + (GetLocalInt(oSelf, "TILE_HEIGHT") * (fHeightTransition * AREA_CREATOR_TILE_SCALE)));
                    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_MAGBLUE, FALSE, 1.0f, vTranslate), oSelf);
                }

                AreaCreator_UpdateTile(oSelf);
            }
            else if (sTag == "AC_PREVIEW")
            {
                SetLocalInt(oPlayer, "CURRENT_TILE", GetLocalInt(oSelf, "TILE_ID"));

                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEAD_SONIC, FALSE, 1.0f, [0.0f, 0.0f, 1.25f]), oSelf);
            }

            break;
        }
    }
}

void AreaCreator_ChatCommand(object oPlayer, string sParams, int nVolume)
{
    object oDataObject = ES_Util_GetDataObject(AREA_CREATOR_SCRIPT_NAME);

    if (sParams == "c")
    {
        object oArea = GetObjectByTag("TEST_CREATION");

        if (GetIsObjectValid(oArea))
            DestroyArea(oArea);

        oArea = CreateArea(AREA_CREATOR_TEMPLATE_RESREF, "TEST_CREATION", "My Cool New Area");

        if (GetIsObjectValid(oArea) && AREA_CREATOR_TILESET == TILESET_RESREF_RURAL)
        {
            SetSkyBox(SKYBOX_GRASS_CLEAR, oArea);
        }
    }
    else if (sParams == "n")
    {
        int nNumTileData = GetLocalInt(oDataObject, "TILESET_NUM_TILE_DATA");
        int nMax = floor(IntToFloat(nNumTileData) / (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT)) * (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT);
        int nCurrent = GetLocalInt(oDataObject, "TILE_ID_RANGE") + (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT);

        if (nCurrent <= nMax)
        {
            SetLocalInt(oDataObject, "TILE_ID_RANGE", nCurrent);
            AreaCreator_UpdatePreviewTiles(oPlayer);
            PostString(oPlayer, "Preview Tiles: " + IntToString(nCurrent) + "-" + IntToString(nCurrent + (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT) - 1), 1, 4, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 1);
        }
    }
    else if (sParams == "p")
    {
        int nCurrent = GetLocalInt(oDataObject, "TILE_ID_RANGE") - (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT);

        if (nCurrent >= 0)
        {
            SetLocalInt(oDataObject, "TILE_ID_RANGE", nCurrent);
            AreaCreator_UpdatePreviewTiles(oPlayer);
            PostString(oPlayer, "Preview Tiles: " + IntToString(nCurrent) + "-" + IntToString(nCurrent + (AREA_CREATOR_PREVIEW_WIDTH * AREA_CREATOR_PREVIEW_HEIGHT) - 1), 1, 4, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 1);
        }
    }
    else if (sParams == "r")
    {
        SetLocalInt(oPlayer, "ROTATION", !GetLocalInt(oPlayer, "ROTATION"));
    }
    else if (sParams == "h")
    {
        int nCurrentHeight = GetLocalInt(oDataObject, "CURRENT_HEIGHT") + 1;

        SetLocalInt(oDataObject, "CURRENT_HEIGHT", nCurrentHeight);

        PostString(oPlayer, "Height: " + IntToString(nCurrentHeight), 1, 5, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 2);
    }
    else if (sParams == "l")
    {
        int nCurrentHeight = GetLocalInt(oDataObject, "CURRENT_HEIGHT") - 1;

        if (nCurrentHeight < 0)
            nCurrentHeight = 0;

        SetLocalInt(oDataObject, "CURRENT_HEIGHT", nCurrentHeight);

        PostString(oPlayer, "Height: " + IntToString(nCurrentHeight), 1, 5, SCREEN_ANCHOR_TOP_LEFT, 0.0f, 0xFFFFFFFF, 0xFFFFFFFF, 2);
    }

    SetPCChatMessage("");
}

void AreaCreator_UpdateTile(object oTile)
{
    Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");

    object oDataObject = ES_Util_GetDataObject(AREA_CREATOR_SCRIPT_NAME);
    int nTileNum = GetLocalInt(oTile, "TILE_NUM");
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
    float fHeight = 1.75f + (nTileHeight * (fTileHeightTransition * AREA_CREATOR_TILE_SCALE));
    vector vTranslate = Vector(0.0f, 0.0f, fHeight);

    effect eTile = EffectVisualEffect(AREA_CREATOR_EFFECT_START + nTileID, FALSE, AREA_CREATOR_TILE_SCALE, vTranslate, vRotate);
    eTile = TagEffect(eTile, "TILE_EFFECT");

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

    NWNX_Tileset_SetCustomTileData(AREA_CREATOR_OVERRIDE_NAME, nTileNum, ctd);

    DelayCommand(0.1f, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oTile));
}

void AreaCreator_SpawnTiles(string sSubsystemScript)
{
    object oGridStart = GetObjectByTag(AREA_CREATOR_GRID_START_TAG);
    object oArea = GetArea(oGridStart);
    vector vStartPosition = GetPosition(oGridStart);
    vStartPosition.x += (AREA_CREATOR_TILE_SCALE * AREA_CREATOR_TILE_SIZE) * 0.5f;
    vector vPosition = vStartPosition;
    vPosition.y += (AREA_CREATOR_TILE_SCALE * AREA_CREATOR_TILE_SIZE) * 0.5f;
    vPosition.z -= 0.3f;
    struct Toolbox_PlaceableData pd;

    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = "AC_TILE";
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    NWNX_Tileset_SetCustomAreaData(AREA_CREATOR_OVERRIDE_NAME, AREA_CREATOR_TILESET, AREA_CREATOR_WIDTH, AREA_CREATOR_HEIGHT);

    int nX, nY, nCount;
    for (nY = 0; nY < AREA_CREATOR_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREA_CREATOR_WIDTH; nX++)
        {
            vPosition.x = vStartPosition.x + (nX * (AREA_CREATOR_TILE_SCALE * AREA_CREATOR_TILE_SIZE));
            location locSpawn = Location(oArea, vPosition, 0.0f);
            object oPedestal = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oPedestal);
            SetLocalInt(oPedestal, "TILE_NUM", nCount++);
            SetLocalInt(oPedestal, "TILE_ID", -1);

            SetObjectVisualTransform(oPedestal, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.0f);
        }

        vPosition.y += AREA_CREATOR_TILE_SCALE * AREA_CREATOR_TILE_SIZE;
    }
}

void AreaCreator_ApplyPreviewEffect(object oTile)
{
    Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");

    int nTileID = GetLocalInt(oTile, "TILE_ID");

    effect eTile = EffectVisualEffect(AREA_CREATOR_EFFECT_START + nTileID, FALSE, 0.1f, [0.0f, 0.0f, 1.75f]);
    eTile = TagEffect(eTile, "TILE_EFFECT");

    DelayCommand(0.1f, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oTile));
}

void AreaCreator_SpawnPreviewTiles(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
    object oPreviewStart = GetObjectByTag(AREA_CREATOR_PREVIEW_START_TAG);
    object oArea = GetArea(oPreviewStart);
    vector vStartPosition = GetPosition(oPreviewStart), vPosition = vStartPosition;
    struct Toolbox_PlaceableData pd;

    pd.nModel = 76;
    pd.sName = " ";
    pd.sDescription = " ";
    pd.sTag = "AC_PREVIEW";
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;
    pd.scriptOnClick = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nX, nY;
    for (nY = 0; nY < AREA_CREATOR_PREVIEW_HEIGHT; nY++)
    {
        for (nX = 0; nX < AREA_CREATOR_PREVIEW_WIDTH; nX++)
        {
            vPosition.x = vStartPosition.x + (nX * 1.25f);
            location locSpawn = Location(oArea, vPosition, 0.0f);
            object oPedestal = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);

            Events_AddObjectToDispatchList(sSubsystemScript, Events_GetEventName_Object(EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK), oPedestal);

            SetObjectVisualTransform(oPedestal, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, -1.3f);

            ObjectArray_Insert(oDataObject, "PREVIEW_TILES", oPedestal);
        }

        vPosition.y -= 1.25f;
    }
}

void AreaCreator_UpdatePreviewTiles(object oPlayer)
{
    object oDataObject = ES_Util_GetDataObject(AREA_CREATOR_SCRIPT_NAME);
    int nRange = GetLocalInt(oDataObject, "TILE_ID_RANGE");
    int nNumPreviewTiles = ObjectArray_Size(oDataObject, "PREVIEW_TILES");

    int nPreviewTile;
    for (nPreviewTile = 0; nPreviewTile < nNumPreviewTiles; nPreviewTile++)
    {
        object oTile = ObjectArray_At(oDataObject, "PREVIEW_TILES", nPreviewTile);
        int nTileID = nRange + nPreviewTile;
        string sTileModel = NWNX_Tileset_GetTileModel(AREA_CREATOR_TILESET, nTileID);

        SetLocalInt(oTile, "TILE_ID", nTileID);

        if (sTileModel != "")
        {
            if (!GetLocalInt(oPlayer, "dummy_tile_" + IntToString(nTileID)))
            {
                NWNX_Player_SetResManOverride(oPlayer, 2002, "dummy_tile_" + IntToString(nTileID), sTileModel);
                SetLocalInt(oPlayer, "dummy_tile_" + IntToString(nTileID), TRUE);
            }

            SetName(oTile, sTileModel);

            AreaCreator_ApplyPreviewEffect(oTile);

            SetUseableFlag(oTile, TRUE);
        }
        else
        {
            SetUseableFlag(oTile, FALSE);
            Effects_RemoveEffectsWithTag(oTile, "TILE_EFFECT");
        }
    }
}

