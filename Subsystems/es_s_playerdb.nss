/*
    ScriptName: es_s_playerdb.nss
    Created by: Daz

    Description: A simple persistent world player database subsystem using SQLite
*/

//void main() {}

#include "es_s_worldtimer"
#include "nwnx_sql"
#include "nwnx_player"

const string PLAYERDB_SYSTEM_TAG    = "PlayerDatabase";

const string PLAYERDB_TABLE_NAME    = "playerdb";

const string PLAYERDB_PLAYER_ID     = "PlayerDB_PlayerID";

// @EventSystem_Init
void PlayerDB_Init(string sEventHandlerScript);
// @EventSystem_EventHandler
void PlayerDB_EventHandler(string sEventHandlerScript, string sEvent);

void PlayerDB_CreateTable();
int PlayerDB_GetPlayerID(object oPlayer);
int PlayerDB_InsertPlayer(object oPlayer);
void PlayerDB_ClientEnter(object oPlayer, int nPlayerID);
void PlayerDB_ClientExit(object oPlayer);
void PlayerDB_LoadPersistentLocations();
void PlayerDB_SaveCharacters();
void PlayerDB_ModuleShutdown();

void PlayerDB_Init(string sEventHandlerScript)
{
    PlayerDB_CreateTable();

    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_LOAD);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN, ES_CORE_EVENT_FLAG_AFTER);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER, ES_CORE_EVENT_FLAG_BEFORE);
    ES_Core_SubscribeEvent_Object(sEventHandlerScript, EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT, ES_CORE_EVENT_FLAG_AFTER);

    SubscribeToWorldTimerEvent(sEventHandlerScript, WORLD_TIMER_EVENT_5_MINUTES);
}

void PlayerDB_EventHandler(string sEventHandlerScript, string sEvent)
{
    if (sEvent == WORLD_TIMER_EVENT_5_MINUTES)
    {
        PlayerDB_SaveCharacters();
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_MODULE_ON_MODULE_LOAD:
            {
                PlayerDB_LoadPersistentLocations();
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_MODULE_SHUTDOWN:
            {
                PlayerDB_ModuleShutdown();
                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_ENTER:
            {
                object oPlayer = GetEnteringObject();

                int nPlayerID = PlayerDB_GetPlayerID(oPlayer);

                if (!nPlayerID)
                    nPlayerID = PlayerDB_InsertPlayer(oPlayer);
                else
                    PlayerDB_ClientEnter(oPlayer, nPlayerID);

                break;
            }

            case EVENT_SCRIPT_MODULE_ON_CLIENT_EXIT:
            {
                object oPlayer = GetExitingObject();

                PlayerDB_ClientExit(oPlayer);

                break;
            }
        }
    }
}

void PlayerDB_CreateTable()
{
    string sPlayerDBTable = "CREATE TABLE IF NOT EXISTS " + PLAYERDB_TABLE_NAME + " ("  +
                            "id INTEGER PRIMARY KEY, "                                  +
                            "charactername TEXT NOT NULL DEFAULT '', "                  +
                            "bicname TEXT NOT NULL DEFAULT '', "                        +
                            "cdkey TEXT NOT NULL DEFAULT '', "                          +
                            "playername TEXT NOT NULL DEFAULT '', "                     +
                            "location TEXT NOT NULL DEFAULT '', "                       +
                            "online INT NOT NULL DEFAULT 0, "                           +
                            "dead INT NOT NULL DEFAULT 0, "                             +
                            "lastonline INT NOT NULL DEFAULT 0);";

    NWNX_SQL_ExecuteQuery(sPlayerDBTable);
}

int PlayerDB_GetPlayerID(object oPlayer)
{
    int nPlayerID = GetLocalInt(oPlayer, PLAYERDB_PLAYER_ID);

    if (!nPlayerID)
    {
        string sGetPlayerID = "SELECT id FROM " + PLAYERDB_TABLE_NAME + " WHERE cdkey=? AND bicname=?";

        NWNX_SQL_PrepareQuery(sGetPlayerID);
        NWNX_SQL_PreparedString(0, GetPCPublicCDKey(oPlayer));
        NWNX_SQL_PreparedString(1, NWNX_Player_GetBicFileName(oPlayer));
        NWNX_SQL_ExecutePreparedQuery();

        if (NWNX_SQL_ReadyToReadNextRow())
        {
            NWNX_SQL_ReadNextRow();
            nPlayerID = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
            SetLocalInt(oPlayer, PLAYERDB_PLAYER_ID, nPlayerID);
        }
    }

    return nPlayerID;
}

int PlayerDB_InsertPlayer(object oPlayer)
{
    string sInsertPlayer = "INSERT INTO " + PLAYERDB_TABLE_NAME +
        " (charactername, bicname, cdkey, playername, location, online, dead, lastonline) VALUES(?, ?, ?, ?, ?, ?, ?, strftime('%s','now'))";

    NWNX_SQL_PrepareQuery(sInsertPlayer);

    NWNX_SQL_PreparedString(0, GetName(oPlayer));
    NWNX_SQL_PreparedString(1, NWNX_Player_GetBicFileName(oPlayer));
    NWNX_SQL_PreparedString(2, GetPCPublicCDKey(oPlayer));
    NWNX_SQL_PreparedString(3, GetPCPlayerName(oPlayer));
    NWNX_SQL_PreparedString(4, ES_Util_LocationToString(GetStartingLocation()));
    NWNX_SQL_PreparedInt(5, TRUE);
    NWNX_SQL_PreparedInt(6, FALSE);

    NWNX_SQL_ExecutePreparedQuery();

    int nInsertID = 0;
    string sGetLastInsertID = "SELECT last_insert_rowid()";
    NWNX_SQL_ExecuteQuery(sGetLastInsertID);

    if (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        nInsertID = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
        SetLocalInt(oPlayer, PLAYERDB_PLAYER_ID, nInsertID);
    }

    return nInsertID;
}

void PlayerDB_ClientEnter(object oPlayer, int nPlayerID)
{
    string sClientEnter = "UPDATE " + PLAYERDB_TABLE_NAME + " SET online=? WHERE id=?";

    NWNX_SQL_PrepareQuery(sClientEnter);

    NWNX_SQL_PreparedInt(0, TRUE);
    NWNX_SQL_PreparedInt(1, nPlayerID);

    NWNX_SQL_ExecutePreparedQuery();

    sClientEnter = "SELECT dead, datetime(lastonline, 'unixepoch') FROM " + PLAYERDB_TABLE_NAME + " WHERE id=?";

    NWNX_SQL_PrepareQuery(sClientEnter);
    NWNX_SQL_PreparedInt(0, nPlayerID);

    NWNX_SQL_ExecutePreparedQuery();

    if (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        int bDead = StringToInt(NWNX_SQL_ReadDataInActiveRow(0));
        string sTime = NWNX_SQL_ReadDataInActiveRow(1);

        SendMessageToPC(oPlayer, "Last Online: " + sTime + " GMT");

        if (bDead)
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oPlayer);
    }
}

void PlayerDB_ClientExit(object oPlayer)
{
    string sClientExit = "UPDATE " + PLAYERDB_TABLE_NAME + " SET location=?, online=?, dead=?, lastonline=strftime('%s','now') WHERE id=?";

    NWNX_SQL_PrepareQuery(sClientExit);

    NWNX_SQL_PreparedString(0, ES_Util_LocationToString(GetLocation(oPlayer)));
    NWNX_SQL_PreparedInt(1, FALSE);
    NWNX_SQL_PreparedInt(2, GetIsDead(oPlayer));
    NWNX_SQL_PreparedInt(3, PlayerDB_GetPlayerID(oPlayer));

    NWNX_SQL_ExecutePreparedQuery();
}

void PlayerDB_LoadPersistentLocations()
{
    string sLoadPersistentLocations = "SELECT cdkey, bicname, location FROM " + PLAYERDB_TABLE_NAME;

    NWNX_SQL_ExecuteQuery(sLoadPersistentLocations);

    while (NWNX_SQL_ReadyToReadNextRow())
    {
        NWNX_SQL_ReadNextRow();

        string sCDKey = NWNX_SQL_ReadDataInActiveRow(0);
        string sBicName = NWNX_SQL_ReadDataInActiveRow(1);
        location locLocation = ES_Util_StringToLocation(NWNX_SQL_ReadDataInActiveRow(2));

        object oWaypoint = CreateObject(OBJECT_TYPE_WAYPOINT, "nw_waypoint001", locLocation);

        if (GetIsObjectValid(GetArea(oWaypoint)))
        {
            NWNX_Player_SetPersistentLocation(sCDKey, sBicName, oWaypoint, TRUE);
        }
    }
}

void PlayerDB_SaveCharacters()
{
    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        SendMessageToPC(oPlayer, "Saving your character...");

        ExportSingleCharacter(oPlayer);

        oPlayer = GetNextPC();
    }
}

void PlayerDB_ModuleShutdown()
{
    string sModuleShutdown = "UPDATE " + PLAYERDB_TABLE_NAME + " SET location=?, online=?, dead=?, lastonline=strftime('%s','now') WHERE id=?";

    NWNX_SQL_PrepareQuery(sModuleShutdown);

    object oPlayer = GetFirstPC();

    while (GetIsObjectValid(oPlayer))
    {
        NWNX_SQL_PreparedString(0, ES_Util_LocationToString(GetLocation(oPlayer)));
        NWNX_SQL_PreparedInt(1, FALSE);
        NWNX_SQL_PreparedInt(2, GetIsDead(oPlayer));
        NWNX_SQL_PreparedInt(3, PlayerDB_GetPlayerID(oPlayer));

        NWNX_SQL_ExecutePreparedQuery();

        oPlayer = GetNextPC();
    }
}

