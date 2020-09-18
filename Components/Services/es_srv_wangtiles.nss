/*
    ScriptName: es_srv_wangtiles.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Tileset]

    Description:
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_tileset"

const string WANGTILES_LOG_TAG          = "WangTiles";
const string WANGTILES_SCRIPT_NAME      = "es_srv_wangtiles";

struct WangTiles_Tile
{
    int nTileID;
    int nOrientation;
    int nHeight;
};

void WangTiles_CreateTable(string sTileset);
void WangTiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners WangTiles_RotateStruct(struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners WangTiles_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation);
void WangTiles_ProcessTile(string sTileset, int nTileID);
void WangTiles_ProcessTileset(string sTileset);
struct WangTiles_Tile WangTiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str);

// @Load
void WangTiles_Load(string sServiceScript)
{

}

void WangTiles_CreateTable(string sTileset)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + WANGTILES_SCRIPT_NAME + "_" + sTileset + " (" +
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

void WangTiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    string sQuery = "REPLACE INTO " + WANGTILES_SCRIPT_NAME + "_" + sTileset + "(tileID, orientation, height, tl, t, tr, r, br, b, bl, l) " +
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

struct NWNX_Tileset_TileEdgesAndCorners WangTiles_RotateStruct(struct NWNX_Tileset_TileEdgesAndCorners str)
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

string WangTiles_HandleEdgeCase(string sTileset, string sEdge, string sCorner1, string sCorner2)
{
    if (sEdge != "")
        return sEdge;
    else
    {
        if (sTileset == TILESET_RESREF_RURAL)
        {
            if (sCorner1 == sCorner2)
                sEdge = sCorner1;
            else if ((sCorner1 == "Grass" && sCorner2 == "Trees") || (sCorner1 == "Trees" && sCorner2 == "Grass"))
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
        else
        if (sTileset == TILESET_RESREF_CRYPT)
        {
            if (sCorner1 == sCorner2)
                sEdge = sCorner1;
            else if ((sCorner1 == "Wall" && sCorner2 == "Floor") || (sCorner1 == "Floor" && sCorner2 == "Wall"))
                sEdge = "Floor";
            else if ((sCorner1 == "Wall" && sCorner2 == "Pit") || (sCorner1 == "Pit" && sCorner2 == "Wall"))
                sEdge = "Pit";
            else if ((sCorner1 == "Floor" && sCorner2 == "Pit") || (sCorner1 == "Pit" && sCorner2 == "Floor"))
                sEdge = "Pit";
        }
    }

    return sEdge;
}

struct NWNX_Tileset_TileEdgesAndCorners WangTiles_GetTileEdgesAndCorners(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = NWNX_Tileset_GetTileEdgesAndCorners(sTileset, nTileID);

    str.sTop = WangTiles_HandleEdgeCase(sTileset, str.sTop, str.sTopLeft, str.sTopRight);
    str.sRight = WangTiles_HandleEdgeCase(sTileset, str.sRight, str.sTopRight, str.sBottomRight);
    str.sBottom = WangTiles_HandleEdgeCase(sTileset, str.sBottom, str.sBottomRight, str.sBottomLeft);
    str.sLeft = WangTiles_HandleEdgeCase(sTileset, str.sLeft, str.sBottomLeft, str.sTopLeft);

    return str;
}

struct NWNX_Tileset_TileEdgesAndCorners WangTiles_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = WangTiles_GetTileEdgesAndCorners(sTileset, nTileID);

    if (!nOrientation)
        return str;

    int nCount;
    for (nCount = 0; nCount < nOrientation; nCount++)
    {
        str = WangTiles_RotateStruct(str);
    }

    return str;
}

int WangTiles_GetHasTerrainOrCrosser(struct NWNX_Tileset_TileEdgesAndCorners str, string sType)
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

struct NWNX_Tileset_TileEdgesAndCorners WangTiles_ReplaceTerrainOrCrosser(struct NWNX_Tileset_TileEdgesAndCorners str, string sOld, string sNew)
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

void WangTiles_ProcessTile(string sTileset, int nTileID)
{
    struct NWNX_Tileset_TileEdgesAndCorners str = WangTiles_GetTileEdgesAndCorners(sTileset, nTileID);

    // ***
    // Terrain or Crosser types to skip outright
    if (sTileset == TILESET_RESREF_RURAL)
    {
        if (WangTiles_GetHasTerrainOrCrosser(str, "Wall1") ||
            WangTiles_GetHasTerrainOrCrosser(str, "Wall2") ||
            (WangTiles_GetHasTerrainOrCrosser(str, "Water") && WangTiles_GetHasTerrainOrCrosser(str, "Road")))
            return;
    }
    // ***

    int nOrientation;
    for (nOrientation = 0; nOrientation < 4; nOrientation++)
    {
        WangTiles_InsertTile(sTileset, nTileID, nOrientation, 0, str);
        str = WangTiles_RotateStruct(str);
    }

    // Tiles that can be placed at Grass+ height
    if (sTileset == TILESET_RESREF_RURAL)
    {
        if ((WangTiles_GetHasTerrainOrCrosser(str, "Stream") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Grass+") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Trees") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Water")) ||
            (WangTiles_GetHasTerrainOrCrosser(str, "Road") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Grass+") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Trees") &&
                !WangTiles_GetHasTerrainOrCrosser(str, "Water")) ||
            nTileID == 120)
        {
            str = WangTiles_ReplaceTerrainOrCrosser(WangTiles_GetTileEdgesAndCorners(sTileset, nTileID), "Grass", "Grass+");

            for (nOrientation = 0; nOrientation < 4; nOrientation++)
            {
                WangTiles_InsertTile(sTileset, nTileID, nOrientation, 1, str);
                str = WangTiles_RotateStruct(str);
            }
        }
    }
}

void WangTiles_ProcessTileset(string sTileset)
{
    WangTiles_CreateTable(sTileset);

    struct NWNX_Tileset_TilesetInfo str = NWNX_Tileset_GetTilesetInfo(sTileset);

    int nTileID;
    for (nTileID = 0; nTileID < str.nNumTileData; nTileID++)
    {
        // ***
        // Tiles to outright skip, groups etc
        if (sTileset == TILESET_RESREF_RURAL)
        {
            if ( nTileID == 61 || nTileID == 113 || nTileID == 117 || nTileID == 118 ||
                 nTileID == 127 || nTileID == 128 || nTileID == 242 ||
                (nTileID >= 132 && nTileID <= 182) ||
                (nTileID >= 213 && nTileID <= 230) ||
                (nTileID >= 233 && nTileID <= 240) ||
                (nTileID >= 245 && nTileID <= 246) ||
                (nTileID >= 249 && nTileID <= 282))
                continue;
        }
        else
        if (sTileset == TILESET_RESREF_CRYPT)
        {
            if ((nTileID >= 72 && nTileID <= 83) ||
                (nTileID >= 84 && nTileID <= 87) ||
                (nTileID >= 88 && nTileID <= 89) ||
                (nTileID >= 90 && nTileID <= 93) ||
                (nTileID >= 94 && nTileID <= 100) ||
                (nTileID >= 161 && nTileID <= 162) ||
                (nTileID >= 166 && nTileID <= 168))
                continue;
        }
        // ***

        WangTiles_ProcessTile(sTileset, nTileID);
    }
}

string GetWhereClause(struct NWNX_Tileset_TileEdgesAndCorners str)
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

struct WangTiles_Tile WangTiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    struct WangTiles_Tile tile;

    string sQuery = "SELECT tileID, orientation, height FROM " + WANGTILES_SCRIPT_NAME + "_" + sTileset + " " +
                    GetWhereClause(str) +
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

    PrintString("TileID: " + IntToString(tile.nTileID) + ", Orientation: " + IntToString(tile.nOrientation) + ", Height: " + IntToString(tile.nHeight));

    return tile;
}

