/*
    ScriptName: es_s_sailing.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Player Tileset Visibility Area]

    Description: A hack job combined with smoke and mirrors~
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_toolbox"
#include "es_srv_tiles"

#include "nwnx_player"
#include "nwnx_tileset"


const string SAILING_LOG_TAG                    = "Sailing";
const string SAILING_SCRIPT_NAME                = "es_s_sailing";
object SAILING_DATA_OBJECT                      = ES_Util_GetDataObject(SAILING_SCRIPT_NAME);
const string SAILING_AREA_TAG                   = "ARE_SAILING";
const float SAILING_TILE_SIZE                   = 10.0f;
const float SAILING_TILE_HEIGHT_OFFSET          = -9.5f;

const string SAILING_TILE_TAG                   = "SAILING_TILE";

const int SAILING_ROW_NUM_TILES                 = 13;
const string SAILING_TILES_ROW_ARRAY            = "SailingRow_";
const string SAILING_TILESET_NAME               = TILESET_RESREF_RURAL;
const int SAILING_WATER_TILE_ID                 = 20;
const float SAILING_TILESET_HEIGHT_OFFSET       = -9.5f;
const int SAILING_VISUALEFFECT_START_ROW        = 1000;
const string SAILING_VISUALEFFECT_DUMMY_NAME    = "dummy_tile_";


object Sailing_GetArea()            { return GetLocalObject(SAILING_DATA_OBJECT, "SAILING_AREA"); }
int Sailing_GetAreaWidth()          { return GetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_WIDTH"); }
int Sailing_GetAreaHeight()         { return GetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_HEIGHT"); }
vector Sailing_GetAreaCenter()      { return GetLocalVector(SAILING_DATA_OBJECT, "SAILING_AREA_CENTER"); }
vector Sailing_GetAreaStart()       { return GetLocalVector(SAILING_DATA_OBJECT, "SAILING_AREA_START"); }
int Sailing_GetAreaCenterColumn()   { return GetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_CENTER_COLUMN"); }

int Sailing_Tile_GetTileID(object oTile)                                { return GetLocalInt(oTile, "SAILING_TILE_ID"); }
void Sailing_Tile_SetTileID(object oTile, int nTileID)                  { SetLocalInt(oTile, "SAILING_TILE_ID", nTileID); }
int Sailing_Tile_GetTileOrientation(object oTile)                       { return GetLocalInt(oTile, "SAILING_TILE_ORIENTATION"); }
void Sailing_Tile_SetTileOrientation(object oTile, int nOrientation)    { SetLocalInt(oTile, "SAILING_TILE_ORIENTATION", nOrientation); }
int Sailing_Tile_GetTileHeight(object oTile)                            { return GetLocalInt(oTile, "SAILING_TILE_HEIGHT"); }
void Sailing_Tile_SetTileHeight(object oTile, int nHeight)              { SetLocalInt(oTile, "SAILING_TILE_HEIGHT", nHeight); }

void Sailing_SetupArea(object oArea);

void Sailing_CreateTileRows();
void Sailing_MoveRow(int nRow, int nPosition, int nNextY);

// @Load
void Sailing_Load(string sSubsystemScript)
{
    Sailing_SetupArea(GetObjectByTag(SAILING_AREA_TAG));

    Sailing_CreateTileRows();

    int nRow;
    for (nRow = 0; nRow < Sailing_GetAreaHeight(); nRow++)
    {
        Sailing_MoveRow(nRow, nRow, 0);
    }

    Tile_SetTilesetIgnoreTerrainOrCrosser(SAILING_TILESET_NAME, "Road", TRUE);
    Tile_SetTilesetIgnoreTerrainOrCrosser(SAILING_TILESET_NAME, "Wall1", TRUE);
    Tile_SetTilesetIgnoreTerrainOrCrosser(SAILING_TILESET_NAME, "Wall2", TRUE);
}

// @EventHandler
void Sailing_EventHandler(string sSubsystemScript, string sEvent)
{

}

void Sailing_SetupArea(object oArea)
{
    int nWidth = GetAreaSize(AREA_WIDTH, oArea);
    int nHeight = GetAreaSize(AREA_HEIGHT, oArea);
    vector vCenter = Vector((nWidth * SAILING_TILE_SIZE) * 0.5f, (nHeight * SAILING_TILE_SIZE) * 0.5f, 0.0f);
    vector vStart = Vector(SAILING_TILE_SIZE * 0.5f, (nHeight * SAILING_TILE_SIZE) - (SAILING_TILE_SIZE * 0.5f), 0.0f);

    SetLocalObject(SAILING_DATA_OBJECT, "SAILING_AREA", oArea);

    SetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_WIDTH", nWidth);
    SetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_HEIGHT", nHeight);

    SetLocalVector(SAILING_DATA_OBJECT, "SAILING_AREA_CENTER", vCenter);
    SetLocalVector(SAILING_DATA_OBJECT, "SAILING_AREA_START", vStart);

    SetLocalInt(SAILING_DATA_OBJECT, "SAILING_AREA_CENTER_COLUMN", (nWidth / 2) - 1);
}

void Sailing_CreateTileRows()
{
    object oArea = Sailing_GetArea();
    vector vCenter = Sailing_GetAreaCenter();
    vector sStart = Sailing_GetAreaStart();
    int nWidth = Sailing_GetAreaWidth();
    int nHeight = Sailing_GetAreaHeight();
    location locSpawn = Location(oArea, Vector(vCenter.x, vCenter.y, SAILING_TILE_SIZE), 0.0f);

    struct Toolbox_PlaceableData pd;
    pd.nModel = 157;
    pd.sTag = SAILING_TILE_TAG;
    pd.bPlot = TRUE;
    pd.bUseable = FALSE;
    pd.fFacingAdjustment = 90.0f;
    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nRow;
    for(nRow = 0; nRow < nHeight; nRow++)
    {
        int nTile;
        for (nTile = 0; nTile < nWidth; nTile++)
        {
            object oTile = Toolbox_CreatePlaceable(sPlaceableData, locSpawn);
            float fX = sStart.x + ((nTile * SAILING_TILE_SIZE) - vCenter.x);

            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Z, SAILING_TILESET_HEIGHT_OFFSET);
            SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_X, fX);
            ObjectArray_Insert(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nRow), oTile);
            Sailing_Tile_SetTileID(oTile, -1);
        }
    }
}

void Sailing_UpdateTile(object oTile)
{
    Effects_RemoveEffectsWithTag(oTile, "SAILING_TILE_EFFECT");

    int nTileID = Sailing_Tile_GetTileID(oTile);

    if (nTileID == -1)
        return;

    int nTileOrientation = Sailing_Tile_GetTileOrientation(oTile);
    int nTileHeight = Sailing_Tile_GetTileHeight(oTile);
    float fTileHeightTransition = Tiles_GetTilesetHeightTransition(SAILING_TILESET_NAME);

    float fOrientation;
    switch (nTileOrientation)
    {
        case 0: fOrientation = 0.0f; break;
        case 1: fOrientation = 90.0f; break;
        case 2: fOrientation = 180.0f; break;
        case 3: fOrientation = 270.0f; break;
    }

    vector vRotate = Vector(fOrientation, 0.0f, 0.0f);
    float fHeight = nTileHeight * fTileHeightTransition;
    vector vTranslate = Vector(0.0f, 0.0f, fHeight);

    effect eTile = EffectVisualEffect(SAILING_VISUALEFFECT_START_ROW + nTileID, FALSE, 1.0f, vTranslate, vRotate);
    eTile = TagEffect(eTile, "SAILING_TILE_EFFECT");

    DelayCommand(0.0f, ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTile, oTile));
}

int Sailing_GetNextArrayNum(int nRow)
{
    nRow++;

    if (nRow == Sailing_GetAreaHeight())
        return 0;
    else
        return nRow;
}

string Sailing_HandleCornerConflict(string sCorner1, string sCorner2)
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

struct NWNX_Tileset_TileEdgesAndCorners Sailing_GetNeighborEdgesAndCorners(object oTile)
{
    struct NWNX_Tileset_TileEdgesAndCorners str;

     int nTileID = Sailing_Tile_GetTileID(oTile);
     int nOrientation = Sailing_Tile_GetTileOrientation(oTile);

     if (nTileID != -1)
     {
        str = Tiles_GetCornersAndEdgesByOrientation(SAILING_TILESET_NAME, nTileID, nOrientation);

        if (SAILING_TILESET_NAME == TILESET_RESREF_RURAL && Sailing_Tile_GetTileHeight(oTile) == 1)
            str = Tiles_ReplaceTerrainOrCrosser(str, "Grass", "Grass+");
    }

    return str;
}

struct Tiles_Tile Sailing_GetRandomMatchingTile(object oTile, int nRow, int nTile, int nCenterColumn)
{
    struct NWNX_Tileset_TileEdgesAndCorners strQuery;
    int nNextRow = Sailing_GetNextArrayNum(nRow);

    if (nTile == 0)
    {
        object oBottom = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nNextRow), nTile);
        struct NWNX_Tileset_TileEdgesAndCorners strBottom = Sailing_GetNeighborEdgesAndCorners(oBottom);

        strQuery.sBottom = strBottom.sTop;
        strQuery.sBottomRight = strBottom.sTopRight;
        strQuery.sBottomLeft = strBottom.sTopLeft;
    }
    else if (nTile == (nCenterColumn - 1))
    {
        object oLeft = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nRow), nTile - 1);
        struct NWNX_Tileset_TileEdgesAndCorners strLeft = Sailing_GetNeighborEdgesAndCorners(oLeft);

        object oBottom = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nNextRow), nTile);
        struct NWNX_Tileset_TileEdgesAndCorners strBottom = Sailing_GetNeighborEdgesAndCorners(oBottom);

        strQuery.sRight = "Water";
        strQuery.sBottom = strBottom.sTop;
        strQuery.sLeft = strLeft.sRight;

        strQuery.sTopLeft = strLeft.sTopRight;
        strQuery.sTopRight = "Water";
        strQuery.sBottomRight = "Water";
        strQuery.sBottomLeft = Sailing_HandleCornerConflict(strBottom.sTopLeft, strLeft.sBottomRight);
    }
    else if (nTile == (nCenterColumn + 1))
    {
        object oBottom = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nNextRow), nTile);
        struct NWNX_Tileset_TileEdgesAndCorners strBottom = Sailing_GetNeighborEdgesAndCorners(oBottom);

        strQuery.sBottom = strBottom.sTop;
        strQuery.sLeft = "Water";

        strQuery.sTopLeft = "Water";
        strQuery.sBottomRight = strBottom.sTopRight;
        strQuery.sBottomLeft = "Water";

    }
    else
    {
        object oLeft = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nRow), nTile - 1);
        struct NWNX_Tileset_TileEdgesAndCorners strLeft = Sailing_GetNeighborEdgesAndCorners(oLeft);

        object oBottom = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nNextRow), nTile);
        struct NWNX_Tileset_TileEdgesAndCorners strBottom = Sailing_GetNeighborEdgesAndCorners(oBottom);

        strQuery.sBottom = strBottom.sTop;
        strQuery.sLeft = strLeft.sRight;

        strQuery.sTopLeft = strLeft.sTopRight;
        strQuery.sBottomRight = strBottom.sTopRight;
        strQuery.sBottomLeft = Sailing_HandleCornerConflict(strBottom.sTopLeft, strLeft.sBottomRight);
    }

    return Tiles_GetRandomMatchingTile(SAILING_TILESET_NAME, strQuery);
}

object Sailing_GetTileEffectOverrideDataObject(object oPlayer)
{
    return ES_Util_GetDataObject("SAILNG_TILE_EFFECT_OVERRIDE_" + GetObjectUUID(oPlayer));
}

void Sailing_SetTileEffectOverride(object oPlayer, object oOverrideDataObject, int nTileID, string sTileModel)
{
    if (!GetLocalInt(oOverrideDataObject, "TILE_ID_" + IntToString(nTileID)))
    {
        NWNX_Player_SetResManOverride(oPlayer, 2002, SAILING_VISUALEFFECT_DUMMY_NAME + IntToString(nTileID), sTileModel);
        SetLocalInt(oOverrideDataObject, "TILE_ID_" + IntToString(nTileID), TRUE);
    }
}

void Sailing_SetTileEffectOverrideForArea(int nTileID, string sTileModel)
{
    object oArea = Sailing_GetArea();
    object oPlayer = GetFirstPC();

    while (oPlayer != OBJECT_INVALID)
    {
        if (GetArea(oPlayer) == oArea)
        {
            object oPlayerDataObject = Sailing_GetTileEffectOverrideDataObject(oPlayer);
            Sailing_SetTileEffectOverride(oPlayer, oPlayerDataObject, nTileID, sTileModel);
        }

        oPlayer = GetNextPC();
    }
}

void Sailing_MoveRow(int nRow, int nPosition, int nNextY)
{
    int nWidth = Sailing_GetAreaWidth();
    int nHeight = Sailing_GetAreaHeight();
    int nCenterColumn = nWidth / 2;

    if (nPosition != -1)
    {
        nNextY = (nPosition * 10) * 100;
        nPosition = -1;
    }

    float fAreaHeight = nHeight * SAILING_TILE_SIZE;
    float fTileY = ((nNextY / 100.0f) + (fAreaHeight * 0.5f)) - fAreaHeight;

    int nTile;
    for(nTile = 0; nTile < nWidth; nTile++)
    {
        object oTile = ObjectArray_At(SAILING_DATA_OBJECT, SAILING_TILES_ROW_ARRAY + IntToString(nRow), nTile);

        if (!nNextY)
        {
            if (GetIsObjectValid(GetFirstPC()))
            {
                int nTileID = -1, nOrientation, nHeight;
                string sTileModel;

                if (nTile == nCenterColumn)
                    nTileID = SAILING_WATER_TILE_ID;
                else
                {
                    struct Tiles_Tile tile = Sailing_GetRandomMatchingTile(oTile, nRow, nTile, nCenterColumn);
                    nTileID = tile.nTileID;
                    nOrientation = tile.nOrientation;
                    nHeight = tile.nHeight;
                }

                if (nTileID != -1)
                    sTileModel = Tiles_GetTileModel(SAILING_TILESET_NAME, nTileID);

                Sailing_Tile_SetTileID(oTile, nTileID);
                Sailing_Tile_SetTileOrientation(oTile, nOrientation);
                Sailing_Tile_SetTileHeight(oTile, nHeight);

                if (nTileID != -1)
                    Sailing_SetTileEffectOverrideForArea(nTileID, sTileModel);

                Sailing_UpdateTile(oTile);
            }
        }

        SetObjectVisualTransform(oTile, OBJECT_VISUAL_TRANSFORM_TRANSLATE_Y, -fTileY);
    }

    nNextY += 25;

    if (nNextY == Sailing_GetAreaHeight() * 1000)
        nNextY = 0;

    DelayCommand(0.1f, Sailing_MoveRow(nRow, nPosition, nNextY));
}

