/*
    ScriptName: es_s_quickbar.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Creature]

    Description: A subsystem that allows players to save and load quickbar configurations
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_profiler"
#include "es_srv_chatcom"
#include "nwnx_creature"

const string QUICKBAR_LOG_TAG                   = "Quickbar";
const string QUICKBAR_SCRIPT_NAME               = "es_s_quickbar";

const string QUICKBAR_CHATCOMMAND_NAME          = "qb";
const string QUICKBAR_CHATCOMMAND_DESCRIPTION   = "Save or Load Quickbar Configurations.";

// @Load
void Quickbar_Load(string sSubsystemScript)
{
    string sQuery = "CREATE TABLE IF NOT EXISTS quickbar_data (" +
                    "uuid TEXT NOT NULL, " +
                    "name TEXT NOT NULL, " +
                    "quickbar TEXT NOT NULL, " +
                    "PRIMARY KEY(uuid, name));";
    sqlquery sql = SqlPrepareQueryCampaign(sSubsystemScript, sQuery);
    SqlStep(sql);

    ChatCommand_Register(sSubsystemScript, "Quickbar_ChatCommand", CHATCOMMAND_GLOBAL_PREFIX + QUICKBAR_CHATCOMMAND_NAME, "", QUICKBAR_CHATCOMMAND_DESCRIPTION);
}

string Quickbar_GetQuickbar(object oPlayer, string sName)
{
    string sSerializedQuickbar;
    string sQuery = "SELECT quickbar FROM quickbar_data WHERE uuid=@uuid AND name=@name;";
    sqlquery sql = SqlPrepareQueryCampaign(QUICKBAR_SCRIPT_NAME, sQuery);

    SqlBindString(sql, "@uuid", GetObjectUUID(oPlayer));
    SqlBindString(sql, "@name", sName);

    return SqlStep(sql) ? SqlGetString(sql, 0) : "";
}

void Quickbar_SaveQuickbar(object oPlayer, string sName, string sSerializedQuickbar)
{
    string sQuery = "REPLACE INTO quickbar_data (uuid, name, quickbar) VALUES(@uuid, @name, @quickbar);";
    sqlquery sql = SqlPrepareQueryCampaign(QUICKBAR_SCRIPT_NAME, sQuery);

    SqlBindString(sql, "@uuid", GetObjectUUID(oPlayer));
    SqlBindString(sql, "@name", sName);
    SqlBindString(sql, "@quickbar", sSerializedQuickbar);
    SqlStep(sql);
}

void Quickbar_DeleteQuickbar(object oPlayer, string sName)
{
    string sQuery = "DELETE FROM quickbar_data WHERE uuid=@uuid AND name=@name;";
    sqlquery sql = SqlPrepareQueryCampaign(QUICKBAR_SCRIPT_NAME, sQuery);

    SqlBindString(sql, "@uuid", GetObjectUUID(oPlayer));
    SqlBindString(sql, "@name", sName);
    SqlStep(sql);
}

string Quickbar_ListQuickbars(object oPlayer)
{
    string sQuickbarList, sQuery = "SELECT name FROM quickbar_data WHERE uuid=@uuid;";
    sqlquery sql = SqlPrepareQueryCampaign(QUICKBAR_SCRIPT_NAME, sQuery);

    SqlBindString(sql, "@uuid", GetObjectUUID(oPlayer));

    while (SqlStep(sql))
    {
        sQuickbarList += SqlGetString(sql, 0) + ", ";
    }

    return GetSubString(sQuickbarList, 0, GetStringLength(sQuickbarList) - 2);
}

void Quickbar_ChatCommand(object oPlayer, string sOption, int nVolume)
{
    string sParams;

    if ((sParams = ChatCommand_Parse(sOption, "list")) != CHATCOMMAND_PARSE_ERROR)
    {
        string sQuickbarList = Quickbar_ListQuickbars(oPlayer);

        if (sQuickbarList != "")
            ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Available quickbars: " + sQuickbarList);
        else
            ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "No saved quickbars found.");
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "load")) != CHATCOMMAND_PARSE_ERROR)
    {
        sParams = trim(sParams);

        if (sParams != "")
        {
            int bSuccess = FALSE;
            string sSerializedQuickbar = Quickbar_GetQuickbar(oPlayer, sParams);

            if (sSerializedQuickbar != "")
                bSuccess = NWNX_Creature_DeserializeQuickbar(oPlayer, sSerializedQuickbar);

            if (bSuccess)
                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Loaded: " + sParams);
            else
                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Failed to load: " + sParams);
        }
        else
            ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Invalid name.");
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "save")) != CHATCOMMAND_PARSE_ERROR)
    {
        sParams = trim(sParams);

        if (sParams != "")
        {
            int bSuccess = FALSE;
            string sSerializedQuickbar = NWNX_Creature_SerializeQuickbar(oPlayer);

            if (sSerializedQuickbar != "")
            {
                Quickbar_SaveQuickbar(oPlayer, sParams, sSerializedQuickbar);
                bSuccess = TRUE;
            }

            if (bSuccess)
                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Saved: " + sParams);
            else
                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Failed to save: " + sParams);
        }
        else
            ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Invalid name.");
    }
    else
    if ((sParams = ChatCommand_Parse(sOption, "delete")) != CHATCOMMAND_PARSE_ERROR)
    {
        sParams = trim(sParams);

        if (sParams != "")
        {
            if (Quickbar_GetQuickbar(oPlayer, sParams) != "")
            {
                Quickbar_DeleteQuickbar(oPlayer, sParams);

                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Deleted: " + sParams);
            }
            else
                ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Quickbar '" + sParams + "' does not exist.");
        }
        else
            ChatCommand_SendInfoMessage(oPlayer, QUICKBAR_LOG_TAG, "Invalid name.");
    }
    else
    {
        string sHelp  = "Available " + ES_Util_ColorString(QUICKBAR_LOG_TAG, "070") + " Commands:\n";
               sHelp += "\n" + ES_Util_ColorString("list", "070") + " - List your saved Quickbars";
               sHelp += "\n" + ES_Util_ColorString("load [name]", "070") + " - Load a Quickbar";
               sHelp += "\n" + ES_Util_ColorString("save [name]", "070") + " - Save your current Quickbar";
               sHelp += "\n" + ES_Util_ColorString("delete [name]", "070") + " - Delete a Quickbar";

        SendMessageToPC(oPlayer, sHelp);
    }

    SetPCChatMessage("");
}

