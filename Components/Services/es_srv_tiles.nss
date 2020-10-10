/*
    ScriptName: es_srv_tiles.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Area Tileset]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_area"
#include "nwnx_tileset"

const string TILES_LOG_TAG                      = "Tiles";
const string TILES_SCRIPT_NAME                  = "es_srv_tiles";

struct Tiles_Tile
{
    int nTileID;
    int nOrientation;
    int nHeight;
};

struct Tiles_DoorData
{
    int nType;
    vector vPosition;
    float fOrientation;
    string sResRef;
};

void Tiles_CreateTable(string sTileset);
void Tiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners Tiles_RotateTileEdgesAndCornersStruct(struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners Tiles_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation);
void Tiles_ProcessTile(string sTileset, int nTileID);
void Tiles_CheckForDoors(string sTileset, int nTileID);
void Tiles_ProcessTileset(string sTileset);
struct Tiles_Tile Tiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str);

object Tiles_GetTilesetDataObject(string sTileset);
int Tiles_GetTilesetNumTileData(string sTileset);
float Tiles_GetTilesetHeightTransition(string sTileset);
int Tiles_GetTilesetNumTerrain(string sTileset);
int Tiles_GetTilesetNumCrossers(string sTileset);
string Tiles_GetTilesetTerrain(string sTileset, int nTerrainNum);
string Tiles_GetTilesetCrosser(string sTileset, int nCrosserNum);
int Tiles_GetTileNumDoors(string sTileset, int nTileID);
struct Tiles_DoorData Tiles_GetTileDoorData(string sTileset, int nTileID, int nDoorNumber = 0);

vector Tiles_RotateRealToCanonical(int nOrientation, vector vReal);
vector Tiles_RotateCanonicalToReal(int nOrientation, vector vCanonical);
vector Tiles_RotateRealToCanonicalTile(struct NWNX_Area_TileInfo strTileInfo, vector vReal);
vector Tiles_RotateCanonicalToRealTile(struct NWNX_Area_TileInfo strTileInfo, vector vCanonical);

string Tiles_GetGenericDoorResRef(string sTileset);
object Tiles_CreateDoorOnTile(object oArea, struct NWNX_Area_TileInfo strTileInfo, string sNewTag, int nDoorNum = 0);

// @Load
void Tiles_Load(string sServiceScript)
{
    Tiles_ProcessTileset(TILESET_RESREF_RURAL);
    Tiles_ProcessTileset(TILESET_RESREF_CRYPT);
    Tiles_ProcessTileset(TILESET_RESREF_CASTLE_INTERIOR);
}

void Tiles_CreateTable(string sTileset)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + TILES_SCRIPT_NAME + "_" + sTileset + " (" +
                    "tileID INTEGER NOT NULL, " +
                    "orientation INTEGER NOT NULL, " +
                    "height INTEGER NOT NULL, " +
                    "tl TEXT NOT NULL, " +
                    "t TEXT NOT NULL, " +
                    "tr TEXT NOT NULL, " +
                    "r TEXT NOT NULL, " +
                    "br TEXT NOT NULL, " +
                    "b TEXT NOT NULL, " +
                    "bl TEXT NOT NULL, " +
                    "l TEXT NOT NULL, " +
                    "PRIMARY KEY(tileID, orientation, height));";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);
    SqlStep(sql);
}

void Tiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    string sQuery = "REPLACE INTO " + TILES_SCRIPT_NAME + "_" + sTileset + "(tileID, orientation, height, tl, t, tr, r, br, b, bl, l) " +
                    "VALUES(@tileID, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l);";
    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);

    SqlBindInt(sql, "@tileID", nTileID);
    SqlBindInt(sql, "@orientation", nOrientation);
    SqlBindInt(sql, "@height", nHeight);

    SqlBindString(sql, "@tl", str.sTopLeft);
    SqlBindString(sql, "@t", str.sTop);
    SqlBindString(sql, "@tr", str.sTopRight);
    SqlBindString(sql, "@r", str.sRight);
    SqlBindString(sql, "@br", str.sBottomRight);
    SqlBindString(sql, "@b", str.sBottom);
    SqlBindString(sql, "@bl", str.sBottomLeft);
    SqlBindString(sql, "@l", str.sLeft);

    SqlStep(sql);
}

struct NWNX_Tileset_TileEdgesAndCorners Tiles_RotateTileEdgesAndCornersStruct(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    struct NWNX_Tileset_TileEdgesAndCorners strRetval;

    strRetval.sTopLeft = str.sTopRight;
    strRetval.sTop = str.sRight;
    strRetval.sTopRight = str.sBottomRight;
    strRetval.sRight = str.sBottom;
    strRetval.sBottomRight = str.sBottomLeft;
    strRetval.sBottom = str.sLeft;
    strRetval.sBottomLeft = str.sTopLeft;
    strRetval.sLeft = str.sTop;

    return strRetval;
}

string Tiles_HandleEdgeCase(string sTileset, string sEdge, string sCorner1, string sCorner2)
{
    if (sEdge != "")
        return sEdge;
    else if (sCorner1 == sCorner2)
        sEdge = sCorner1;
    else
    {
        if (sTileset == TILESET_RESREF_RURAL)
        {
            if ((sCorner1 == "Grass" && sCorner2 == "Trees") || (sCorner1 == "Trees" && sCorner2 == "Grass"))
                sEdge = "Grass";
            else if ((sCorner1 == "Water" && sCorner2 == "Trees") || (sCorner1 == "Trees" && sCorner2 == "Water"))
                sEdge == "Water";
            else if ((sCorner1 == "Grass" && sCorner2 == "Grass+") || (sCorner1 == "Grass+" && sCorner2 == "Grass"))
                sEdge == "Grass";
            else if ((sCorner1 == "Water" && sCorner2 == "Grass+") || (sCorner1 == "Grass+" && sCorner2 == "Water"))
                sEdge == "Water";
            else if ((sCorner1 == "Grass+" && sCorner2 == "Trees") || (sCorner1 == "Trees" && sCorner2 == "Grass+"))
                sEdge == "Trees";
            else if ((sCorner1 == "Grass" && sCorner2 == "Water") || (sCorner1 == "Water" && sCorner2 == "Grass"))
                sEdge = "Grass";
        }
        else if (sTileset == TILESET_RESREF_CRYPT)
        {
            if ((sCorner1 == "Wall" && sCorner2 == "Floor") || (sCorner1 == "Floor" && sCorner2 == "Wall"))
                sEdge = "Floor";
            else if ((sCorner1 == "Wall" && sCorner2 == "Pit") || (sCorner1 == "Pit" && sCorner2 == "Wall"))
                sEdge = "Pit";
            else if ((sCorner1 == "Floor" && sCorner2 == "Pit") || (sCorner1 == "Pit" && sCorner2 == "Floor"))
                sEdge = "Pit";
        }
        else if (sTileset == TILESET_RESREF_CASTLE_INTERIOR)
        {

        }
    }

    return sEdge;
}

struct NWNX_Tileset_TileEdgesAndCorners Tiles_FixCapitalization(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    str.sTopLeft = ES_Util_CapitalizeString(str.sTopLeft);
    str.sTop = ES_Util_CapitalizeString(str.sTop);
    str.sTopRight = ES_Util_CapitalizeString(str.sTopRight);
    str.sRight = ES_Util_CapitalizeString(str.sRight);
    str.sBottomRight = ES_Util_CapitalizeString(str.sBottomRight);
    str.sBottom = ES_Util_CapitalizeString(str.sBottom);
    str.sBottomLeft = ES_Util_CapitalizeString(str.sBottomLeft);
    str.sLeft = ES_Util_CapitalizeString(str.sLeft);

    return str;
}

struct NWNX_Tileset_TileEdgesAndCorners Tiles_GetTileEdgesAndCorners(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = Tiles_FixCapitalization(NWNX_Tileset_GetTileEdgesAndCorners(sTileset, nTileID));

    str.sTop = Tiles_HandleEdgeCase(sTileset, str.sTop, str.sTopLeft, str.sTopRight);
    str.sRight = Tiles_HandleEdgeCase(sTileset, str.sRight, str.sTopRight, str.sBottomRight);
    str.sBottom = Tiles_HandleEdgeCase(sTileset, str.sBottom, str.sBottomRight, str.sBottomLeft);
    str.sLeft = Tiles_HandleEdgeCase(sTileset, str.sLeft, str.sBottomLeft, str.sTopLeft);

    return str;
}

struct NWNX_Tileset_TileEdgesAndCorners Tiles_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = Tiles_GetTileEdgesAndCorners(sTileset, nTileID);

    if (!nOrientation)
        return str;

    int nCount;
    for (nCount = 0; nCount < nOrientation; nCount++)
    {
        str = Tiles_RotateTileEdgesAndCornersStruct(str);
    }

    return str;
}

int Tiles_GetHasTerrainOrCrosser(struct NWNX_Tileset_TileEdgesAndCorners str, string sType)
{
    return (str.sTopLeft == sType ||
            str.sTop == sType ||
            str.sTopRight == sType ||
            str.sRight == sType ||
            str.sBottomRight == sType ||
            str.sBottom == sType ||
            str.sBottomLeft == sType ||
            str.sLeft == sType);
}

struct NWNX_Tileset_TileEdgesAndCorners Tiles_ReplaceTerrainOrCrosser(struct NWNX_Tileset_TileEdgesAndCorners str, string sOld, string sNew)
{
    if (str.sTopLeft == sOld) str.sTopLeft = sNew;
    if (str.sTop == sOld) str.sTop = sNew;
    if (str.sTopRight == sOld) str.sTopRight = sNew;
    if (str.sRight == sOld) str.sRight = sNew;
    if (str.sBottomRight == sOld) str.sBottomRight = sNew;
    if (str.sBottom == sOld) str.sBottom = sNew;
    if (str.sBottomLeft == sOld) str.sBottomLeft = sNew;
    if (str.sLeft == sOld) str.sLeft = sNew;

    return str;
}

void Tiles_ProcessTile(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = Tiles_GetTileEdgesAndCorners(sTileset, nTileID);

    // Tiles to outright skip, groups etc
    if (sTileset == TILESET_RESREF_RURAL)
    {
        if ( nTileID == 61 || nTileID == 113 || nTileID == 117 || nTileID == 118 ||
             nTileID == 127 || nTileID == 128 || nTileID == 242 ||
            (nTileID >= 132 && nTileID <= 182) ||
            (nTileID >= 213 && nTileID <= 230) ||
            (nTileID >= 233 && nTileID <= 240) ||
            (nTileID >= 245 && nTileID <= 246) ||
            (nTileID >= 249 && nTileID <= 282) ||
            Tiles_GetHasTerrainOrCrosser(str, "Wall1") ||
            Tiles_GetHasTerrainOrCrosser(str, "Wall2") ||
            (Tiles_GetHasTerrainOrCrosser(str, "Water") && Tiles_GetHasTerrainOrCrosser(str, "Road")))
            return;
    }
    else if (sTileset == TILESET_RESREF_CRYPT)
    {
        if ((nTileID >= 72 && nTileID <= 83) ||
            (nTileID >= 84 && nTileID <= 87) ||
            (nTileID >= 88 && nTileID <= 89) ||
            (nTileID >= 90 && nTileID <= 93) ||
            (nTileID >= 94 && nTileID <= 100) ||
            (nTileID >= 161 && nTileID <= 162) ||
            (nTileID >= 166 && nTileID <= 168))
            return;
    }
    else if (sTileset == TILESET_RESREF_CASTLE_INTERIOR)
    {

    }

    int nOrientation;
    for (nOrientation = 0; nOrientation < 4; nOrientation++)
    {
        Tiles_InsertTile(sTileset, nTileID, nOrientation, 0, str);
        str = Tiles_RotateTileEdgesAndCornersStruct(str);
    }

    // Tiles that can be placed at Grass+ height
    if (sTileset == TILESET_RESREF_RURAL)
    {
        if ((Tiles_GetHasTerrainOrCrosser(str, "Stream") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Grass+") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Trees") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Water")) ||
            (Tiles_GetHasTerrainOrCrosser(str, "Road") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Grass+") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Trees") &&
                !Tiles_GetHasTerrainOrCrosser(str, "Water")) ||
            nTileID == 120)
        {
            str = Tiles_ReplaceTerrainOrCrosser(Tiles_GetTileEdgesAndCorners(sTileset, nTileID), "Grass", "Grass+");

            for (nOrientation = 0; nOrientation < 4; nOrientation++)
            {
                Tiles_InsertTile(sTileset, nTileID, nOrientation, 1, str);
                str = Tiles_RotateTileEdgesAndCornersStruct(str);
            }
        }
    }
}

void Tiles_CheckForDoors(string sTileset, int nTileID)
{
    int nNumDoors = NWNX_Tileset_GetTileNumDoors(sTileset, nTileID);

    if (!nNumDoors)
        return;

    object oDataObject = Tiles_GetTilesetDataObject(sTileset);

    SetLocalInt(oDataObject, "TILE_" + IntToString(nTileID) + "_NUM_DOORS", nNumDoors);

    int nDoorNum;
    for (nDoorNum = 0; nDoorNum < nNumDoors; nDoorNum++)
    {
        string sTileVarName = "TILE_" + IntToString(nTileID) + "_DOOR_" + IntToString(nDoorNum);
        struct NWNX_Tileset_TileDoorData str = NWNX_Tileset_GetTileDoorData(sTileset, nTileID, nDoorNum);

        if (str.nType != -1)
        {
            SetLocalInt(oDataObject, sTileVarName, TRUE);
            SetLocalInt(oDataObject, sTileVarName + "_TYPE", str.nType);

            str.fX += 5.0f;
            str.fY += 5.0f;
            str.fOrientation += 90.0f;

            location locDoorData = Location(OBJECT_INVALID, Vector(str.fX, str.fY, str.fZ), str.fOrientation);
            SetLocalLocation(oDataObject, sTileVarName + "_LOCATION_DATA", locDoorData);

            string sResRef = Get2DAString("doortypes", "TemplateResRef", str.nType);
            SetLocalString(oDataObject, sTileVarName + "_RESREF", sResRef);
        }
    }
}

void Tiles_ProcessTileset(string sTileset)
{
    object oDataObject = ES_Util_GetDataObject(TILES_SCRIPT_NAME);
    if (GetLocalInt(oDataObject, "T_" + sTileset))
        return;

    object oTilesetDataObject = Tiles_GetTilesetDataObject(sTileset);

    Tiles_CreateTable(sTileset);

    struct NWNX_Tileset_TilesetInfo str = NWNX_Tileset_GetTilesetInfo(sTileset);
    SetLocalInt(oTilesetDataObject, "NUM_TILE_DATA", str.nNumTileData);
    SetLocalFloat(oTilesetDataObject, "HEIGHT_TRANSITION", str.fHeightTransition);
    SetLocalInt(oTilesetDataObject, "NUM_TERRAIN", str.nNumTerrain);
    SetLocalInt(oTilesetDataObject, "NUM_CROSSERS", str.nNumCrossers);

    int nTerrainNum;
    for (nTerrainNum = 0; nTerrainNum < str.nNumTerrain; nTerrainNum++)
    {
        string sTerrain = NWNX_Tileset_GetTilesetTerrain(sTileset, nTerrainNum);
        SetLocalString(oTilesetDataObject, "TERRAIN" + IntToString(nTerrainNum), sTerrain);
    }

    int nCrosserNum;
    for (nCrosserNum = 0; nCrosserNum < str.nNumCrossers; nCrosserNum++)
    {
        string sCrosser = NWNX_Tileset_GetTilesetCrosser(sTileset, nCrosserNum);
        SetLocalString(oTilesetDataObject, "CROSSER" + IntToString(nCrosserNum), sCrosser);
    }

    int nTileID;
    for (nTileID = 0; nTileID < str.nNumTileData; nTileID++)
    {
        Tiles_CheckForDoors(sTileset, nTileID);
        Tiles_ProcessTile(sTileset, nTileID);
    }

    SetLocalInt(oDataObject, "T_" + sTileset, TRUE);
}

string Tiles_GetWhereClause(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    string sWhere = "WHERE ";

    if (str.sTopLeft != "")
        sWhere += "tl=@tl AND ";

    if (str.sTop != "")
        sWhere += "t=@t AND ";

    if (str.sTopRight != "")
        sWhere += "tr=@tr AND ";

    if (str.sRight != "")
        sWhere += "r=@r AND ";

    if (str.sBottomRight != "")
        sWhere += "br=@br AND ";

    if (str.sBottom != "")
        sWhere += "b=@b AND ";

    if (str.sBottomLeft != "")
        sWhere += "bl=@bl AND ";

    if (str.sLeft != "")
        sWhere += "l=@l AND ";

    sWhere = GetStringLeft(sWhere, GetStringLength(sWhere) - 4);

    return sWhere;
}

struct Tiles_Tile Tiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    struct Tiles_Tile tile;

    string sQuery = "SELECT tileID, orientation, height FROM " + TILES_SCRIPT_NAME + "_" + sTileset + " " +
                    Tiles_GetWhereClause(str) +
                    " ORDER BY RANDOM() LIMIT 1;";

    sqlquery sql = SqlPrepareQueryObject(GetModule(), sQuery);

    if (str.sTopLeft != "")
        SqlBindString(sql, "@tl", str.sTopLeft);

    if (str.sTop != "")
        SqlBindString(sql, "@t", str.sTop);

    if (str.sTopRight != "")
        SqlBindString(sql, "@tr", str.sTopRight);

    if (str.sRight != "")
        SqlBindString(sql, "@r", str.sRight);

    if (str.sBottomRight != "")
        SqlBindString(sql, "@br", str.sBottomRight);

    if (str.sBottom != "")
        SqlBindString(sql, "@b", str.sBottom);

    if (str.sBottomLeft != "")
        SqlBindString(sql, "@bl", str.sBottomLeft);

    if (str.sLeft != "")
        SqlBindString(sql, "@l", str.sLeft);

    if (SqlStep(sql))
    {
        tile.nTileID = SqlGetInt(sql, 0);
        tile.nOrientation = SqlGetInt(sql, 1);
        tile.nHeight = SqlGetInt(sql, 2);
    }
    else
    {
        tile.nTileID = -1;
        tile.nOrientation = -1;
        tile.nHeight = -1;
    }

    //PrintString("TileID: " + IntToString(tile.nTileID) + ", Orientation: " + IntToString(tile.nOrientation) + ", Height: " + IntToString(tile.nHeight));

    return tile;
}

// *** Data Functions
object Tiles_GetTilesetDataObject(string sTileset)
{
    return ES_Util_GetDataObject(TILES_SCRIPT_NAME + "_T_" + sTileset);
}

int Tiles_GetTilesetNumTileData(string sTileset)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "NUM_TILE_DATA");
}

float Tiles_GetTilesetHeightTransition(string sTileset)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalFloat(oDataObject, "HEIGHT_TRANSITION");
}

int Tiles_GetTilesetNumTerrain(string sTileset)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "NUM_TERRAIN");
}

int Tiles_GetTilesetNumCrossers(string sTileset)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "NUM_CROSSERS");
}

string Tiles_GetTilesetTerrain(string sTileset, int nTerrainNum)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalString(oDataObject, "TERRAIN" + IntToString(nTerrainNum));
}

string Tiles_GetTilesetCrosser(string sTileset, int nCrosserNum)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalString(oDataObject, "CROSSER" + IntToString(nCrosserNum));
}

int Tiles_GetTileNumDoors(string sTileset, int nTileID)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "TILE_" + IntToString(nTileID) + "_NUM_DOORS");
}

struct Tiles_DoorData Tiles_GetTileDoorData(string sTileset, int nTileID, int nDoorNumber = 0)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    int nNumDoors = GetLocalInt(oDataObject, "TILE_" + IntToString(nTileID) + "_NUM_DOORS");
    string sTileVarName = "TILE_" + IntToString(nTileID) + "_DOOR_" + IntToString(nDoorNumber);
    struct Tiles_DoorData str;

    if (nDoorNumber < nNumDoors && GetLocalInt(oDataObject, sTileVarName))
    {
        str.nType = GetLocalInt(oDataObject, sTileVarName + "_TYPE");

        location locDoorData = GetLocalLocation(oDataObject, sTileVarName + "_LOCATION_DATA");
        str.vPosition = GetPositionFromLocation(locDoorData);
        str.fOrientation = GetFacingFromLocation(locDoorData);

        str.sResRef = GetLocalString(oDataObject, sTileVarName + "_RESREF");
    }
    else
        str.nType = -1;

    return str;
}

// *** Rotation Functions
vector Tiles_RotateRealToCanonical(int nOrientation, vector vReal)
{
    vector vCanonical;
    switch (nOrientation)
    {
        case 1:
        {
            vCanonical.x = vReal.y;
            vCanonical.y = 10.0f - vReal.x;
            break;
        }

        case 2:
        {
            vCanonical.x = 10.0f - vReal.x;
            vCanonical.y = 10.0f - vReal.y;
            break;
        }

        case 3:
        {
            vCanonical.x = 10.0f - vReal.y;
            vCanonical.y = vReal.x;
            break;
        }

        default:
            vCanonical = vReal;
            break;

    }

    return vCanonical;
}

vector Tiles_RotateCanonicalToReal(int nOrientation, vector vCanonical)
{
    vector vReal;
    switch (nOrientation)
    {
        case 1:
        {
            vReal.x = 10.0f - vCanonical.y;
            vReal.y = vCanonical.x;
            break;
        }

        case 2:
        {
            vReal.x = 10.0f - vCanonical.x;
            vReal.y = 10.0f - vCanonical.y;
            break;
        }

        case 3:
        {
            vReal.x = vCanonical.y;
            vReal.y = 10.0f - vCanonical.x;
            break;
        }

        default:
            vReal = vCanonical;
            break;

    }

    return vReal;
}

vector Tiles_RotateRealToCanonicalTile(struct NWNX_Area_TileInfo strTileInfo, vector vReal)
{
    vReal.x -= (strTileInfo.nGridX * 10.0f);
    vReal.y -= (strTileInfo.nGridY * 10.0f);
    vector vCanonical = Tiles_RotateRealToCanonical(strTileInfo.nOrientation, vReal);
    vCanonical.x += (strTileInfo.nGridX * 10.0f);
    vCanonical.y += (strTileInfo.nGridY * 10.0f);

    return vCanonical;
}

vector Tiles_RotateCanonicalToRealTile(struct NWNX_Area_TileInfo strTileInfo, vector vCanonical)
{
    vCanonical.x -= (strTileInfo.nGridX * 10.0f);
    vCanonical.y -= (strTileInfo.nGridY * 10.0f);
    vector vReal = Tiles_RotateCanonicalToReal(strTileInfo.nOrientation, vCanonical);
    vReal.x += (strTileInfo.nGridX * 10.0f);
    vReal.y += (strTileInfo.nGridY * 10.0f);

    return vReal;
}

// Door Creation
string Tiles_GetGenericDoorResRef(string sTileset)
{
    string sResRef;

    if (sTileset == TILESET_RESREF_RURAL)
        sResRef = "nw_door_strong";
    else
    if (sTileset == TILESET_RESREF_CRYPT)
        sResRef = Random(2) ? "nw_door_rusted" : "nw_door_grate";
    else
    if (sTileset == TILESET_RESREF_ILLITHID_INTERIOR)
        sResRef = "x3_door_oth003";
    else
        sResRef = "nw_door_fancy";

    return sResRef;
}

object Tiles_CreateDoorOnTile(object oArea, struct NWNX_Area_TileInfo strTileInfo, string sNewTag, int nDoorNum = 0)
{
    string sTileset = GetTilesetResRef(oArea);
    int nNumDoors = Tiles_GetTileNumDoors(sTileset, strTileInfo.nID);

    if (!nNumDoors || nDoorNum >= nNumDoors)
        return OBJECT_INVALID;

    float fTilesetHeighTransition = Tiles_GetTilesetHeightTransition(sTileset);
    struct Tiles_DoorData strDoorData = Tiles_GetTileDoorData(sTileset, strTileInfo.nID, nDoorNum);
    vector vDoorPosition = Tiles_RotateCanonicalToReal(strTileInfo.nOrientation, strDoorData.vPosition);
           vDoorPosition.x += (strTileInfo.nGridX * 10.0f);
           vDoorPosition.y += (strTileInfo.nGridY * 10.0f);
           vDoorPosition.z += (strTileInfo.nHeight * fTilesetHeighTransition);

    switch (strTileInfo.nOrientation)
    {
      /*case 0: strDoorData.fOrientation += 0.0f ; break;*/
        case 1: strDoorData.fOrientation += 90.0f; break;
        case 2: strDoorData.fOrientation += 180.0f; break;
        case 3: strDoorData.fOrientation += 270.0f; break;
    }

    location locSpawn = Location(oArea, vDoorPosition, strDoorData.fOrientation);

    if (!strDoorData.nType)
        strDoorData.sResRef = Tiles_GetGenericDoorResRef(sTileset);

    return NWNX_Util_CreateDoor(strDoorData.sResRef, locSpawn, sNewTag, strDoorData.nType);
}

