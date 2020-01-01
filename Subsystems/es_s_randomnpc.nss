/*
    ScriptName: es_s_randomnpc.nss
    Created by: Daz

    Description: A subsystem that allows the creation of random NPCs
*/

//void main() {}

#include "es_inc_core"
#include "es_inc_sql"

#include "nwnx_creature"

const string RANDOM_NPC_SYSTEM_TAG              = "RandomNPC";
const string RANDOM_NPC_TEMPLATE_TAG            = "RandomNPCTemplate";

const string RANDOM_NPC_PREGENERATE_AMOUNT      = "RandomNPCPregenerateAmount";
const string RANDOM_NPC_PREGENERATE_NAME        = "RandomNPCPregenerateNPC_";

const int RANDOM_NPC_PREGENERATE_MAX            = 200;
const int RANDOM_NPC_PREGENERATE_AMOUNT_ON_INIT = 100;

// Create a new random NPC from scratch
object RandomNPC_CreateNPC(struct RandomNPC_NPCData nd, location locLocation);
// Get a random pre-generated NPC
object RandomNPC_GetRandomPregeneratedNPC(string sTag, location locSpawn);
// Get a random soundset for nGender
int RandomNPC_GetRandomSoundset(int nGender);

// @EventSystem_Init
void RandomNPC_Init(string sEventHandlerScript)
{
    string sNPC = GetCampaignString(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_TEMPLATE_TAG);
    if (sNPC == "")
    {
        ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Generating NPC Template");

            object oNPC = CreateObject(OBJECT_TYPE_CREATURE, "nw_beggmale", GetStartingLocation(), FALSE, RANDOM_NPC_TEMPLATE_TAG);
            SetName(oNPC, "Random NPC Template");
            SetDescription(oNPC, "Random NPC Template");
            SetCreatureAppearanceType(oNPC, APPEARANCE_TYPE_HUMAN);

            int nIndex;
            for (nIndex = CREATURE_PART_RIGHT_FOOT; nIndex <= CREATURE_PART_LEFT_HAND; nIndex++)
            {
                if (nIndex == CREATURE_PART_BELT ||
                    nIndex == CREATURE_PART_RIGHT_SHOULDER ||
                    nIndex == CREATURE_PART_LEFT_SHOULDER)
                    continue;

                SetCreatureBodyPart(nIndex, CREATURE_MODEL_TYPE_SKIN, oNPC);
            }

            sNPC = NWNX_Object_Serialize(oNPC);
            SetCampaignString(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_TEMPLATE_TAG, sNPC);

            DestroyObject(oNPC);
    }

    object oModule = GetModule();

    ES_Util_ExecuteScriptChunk("es_s_randomnpc", nssFunction("RandomNPC_CacheNPCSoundsets"), oModule);
    ES_Util_ExecuteScriptChunk("es_s_randomnpc", nssFunction("RandomNPC_PregenerateRandomNPCs", "RANDOM_NPC_PREGENERATE_AMOUNT_ON_INIT"), oModule);
}

struct RandomNPC_NPCData
{
    string sName;
    string sTag;
    string sDescription;

    int bPlot;

    int nRace;
    int nGender;
    int nHead;

    int nHairColor;
    int nSkinColor;
    int nTatoo1Color;
    int nTatoo2Color;

    int nStandardFaction;

    int bRandomScale;
    int bRandomName;
};

object RandomNPC_CreateNPC(struct RandomNPC_NPCData nd, location locLocation)
{
    object oNPC = NWNX_Object_Deserialize(GetCampaignString(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_TEMPLATE_TAG));

    if (!NWNX_Creature_GetKnowsFeat(oNPC, FEAT_ARMOR_PROFICIENCY_LIGHT))
        NWNX_Creature_AddFeat(oNPC, FEAT_ARMOR_PROFICIENCY_LIGHT);
    if (!NWNX_Creature_GetKnowsFeat(oNPC, FEAT_ARMOR_PROFICIENCY_MEDIUM))
        NWNX_Creature_AddFeat(oNPC, FEAT_ARMOR_PROFICIENCY_MEDIUM);
    if (!NWNX_Creature_GetKnowsFeat(oNPC, FEAT_ARMOR_PROFICIENCY_HEAVY))
        NWNX_Creature_AddFeat(oNPC, FEAT_ARMOR_PROFICIENCY_HEAVY);

    if (nd.nRace < 0 || nd.nRace > 6)
        NWNX_Creature_SetRacialType(oNPC, Random(7));
    else
        NWNX_Creature_SetRacialType(oNPC, nd.nRace);

    SetDescription(oNPC, nd.sDescription);
    SetTag(oNPC, nd.sTag);

    SetPlotFlag(oNPC, nd.bPlot);

    if (nd.bRandomScale)
    {
        SetObjectVisualTransform(oNPC, OBJECT_VISUAL_TRANSFORM_SCALE, 0.85 + IntToFloat(Random(30))/100);
    }

    if (nd.nGender < 0 || nd.nGender > 1)
        NWNX_Creature_SetGender(oNPC, Random(2));
    else
        NWNX_Creature_SetGender(oNPC, nd.nGender);

    SetPortraitResRef(oNPC, !GetGender(oNPC) ? "hu_m_99_" : "hu_f_99_");

    NWNX_Creature_SetSoundset(oNPC, RandomNPC_GetRandomSoundset(GetGender(oNPC)));

    int nRace = GetRacialType(oNPC);
    SetCreatureAppearanceType(oNPC, nRace);

    if (nd.nHead < 0)
    {
        int nModel = 0;
        switch (GetGender(oNPC))
        {
            case GENDER_MALE:
                switch (nRace)
                {
                    case RACIAL_TYPE_DWARF:    nModel = Random(14) + 1; break;
                    case RACIAL_TYPE_ELF:      nModel = Random(18) + 1; break;
                    case RACIAL_TYPE_GNOME:    nModel = Random(13) + 1; break;
                    case RACIAL_TYPE_HALFELF:  nModel = Random(34) + 1; break;
                    case RACIAL_TYPE_HALFLING: nModel = Random(10) + 1; break;
                    case RACIAL_TYPE_HALFORC:  nModel = Random(13) + 1; break;
                    case RACIAL_TYPE_HUMAN:    nModel = Random(34) + 1; break;
                }
                break;

            case GENDER_FEMALE:
                switch (nRace)
                {
                    case RACIAL_TYPE_DWARF:    nModel = Random(12) + 1; break;
                    case RACIAL_TYPE_ELF:      nModel = Random(16) + 1; break;
                    case RACIAL_TYPE_GNOME:    nModel = Random(9)  + 1; break;
                    case RACIAL_TYPE_HALFELF:  nModel = Random(27) + 1; break;
                    case RACIAL_TYPE_HALFLING: nModel = Random(11) + 1; break;
                    case RACIAL_TYPE_HALFORC:  nModel = Random(12) + 1; break;
                    case RACIAL_TYPE_HUMAN:    nModel = Random(27) + 1; break;
                }
                break;
        }

        if (nModel > 0)
            SetCreatureBodyPart(CREATURE_PART_HEAD, nModel, oNPC);
    }
    else
        SetCreatureBodyPart(CREATURE_PART_HEAD, nd.nHead, oNPC);

    if (!nd.bRandomName)
        SetName(oNPC, nd.sName);
    else
    {
        string sName;
        int nLTR1 = 3 * GetRacialType(oNPC) + GetGender(oNPC) + 2;
        int nLTR2 = 3 * GetRacialType(oNPC) + 4;

        if (nLTR1 > 22)
            sName = RandomName(Random(3) - 1);
        else
            sName = RandomName(nLTR1) + " " + RandomName(nLTR2);

        SetName(oNPC, sName);
    }

    if (nd.nHairColor < 0)
    {
        int nHair = d20();
        switch (nHair)
        {
            case 15: nHair = 166; break;
            case 16: nHair = 167; break;
            case 17: nHair = 124; break;
            case 18: nHair = 31;  break;
            case 19: nHair = 47;  break;
            case 20: nHair = 0;   break;
        }
        SetColor(oNPC, COLOR_CHANNEL_HAIR, nHair);
    }
    else
        SetColor(oNPC, COLOR_CHANNEL_HAIR, nd.nHairColor);

    if (nd.nSkinColor < 0)
    {
        int nSkin = d6();
        switch (nSkin)
        {
            case 5: nSkin = 12; break;
            case 6: nSkin = 0;  break;
        }
        SetColor(oNPC, COLOR_CHANNEL_SKIN, nSkin);
    }
    else
        SetColor(oNPC, COLOR_CHANNEL_SKIN, nd.nSkinColor);

    if (nd.nTatoo1Color < 0)
        SetColor(oNPC, COLOR_CHANNEL_TATTOO_1, Random(176));
    else
        SetColor(oNPC, COLOR_CHANNEL_TATTOO_1, nd.nTatoo1Color);

    if (nd.nTatoo2Color < 0)
        SetColor(oNPC, COLOR_CHANNEL_TATTOO_2, Random(176));
    else
        SetColor(oNPC, COLOR_CHANNEL_TATTOO_2, nd.nTatoo2Color);

    ChangeToStandardFaction(oNPC, nd.nStandardFaction);

    AssignCommand(oNPC, SetFacing(GetFacingFromLocation(locLocation)));

    NWNX_Object_AddToArea(oNPC, GetAreaFromLocation(locLocation), GetPositionFromLocation(locLocation));

    return oNPC;
}

object RandomNPC_GenerateRandomNPC(location locLocation)
{
    struct RandomNPC_NPCData nd;
    nd.sTag = RANDOM_NPC_TEMPLATE_TAG;
    nd.sDescription = " ";

    nd.nRace = -1;
    nd.nGender = -1;
    nd.nHead = -1;
    nd.nHairColor = -1;
    nd.nSkinColor = -1;
    nd.nTatoo1Color = -1;
    nd.nTatoo2Color = -1;
    nd.nStandardFaction = STANDARD_FACTION_COMMONER;
    nd.bRandomScale = TRUE;
    nd.bRandomName = TRUE;

    object oNPC = RandomNPC_CreateNPC(nd, locLocation);

    return oNPC;
}

void RandomNPC_PregenerateRandomNPCs(int nAmount)
{
    int nCurrentAmount = GetCampaignInt(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_PREGENERATE_AMOUNT);
    int nTotal = nCurrentAmount + nAmount;

    ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Pre-generated NPC amount: " + IntToString(nCurrentAmount) + "/" + IntToString(RANDOM_NPC_PREGENERATE_MAX));

    if (nTotal > RANDOM_NPC_PREGENERATE_MAX)
        return;

    ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Generating an additional '" + IntToString(nAmount) + "' random NPCs");

    SetCampaignInt(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_PREGENERATE_AMOUNT, nTotal);

    location locLocation = GetStartingLocation();

    int nIndex;
    for (nIndex = nCurrentAmount; nIndex < nCurrentAmount + nAmount; nIndex++)
    {
        object oNPC = RandomNPC_GenerateRandomNPC(locLocation);

        StoreCampaignObject(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_PREGENERATE_NAME + IntToString(nIndex), oNPC);

        DestroyObject(oNPC);
    }

    ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Done! New cached NPC amount: " + IntToString(nIndex) + "/" + IntToString(RANDOM_NPC_PREGENERATE_MAX));
}

object RandomNPC_GetRandomPregeneratedNPC(string sTag, location locSpawn)
{
    int nCount = GetCampaignInt(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_PREGENERATE_AMOUNT);
    object oNPC = RetrieveCampaignObject(GetModuleName() + "_" + RANDOM_NPC_SYSTEM_TAG, RANDOM_NPC_PREGENERATE_NAME + IntToString(Random(nCount)), locSpawn);

    SetTag(oNPC, sTag);

    return oNPC;
}

void RandomNPC_CacheNPCSoundsets()
{
    string sSoundset2DA = "soundset";

    if (SQLite_GetTableExists(RANDOM_NPC_SYSTEM_TAG + "_" + sSoundset2DA))
    {
        ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Table for '" + sSoundset2DA + "' already exists, skipping!");
        return;
    }

    ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "* Creating table for '" + sSoundset2DA + "'");

    string sQuery = "CREATE TABLE IF NOT EXISTS " + RANDOM_NPC_SYSTEM_TAG + "_" + sSoundset2DA + " ( SoundsetNum INTEGER UNIQUE, Gender INTEGER NOT NULL, Type INTEGER NOT NULL );";
    NWNX_SQL_PrepareQuery(sQuery);
    NWNX_SQL_ExecutePreparedQuery();

    int nNumRows = NWNX_Util_Get2DARowCount(sSoundset2DA);

    sQuery = "INSERT INTO " + RANDOM_NPC_SYSTEM_TAG + "_" + sSoundset2DA + " (SoundsetNum, Gender, Type) VALUES (?, ?, ?);";
    NWNX_SQL_PrepareQuery(sQuery);

    int nIndex;
    for (nIndex = 0; nIndex < nNumRows; nIndex++)
    {
        int nType = StringToInt(Get2DAString(sSoundset2DA, "TYPE", nIndex));

        if (nType == 3)
        {
            int nGender = StringToInt(Get2DAString(sSoundset2DA, "GENDER", nIndex));

            ES_Util_Log(RANDOM_NPC_SYSTEM_TAG, "  > Inserting Soundset: Index: '" + IntToString(nIndex) +
                "', Type: '" + IntToString(nType) + "', Gender: '" + IntToString(nGender) + "'");

            NWNX_SQL_PreparedInt(0, nIndex);
            NWNX_SQL_PreparedInt(1, nGender);
            NWNX_SQL_PreparedInt(2, nType);
            NWNX_SQL_ExecutePreparedQuery();
        }
    }
}

int RandomNPC_GetRandomSoundset(int nGender)
{
    int bReturn = 0;

    string sQuery = "SELECT SoundsetNum FROM " + RANDOM_NPC_SYSTEM_TAG + "_soundset WHERE Gender = ? ORDER BY RANDOM() LIMIT 1;";

    NWNX_SQL_PrepareQuery(sQuery);
    NWNX_SQL_PreparedInt(0, nGender);
    NWNX_SQL_ExecutePreparedQuery();

    if (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        bReturn = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
    }

    return bReturn;
}

