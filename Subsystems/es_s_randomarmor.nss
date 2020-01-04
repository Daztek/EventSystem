/*
    ScriptName: es_s_randomarmor.nss
    Created by: Daz

    Description: A subsystem that allows the creation of random chest armor
*/

//void main() {}

#include "es_inc_core"
#include "es_inc_sql"

#include "nwnx_item"

const string RANDOM_ARMOR_SYSTEM_TAG    = "RandomArmor";
const string RANDOM_ARMOR_TEMPLATE_TAG  = "RandomArmorTemplate";

void RandomArmor_CacheArmorParts();
void RandomArmor_PrepareTemplateArmor();

string RandomArmor_GetTableFromArmorModelType(int nArmorModelPart);
int RandomArmor_GetRandomPartByType(int nArmorModelPart, int nMinPartNum = 0, float fMinAC = 0.0f, float fMaxAC = 10.0f);

object RandomArmor_GetClothes(object oTarget = OBJECT_INVALID);

// @EventSystem_Init
void RandomArmor_Init(string sEventHandlerScript)
{
    RandomArmor_CacheArmorParts();

    RandomArmor_PrepareTemplateArmor();
}

void RandomArmor_CacheArmorParts()
{
    object oDataObject = ES_Util_GetDataObject(RANDOM_ARMOR_SYSTEM_TAG);
    string sParts2DAArray = ES_Util_GetResRefArray(oDataObject, 2017/* 2DA */, "parts_.+", FALSE);

    ES_Util_Log(RANDOM_ARMOR_SYSTEM_TAG, "* Caching armor parts in database");
    ES_Util_ExecuteScriptChunkForArrayElements(oDataObject, sParts2DAArray, "es_s_randomarmor", nssFunction("RandomArmor_InsertArmorParts2DA", "sArrayElement"), GetModule());
    ES_Util_StringArray_Clear(oDataObject, sParts2DAArray);
}

void RandomArmor_InsertArmorParts2DA(string sParts2DA)
{
    if (SQLite_GetTableExists(RANDOM_ARMOR_SYSTEM_TAG + "_" + sParts2DA))
    {
        ES_Util_Log(RANDOM_ARMOR_SYSTEM_TAG, "  > Table for '" + sParts2DA + "' already exists, skipping!");
        return;
    }

    ES_Util_Log(RANDOM_ARMOR_SYSTEM_TAG, "  > Creating table for '" + sParts2DA + "'");

    string sQuery = "CREATE TABLE IF NOT EXISTS " + RANDOM_ARMOR_SYSTEM_TAG + "_" + sParts2DA + " ( PartNum INTEGER UNIQUE, ACBonus REAL NOT NULL );";
    NWNX_SQL_PrepareQuery(sQuery);
    NWNX_SQL_ExecutePreparedQuery();

    int nIndex;
    int nNumRows = NWNX_Util_Get2DARowCount(sParts2DA);

    sQuery = "INSERT INTO " + RANDOM_ARMOR_SYSTEM_TAG + "_" + sParts2DA + " (PartNum, ACBonus) VALUES (?, ?);";
    NWNX_SQL_PrepareQuery(sQuery);

    for (nIndex = 0; nIndex < nNumRows; nIndex++)
    {
        string sACBonus = Get2DAString(sParts2DA, "ACBONUS", nIndex);

        if (sACBonus != "")
        {
            if (sParts2DA == "parts_shin" && (nIndex >= 18 && nIndex <= 21)) continue; // Pirate Shins
            if (sParts2DA == "parts_foot" && (nIndex >= 13 && nIndex <= 16)) continue; // Pirate Feet
            if (sParts2DA == "parts_hand" && (nIndex == 9)) continue; // Pirate Hands

            ES_Util_Log(RANDOM_ARMOR_SYSTEM_TAG, "    > Inserting Armor Part: Index: '" + IntToString(nIndex) +  "', ACBonus: '" + sACBonus + "'");

            NWNX_SQL_PreparedInt(0, nIndex);
            NWNX_SQL_PreparedFloat(1, StringToFloat(sACBonus));
            NWNX_SQL_ExecutePreparedQuery();
        }
    }
}

void RandomArmor_PrepareTemplateArmor()
{
    object oItem = CreateObject(OBJECT_TYPE_ITEM, "nw_cloth027", GetStartingLocation(), FALSE, RANDOM_ARMOR_TEMPLATE_TAG);

    SetName(oItem, "Random Armor Template");
    SetDescription(oItem, "Random Armor Template");
    SetDroppableFlag(oItem, FALSE);

    string sItem = NWNX_Object_Serialize(oItem);

    ES_Util_SetString(ES_Util_GetDataObject(RANDOM_ARMOR_SYSTEM_TAG), RANDOM_ARMOR_TEMPLATE_TAG, sItem);

    DestroyObject(oItem);
}

string RandomArmor_GetTableFromArmorModelType(int nArmorModelPart)
{
    string sTable = RANDOM_ARMOR_SYSTEM_TAG + "_parts_";
    switch (nArmorModelPart)
    {
        case ITEM_APPR_ARMOR_MODEL_RFOOT:
        case ITEM_APPR_ARMOR_MODEL_LFOOT:     return sTable + "foot";
        case ITEM_APPR_ARMOR_MODEL_RSHIN:
        case ITEM_APPR_ARMOR_MODEL_LSHIN:     return sTable + "shin";
        case ITEM_APPR_ARMOR_MODEL_LTHIGH:
        case ITEM_APPR_ARMOR_MODEL_RTHIGH:    return sTable + "legs";
        case ITEM_APPR_ARMOR_MODEL_PELVIS:    return sTable + "pelvis";
        case ITEM_APPR_ARMOR_MODEL_TORSO:     return sTable + "chest";
        case ITEM_APPR_ARMOR_MODEL_BELT:      return sTable + "belt";
        case ITEM_APPR_ARMOR_MODEL_NECK:      return sTable + "neck";
        case ITEM_APPR_ARMOR_MODEL_RFOREARM:
        case ITEM_APPR_ARMOR_MODEL_LFOREARM:  return sTable + "forearm";
        case ITEM_APPR_ARMOR_MODEL_RBICEP:
        case ITEM_APPR_ARMOR_MODEL_LBICEP:    return sTable + "bicep";
        case ITEM_APPR_ARMOR_MODEL_RSHOULDER:
        case ITEM_APPR_ARMOR_MODEL_LSHOULDER: return sTable + "shoulder";
        case ITEM_APPR_ARMOR_MODEL_RHAND:
        case ITEM_APPR_ARMOR_MODEL_LHAND:     return sTable + "hand";
        case ITEM_APPR_ARMOR_MODEL_ROBE :     return sTable + "robe";
    }

    return "";
}

int RandomArmor_GetRandomPartByType(int nArmorModelPart, int nMinPartNum = 0, float fMinAC = 0.0f, float fMaxAC = 10.0f)
{
    int bReturn = 0;
    string sTable = RandomArmor_GetTableFromArmorModelType(nArmorModelPart);
    string sQuery = "SELECT PartNum FROM " + sTable + " WHERE ACBonus >= ? AND ACBonus <= ? AND PartNum >= ? ORDER BY RANDOM() LIMIT 1;";

    NWNX_SQL_PrepareQuery(sQuery);
    NWNX_SQL_PreparedFloat(0, fMinAC);
    NWNX_SQL_PreparedFloat(1, fMaxAC);
    NWNX_SQL_PreparedInt(2, nMinPartNum);
    NWNX_SQL_ExecutePreparedQuery();

    if (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        bReturn = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
    }

    return bReturn;
}

object RandomArmor_GetClothes(object oTarget = OBJECT_INVALID)
{
    object oItem = NWNX_Object_Deserialize(ES_Util_GetString(ES_Util_GetDataObject(RANDOM_ARMOR_SYSTEM_TAG), RANDOM_ARMOR_TEMPLATE_TAG));

    float fMinPartAC = 0.0f;
    float fMaxPartAC = 0.08f;

    float fMinChestAC = 0.0f;
    float fMaxChestAC = 2.0f;

    float fMinRobeAC = 0.0f;
    float fMaxRobeAC = 2.0f;

    int nValue;

    if (Random(10) > 7)
    {
        nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_BELT, 0, fMinPartAC, fMaxPartAC);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_BELT, nValue);
    }

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LBICEP, 0, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LBICEP, nValue);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RBICEP, nValue);

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_TORSO, 2, fMinChestAC, fMaxChestAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_TORSO, nValue);

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LFOOT, 2, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LFOOT, nValue);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RFOOT, nValue);

    if (Random(10) > 7)
    {
        nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LFOREARM, 0, fMinPartAC, fMaxPartAC);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LFOREARM, nValue);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RFOREARM, nValue);
    }

    if (Random(10) > 6)
    {
        nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LHAND, 0, fMinPartAC, fMaxPartAC);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LHAND, nValue);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RHAND, nValue);
    }

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LTHIGH, 2, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LTHIGH, nValue);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RTHIGH, nValue);

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_NECK, 1, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_NECK, nValue);

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_PELVIS, 1, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_PELVIS, nValue);

    nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LSHIN, 2, fMinPartAC, fMaxPartAC);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LSHIN, nValue);
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RSHIN, nValue);

    if (!Random(10))
    {
        nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_LSHOULDER, 0, fMinPartAC, fMaxPartAC);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_LSHOULDER, nValue);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_RSHOULDER, nValue);
    }

    if (Random(10) < 2)
    {
        nValue = RandomArmor_GetRandomPartByType(ITEM_APPR_ARMOR_MODEL_ROBE, 0, fMinRobeAC, fMaxRobeAC);
        NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_ROBE, nValue);
    }

    // Colors
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_CLOTH1, Random(25));
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_CLOTH2, Random(25));

    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_LEATHER1, Random(25));
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_LEATHER2, Random(25));

    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_METAL1, Random(16));
    NWNX_Item_SetItemAppearance(oItem, ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_METAL2, Random(16));

    if (oTarget == OBJECT_INVALID)
        return oItem;
    else
    {
        object oCopy = CopyItem(oItem, oTarget);
        SetDroppableFlag(oCopy, FALSE);
        DestroyObject(oItem);
        return oCopy;
    }
}

