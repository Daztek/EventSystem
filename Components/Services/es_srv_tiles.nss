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

const string TILES_LOG_TAG                          = "Tiles";
const string TILES_SCRIPT_NAME                      = "es_srv_tiles";

const int TILES_USE_MODULE_DATABASE                 = TRUE;

const string TILESET_RESREF_MEDIEVAL_RURAL_2        = "trm02";
const string TILESET_RESREF_MEDIEVAL_CITY_2         = "tcm02";
const string TILESET_RESREF_CASTLE_EXTERIOR_RURAL   = "tno01";
const string TILESET_RESREF_EARLY_WINTER            = "trs02";

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

void Tiles_CreateTables(string sTileset);
void Tiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners Tiles_RotateTileEdgesAndCornersStruct(struct NWNX_Tileset_TileEdgesAndCorners str);
struct NWNX_Tileset_TileEdgesAndCorners Tiles_GetCornersAndEdgesByOrientation(string sTileset, int nTileID, int nOrientation);
int Tiles_GetIsGroupTile(string sTileset, int nTileID);
int Tiles_GetIsWhitelistedGroupTile(string sTileset, int nTileID);
void Tiles_ProcessTile(string sTileset, int nTileID);
void Tiles_ProcessGroups(string sTileset);
void Tiles_CheckForDoors(string sTileset, int nTileID);
void Tiles_ProcessTileset(string sTileset);
struct Tiles_Tile Tiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str);

object Tiles_GetTilesetDataObject(string sTileset);
int Tiles_GetTilesetNumTileData(string sTileset);
float Tiles_GetTilesetHeightTransition(string sTileset);
int Tiles_GetTilesetNumTerrain(string sTileset);
int Tiles_GetTilesetNumCrossers(string sTileset);
int Tiles_GetTilesetNumGroups(string sTileset);
string Tiles_GetTilesetTerrain(string sTileset, int nTerrainNum);
string Tiles_GetTilesetCrosser(string sTileset, int nCrosserNum);
int Tiles_GetTileNumDoors(string sTileset, int nTileID);
struct Tiles_DoorData Tiles_GetTileDoorData(string sTileset, int nTileID, int nDoorNumber = 0);
string Tiles_GetTileModel(string sTileset, int nTileID);
int Tile_GetTilesetIgnoreTerrainOrCrosser(string sTileset, string sCrosserOrTerrain);
void Tile_SetTilesetIgnoreTerrainOrCrosser(string sTileset, string sCrosserOrTerrain, int bIgnore);

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
    Tiles_ProcessTileset(TILESET_RESREF_CITY_EXTERIOR);
    Tiles_ProcessTileset(TILESET_RESREF_DUNGEON);
    Tiles_ProcessTileset(TILESET_RESREF_MEDIEVAL_RURAL_2);
    Tiles_ProcessTileset(TILESET_RESREF_CITY_INTERIOR);
    Tiles_ProcessTileset(TILESET_RESREF_MINES_AND_CAVERNS);
    Tiles_ProcessTileset(TILESET_RESREF_CASTLE_EXTERIOR_RURAL);
    Tiles_ProcessTileset(TILESET_RESREF_EARLY_WINTER);
}

string Tiles_GetDatabaseName(string sTileset, string sType)
{
    if (TILES_USE_MODULE_DATABASE)
        return TILES_SCRIPT_NAME + "_" + sTileset + "_" + sType;
    else
        return sType;
}

void Tiles_CreateTables(string sTileset)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS " + Tiles_GetDatabaseName(sTileset, "Tiles") +" (" +
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
                    "ctc TEXT NOT NULL, " +
                    "PRIMARY KEY(tileID, orientation, height));";
    sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);
    SqlStep(sql);

    sQuery = "CREATE TABLE IF NOT EXISTS " + Tiles_GetDatabaseName(sTileset, "Groups") +" (" +
             "groupID INTEGER NOT NULL PRIMARY KEY, " +
             "name TEXT NOT NULL, " +
             "strRef INTEGER NOT NULL, " +
             "rows INTEGER NOT NULL, " +
             "columns INTEGER NOT NULL, " +
             "numTiles INTEGER NOT NULL);";
    sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);
    SqlStep(sql);

    sQuery = "CREATE TABLE IF NOT EXISTS " + Tiles_GetDatabaseName(sTileset, "GroupTiles") +" (" +
             "groupID INTEGER NOT NULL, " +
             "tileIndex INTEGER NOT NULL, " +
             "tileID INTEGER NOT NULL, " +
             "PRIMARY KEY(groupID, tileIndex));";
    sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);
    SqlStep(sql);
}

string Tiles_GetTerrainAndCrossersAsString(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    return str.sTopLeft + str.sTop + str.sTopRight + str.sRight + str.sBottomRight + str.sBottom + str.sBottomLeft + str.sLeft;
}

void Tiles_InsertTile(string sTileset, int nTileID, int nOrientation, int nHeight, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    string sQuery = "REPLACE INTO " + Tiles_GetDatabaseName(sTileset, "Tiles") + " (tileID, orientation, height, tl, t, tr, r, br, b, bl, l, ctc) " +
                    "VALUES(@tileID, @orientation, @height, @tl, @t, @tr, @r, @br, @b, @bl, @l, @ctc);";
    sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);

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

    SqlBindString(sql, "@ctc", Tiles_GetTerrainAndCrossersAsString(str));

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
        sEdge = "N/A";

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

    // BUG: Fixes a missing crosser
    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (nTileID == 1313)
            str.sLeft = "Stream";
    }

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

int Tiles_GetIsGroupTile(string sTileset, int nTileID)
{
    string sQuery = "SELECT * FROM " + Tiles_GetDatabaseName(sTileset, "GroupTiles") + " WHERE tileID = @tileID;";
    sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);

    SqlBindInt(sql, "@tileID", nTileID);

    return SqlStep(sql);
}

int Tiles_GetIsWhitelistedGroupTile(string sTileset, int nTileID)
{
    if (sTileset == TILESET_RESREF_RURAL)
    {
        switch (nTileID)
        {
            case 113: // Shrine01
            case 118: // Crystal
            case 129: // Tree Hollow
            case 130: // Menhir
            case 131: // Anthill
            case 205: // Ramp
            case 241: // Tree
            case 244: // Cave
                return TRUE;
        }
    }
    /*
    else if (sTileset == TILESET_RESREF_CRYPT)
    {
        switch (nTileID)
        {
            case :
                return TRUE;
        }
    }
    */
    /*
    else if (sTileset == TILESET_RESREF_CASTLE_INTERIOR)
    {
        switch (nTileID)
        {
            case :
                return TRUE;
        }
    }
    */
    else if (sTileset == TILESET_RESREF_CITY_EXTERIOR)
    {
        switch (nTileID)
        {
            case 33: // GC_MainDoor
            case 34: // GC_Breach
            case 42: // Wall Gate
            case 45: // Market01
            case 46: // Market02
            case 47: // Tree
            case 48: // Wagon
            case 49: // StreetLight
            case 50: // SlumHouse01
            case 51: // SlumHouse02
            case 54: // House
            case 114: // SlumMarket01
            case 115: // SlumMarket02
            case 124: // Fountain
            case 125: // VegGarden
            case 128: // FlowerGarden
            case 129: // Construction
            case 130: // BurningBuilding
            case 134: // SewerEntrance02
            case 146: // Gazebo
            case 147: // Well
            case 181: // Footbridge
            case 187: // DockDoor
            case 193: // BridgeDoor
            case 198: // BW_Temple
            case 215: // Boathouse
            case 231: // GC_SmallDoor
            case 258: // WallGap01
            case 259: // WallGap02
            case 260: // WallChunk
            case 273: // CaveEntrance
            case 274: // Ramp
            case 298: // Boat
            case 299: // ElevationDoor01
            case 304: // BW_Breach
            case 316: // ElevationTower2
            case 317: // ElevationTower1
                return TRUE;
        }
    }
    /*
    else if (sTileset == TILESET_RESREF_DUNGEON)
    {
        switch (nTileID)
        {
            case :
                return TRUE;
        }
    }
    */

    return FALSE;
}

void Tiles_ProcessTile(string sTileset, int nTileID)
{
    if (Tiles_GetIsGroupTile(sTileset, nTileID) && !Tiles_GetIsWhitelistedGroupTile(sTileset, nTileID))
        return;

    struct NWNX_Tileset_TileEdgesAndCorners str = Tiles_GetTileEdgesAndCorners(sTileset, nTileID);


    if (sTileset == TILESET_RESREF_CITY_EXTERIOR)
    {
        if (nTileID == 306)
            return;
    }
    else
    if (sTileset == TILESET_RESREF_MEDIEVAL_RURAL_2)
    {
        if (nTileID == 812)
            return;
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

void Tiles_ProcessGroups(string sTileset)
{
    int nNumGroups = Tiles_GetTilesetNumGroups(sTileset);

    if (!nNumGroups)
        return;

    object oDataObject = Tiles_GetTilesetDataObject(sTileset);

    int nGroupNum;
    for (nGroupNum = 0; nGroupNum < nNumGroups; nGroupNum++)
    {
        struct NWNX_Tileset_TilesetGroupData strGroupData = NWNX_Tileset_GetTilesetGroupData(sTileset, nGroupNum);
        int nNumGroupTiles = strGroupData.nRows * strGroupData.nColumns;

        string sQuery = "REPLACE INTO " + Tiles_GetDatabaseName(sTileset, "Groups") + " (groupID, name, strRef, rows, columns, numTiles) " +
                        "VALUES(@groupID, @name, @strRef, @rows, @columns, @numTiles);";
        sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);

        SqlBindInt(sql, "@groupID", nGroupNum);
        SqlBindString(sql, "@name", strGroupData.sName);
        SqlBindInt(sql, "@strRef", strGroupData.nStrRef);
        SqlBindInt(sql, "@rows", strGroupData.nRows);
        SqlBindInt(sql, "@columns", strGroupData.nColumns);
        SqlBindInt(sql, "@numTiles", nNumGroupTiles);

        SqlStep(sql);

        int nGroupTileIndex;

        for (nGroupTileIndex = 0; nGroupTileIndex < nNumGroupTiles; nGroupTileIndex++)
        {
            int nGroupTileID = NWNX_Tileset_GetTilesetGroupTile(nGroupTileIndex);

            sQuery = "REPLACE INTO " + Tiles_GetDatabaseName(sTileset, "GroupTiles") + " (groupID, tileIndex, tileID) " +
                     "VALUES(@groupID, @tileIndex, @tileID);";
            sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);

            SqlBindInt(sql, "@groupID", nGroupNum);
            SqlBindInt(sql, "@tileIndex", nGroupTileIndex);
            SqlBindInt(sql, "@tileID", nGroupTileID);

            SqlStep(sql);
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

    Tiles_CreateTables(sTileset);

    struct NWNX_Tileset_TilesetData str = NWNX_Tileset_GetTilesetData(sTileset);
    SetLocalInt(oTilesetDataObject, "NUM_TILE_DATA", str.nNumTileData);
    SetLocalFloat(oTilesetDataObject, "HEIGHT_TRANSITION", str.fHeightTransition);
    SetLocalInt(oTilesetDataObject, "NUM_TERRAIN", str.nNumTerrain);
    SetLocalInt(oTilesetDataObject, "NUM_CROSSERS", str.nNumCrossers);
    SetLocalInt(oTilesetDataObject, "NUM_GROUPS", str.nNumGroups);

    ES_Util_Log(TILES_LOG_TAG, "Processing tileset: " + (str.nDisplayNameStrRef != -1 ? GetStringByStrRef(str.nDisplayNameStrRef) : str.sUnlocalizedName));

    int nTerrainNum;
    for (nTerrainNum = 0; nTerrainNum < str.nNumTerrain; nTerrainNum++)
    {
        string sTerrain = ES_Util_CapitalizeString(NWNX_Tileset_GetTilesetTerrain(sTileset, nTerrainNum));
        SetLocalString(oTilesetDataObject, "TERRAIN" + IntToString(nTerrainNum), sTerrain);
    }

    int nCrosserNum;
    for (nCrosserNum = 0; nCrosserNum < str.nNumCrossers; nCrosserNum++)
    {
        string sCrosser = ES_Util_CapitalizeString(NWNX_Tileset_GetTilesetCrosser(sTileset, nCrosserNum));
        SetLocalString(oTilesetDataObject, "CROSSER" + IntToString(nCrosserNum), sCrosser);
    }

    Tiles_ProcessGroups(sTileset);

    int nTileID;
    for (nTileID = 0; nTileID < str.nNumTileData; nTileID++)
    {
        Tiles_CheckForDoors(sTileset, nTileID);
        Tiles_ProcessTile(sTileset, nTileID);
    }

    SetLocalInt(oDataObject, "T_" + sTileset, TRUE);
}

string Tiles_GetCornersAndEdgesClause(struct NWNX_Tileset_TileEdgesAndCorners str)
{
    string sWhere;

    if (str.sTopLeft != "")
        sWhere += "AND tl=@tl ";

    if (str.sTop != "")
        sWhere += "AND t=@t ";

    if (str.sTopRight != "")
        sWhere += "AND tr=@tr ";

    if (str.sRight != "")
        sWhere += "AND r=@r ";

    if (str.sBottomRight != "")
        sWhere += "AND br=@br ";

    if (str.sBottom != "")
        sWhere += "AND b=@b ";

    if (str.sBottomLeft != "")
        sWhere += "AND bl=@bl ";

    if (str.sLeft != "")
        sWhere += "AND l=@l ";

    return sWhere;
}

string Tiles_GetIgnoreTerrainOrCrosserClause(string sCrosserOrTerrain)
{
    return "AND ctc NOT LIKE @" + sCrosserOrTerrain + " ";
}

struct Tiles_Tile Tiles_GetRandomMatchingTile(string sTileset, struct NWNX_Tileset_TileEdgesAndCorners str)
{
    struct Tiles_Tile tile;

    string sQuery = "SELECT tileID, orientation, height FROM " + Tiles_GetDatabaseName(sTileset, "Tiles") + " WHERE 1=1 " +
                    Tiles_GetCornersAndEdgesClause(str);

    int nTerrain, nNumTerrain = Tiles_GetTilesetNumTerrain(sTileset);
    for (nTerrain = 0; nTerrain < nNumTerrain; nTerrain++)
    {
        string sTerrain = Tiles_GetTilesetTerrain(sTileset, nTerrain);

        if (Tile_GetTilesetIgnoreTerrainOrCrosser(sTileset, sTerrain))
        {
            sQuery += Tiles_GetIgnoreTerrainOrCrosserClause(sTerrain);
        }
    }

    int nCrosser, nNumCrossers = Tiles_GetTilesetNumCrossers(sTileset);
    for (nCrosser = 0; nCrosser < nNumCrossers; nCrosser++)
    {
        string sCrosser = Tiles_GetTilesetCrosser(sTileset, nCrosser);

        if (Tile_GetTilesetIgnoreTerrainOrCrosser(sTileset, sCrosser))
        {
            sQuery += Tiles_GetIgnoreTerrainOrCrosserClause(sCrosser);
        }
    }

    sQuery += " ORDER BY RANDOM() LIMIT 1;";

    sqlquery sql = SqlPrepareQuery(sTileset, sQuery, TILES_USE_MODULE_DATABASE);

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

    for (nTerrain = 0; nTerrain < nNumTerrain; nTerrain++)
    {
        string sTerrain = Tiles_GetTilesetTerrain(sTileset, nTerrain);

        if (Tile_GetTilesetIgnoreTerrainOrCrosser(sTileset, sTerrain))
        {
            SqlBindString(sql, "@" + sTerrain, "%" + sTerrain + "%");
        }
    }

    for (nCrosser = 0; nCrosser < nNumCrossers; nCrosser++)
    {
        string sCrosser = Tiles_GetTilesetCrosser(sTileset, nCrosser);

        if (Tile_GetTilesetIgnoreTerrainOrCrosser(sTileset, sCrosser))
        {
            SqlBindString(sql, "@" + sCrosser, "%" + sCrosser + "%");
        }
    }

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

int Tiles_GetTilesetNumGroups(string sTileset)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "NUM_GROUPS");
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

string Tiles_GetTileModel(string sTileset, int nTileID)
{
    string sTileModel = NWNX_Tileset_GetTileModel(sTileset, nTileID);

    // BUG: Fix typo'd models
    if (sTileset == TILESET_RESREF_MEDIEVAL_CITY_2)
    {
        if (nTileID == 1600 && sTileModel == "tcm02_f27_14")
            sTileModel = "tcm02_f27_04";
        else if (nTileID == 1026 && sTileModel == "tcm02_f17_14")
            sTileModel = "tcm02_f17_04";
    }

    return sTileModel;
}

int Tile_GetTilesetIgnoreTerrainOrCrosser(string sTileset, string sCrosserOrTerrain)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    return GetLocalInt(oDataObject, "IGNORE_" + sCrosserOrTerrain);
}

void Tile_SetTilesetIgnoreTerrainOrCrosser(string sTileset, string sCrosserOrTerrain, int bIgnore)
{
    object oDataObject = Tiles_GetTilesetDataObject(sTileset);
    SetLocalInt(oDataObject, "IGNORE_" + sCrosserOrTerrain, bIgnore);
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
    if (sTileset == TILESET_RESREF_CITY_EXTERIOR)
        sResRef = Random(2) ? "nw_door_fancy" : "nw_door_strong";
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

