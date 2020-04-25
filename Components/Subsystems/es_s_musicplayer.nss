/*
    ScriptName: es_s_musicplayer.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: A subsystem that spawns a music player that lets players
                 change the area's music

    Usage: Place a waypoint with tag MUSICPLAYER_SPAWN where you want a
           Gnomish Music Contraption to spawn.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_toolbox"
#include "es_srv_simdialog"

const string MUSICPLAYER_LOG_TAG                = "MusicPlayer";
const string MUSICPLAYER_SCRIPT_NAME            = "es_s_musicplayer";

const string MUSICPLAYER_WAYPOINT_TAG           = "MUSICPLAYER_SPAWN";

const string MUSICPLAYER_NUM_TRACKS             = "NumTracks";
const string MUSICPLAYER_MAX_TRACK_RANGE        = "MaxTrackRange";
const string MUSICPLAYER_TRACK                  = "Track_";
const string MUSICPLAYER_CURRENT_TRACK          = "CurrentTrack";
const string MUSICPLAYER_IS_PLAYING             = "IsPlaying";
const string MUSICPLAYER_IS_DISABLED            = "IsDisabled";

const float MUSICPLAYER_DISABLED_DURATION       = 60.0f;

void MusicPlayer_LoadMusicTracks();
void MusicPlayer_CreateConversation();
void MusicPlayer_SpawnPlaceables(string sSubsystemScript);

void MusicPlayer_PlaySoundAndApplySparks(object oMusicPlayer, string sSound);
int MusicPlayer_GetIsDisabled(object oMusicPlayer = OBJECT_SELF);
void MusicPlayer_DisableMusicPlayer();
void MusicPlayer_ApplyDisabledEffects(object oMusicPlayer);

// @Load
void MusicPlayer_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_USED, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_MELEEATTACKED, EVENTS_EVENT_FLAG_DEFAULT, TRUE);
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_PLACEABLE_ON_SPELLCASTAT, EVENTS_EVENT_FLAG_DEFAULT, TRUE);

    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_ACTION_TAKEN, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE, TRUE);
    SimpleDialog_SubscribeEvent(sSubsystemScript, SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION, TRUE);

    MusicPlayer_LoadMusicTracks();
    MusicPlayer_CreateConversation();
    MusicPlayer_SpawnPlaceables(sSubsystemScript);
}

// @EventHandler
void MusicPlayer_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == SIMPLE_DIALOG_EVENT_ACTION_TAKEN)
    {
        object oMusicPlayer = OBJECT_SELF;
        object oPlayer = Events_GetEventData_NWNX_Object("PLAYER");
        int nPage = Events_GetEventData_NWNX_Int("PAGE");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        if (nPage == 1)
        {
            switch (nOption)
            {
                case 1:// Action - Play/Stop Music
                {
                    object oArea = GetArea(oMusicPlayer);
                    if (NWNX_Area_GetMusicIsPlaying(oArea))
                    {
                        MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_trapdisarm");
                        MusicBackgroundStop(oArea);
                    }
                    else
                    {
                        MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_traparm");
                        MusicBackgroundPlay(oArea);
                    }
                    break;
                }

                case 2:// Action - Change Track
                {
                    MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_trapsetoff");
                    SimpleDialog_SetCurrentPage(oPlayer, 2);
                    break;
                }

                case 3:// Action - Leave
                    SimpleDialog_EndConversation(oPlayer);
                    break;
            }
        }
        else
        if (nPage == 2)
        {
            switch (nOption)
            {
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:// Action - Select Track
                {
                    object oArea = GetArea(oMusicPlayer);
                    int nTrack = SimpleDialog_GetListSelection(oPlayer, nOption);

                    MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_picklockopen");

                    SetLocalInt(oMusicPlayer, MUSICPLAYER_CURRENT_TRACK, nTrack);

                    MusicBackgroundChangeNight(oArea, nTrack);
                    MusicBackgroundChangeDay(oArea, nTrack);
                    MusicBackgroundPlay(oArea);

                    SimpleDialog_SetCurrentPage(oPlayer, 1);
                    break;
                }
                case 11:// Action - Next
                {
                    MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_quick_add");
                    SimpleDialog_IncrementListRange(oPlayer);
                    break;
                }
                case 12:// Action - Previous
                {
                    MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_quick_erase");
                    SimpleDialog_DecrementListRange(oPlayer);
                    break;
                }
                case 13:// Action - Back
                {
                    MusicPlayer_PlaySoundAndApplySparks(oMusicPlayer, "gui_select");
                    SimpleDialog_SetCurrentPage(oPlayer, 1);
                    break;
                }
            }
        }
        else
        if (nPage == 3 && nOption == 1)
        {
            SimpleDialog_EndConversation(oPlayer);
        }
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_PAGE)
    {
        object oMusicPlayer = OBJECT_SELF;
        object oPlayer = Events_GetEventData_NWNX_Object("PLAYER");
        int nPage = Events_GetEventData_NWNX_Int("PAGE");

        object oDataObject = ES_Util_GetDataObject(MUSICPLAYER_SCRIPT_NAME);
        int nCurrentTrack = GetLocalInt(oMusicPlayer, MUSICPLAYER_CURRENT_TRACK);
        string sCurrentTrackName = GetLocalString(oDataObject, MUSICPLAYER_TRACK + IntToString(nCurrentTrack));

        if (nPage == 1)
        {
            if (NWNX_Area_GetMusicIsPlaying(GetArea(oMusicPlayer)))
                SimpleDialog_SetOverrideText("The infernal gnomish contraption is playing music.\n\nCurrent track: " + sCurrentTrackName);
            else
                SimpleDialog_SetOverrideText("The infernal gnomish contraption is silent.\n\nCurrent track: " + sCurrentTrackName);
        }
        else
        if (nPage == 2)
        {
            int nNumTracks = GetLocalInt(oDataObject, MUSICPLAYER_NUM_TRACKS);
            int nEnd = SimpleDialog_GetNextListRange(oPlayer);
            int nStart = nEnd - 9;
            nEnd = nEnd > nNumTracks ? nNumTracks : nEnd;

            SimpleDialog_SetOverrideText("Select a music track.\n\nCurrent track: " +
                sCurrentTrackName + "\n\n Showing tracks " + IntToString(nStart) +
                "-" + IntToString(nEnd) + " of " + IntToString(nNumTracks));
        }
    }
    else
    if (sEvent == SIMPLE_DIALOG_EVENT_CONDITIONAL_OPTION)
    {
        object oMusicPlayer = OBJECT_SELF;
        object oPlayer = Events_GetEventData_NWNX_Object("PLAYER");
        int nPage = Events_GetEventData_NWNX_Int("PAGE");
        int nOption = Events_GetEventData_NWNX_Int("OPTION");

        if (nPage == 1 && nOption == 1)
        {
            if (NWNX_Area_GetMusicIsPlaying(GetArea(oMusicPlayer)))
                SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[Stop music]"));
            else
                SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[Play music]"));

            SimpleDialog_SetResult(TRUE);
        }
        else
        if (nPage == 2)
        {
            object oDataObject = ES_Util_GetDataObject(MUSICPLAYER_SCRIPT_NAME);

            switch (nOption)
            {
                case 1:
                case 2:
                case 3:
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                case 9:
                case 10:
                {
                    int nTrack = SimpleDialog_GetListSelection(oPlayer, nOption);
                    string sTrack = GetLocalString(oDataObject, MUSICPLAYER_TRACK + IntToString(nTrack));

                    if (sTrack != "")
                    {
                        SimpleDialog_SetOverrideText(SimpleDialog_Token_Action("[Select '" + sTrack + "']"));
                        SimpleDialog_SetResult(TRUE);
                    }
                    break;
                }

                case 11:
                {
                    int nMaxTrackRange = GetLocalInt(oDataObject, MUSICPLAYER_MAX_TRACK_RANGE);
                    SimpleDialog_SetResult(SimpleDialog_GetNextListRange(oPlayer) < nMaxTrackRange);
                    break;
                }
                case 12:
                {
                    SimpleDialog_SetResult(SimpleDialog_GetListRange(oPlayer) > 0);
                    break;
                }

                case 13:
                    SimpleDialog_SetResult(TRUE);
                    break;
            }
        }
    }
    else
    {
        switch (StringToInt(sEvent))
        {
            case EVENT_SCRIPT_PLACEABLE_ON_USED:
                SimpleDialog_StartConversation(GetLastUsedBy(), OBJECT_SELF, MUSICPLAYER_SCRIPT_NAME, MusicPlayer_GetIsDisabled() ? 3 : 1);
                break;

            case EVENT_SCRIPT_PLACEABLE_ON_MELEEATTACKED:
            case EVENT_SCRIPT_PLACEABLE_ON_SPELLCASTAT:
                MusicPlayer_DisableMusicPlayer();
                break;
        }
    }
}

void MusicPlayer_LoadMusicTracks()
{
    object oDataObject = ES_Util_GetDataObject(MUSICPLAYER_SCRIPT_NAME);
    int nTrack, nNumTracks = NWNX_Util_Get2DARowCount("ambientmusic") - 1;

    SetLocalInt(oDataObject, MUSICPLAYER_NUM_TRACKS, nNumTracks);
    SetLocalInt(oDataObject, MUSICPLAYER_MAX_TRACK_RANGE, SimpleDialog_CalculateMaxRange(nNumTracks));

    for (nTrack = 1; nTrack <= nNumTracks; nTrack++)
    {
        SetLocalString(oDataObject, MUSICPLAYER_TRACK + IntToString(nTrack),
            GetStringByStrRef(StringToInt(Get2DAString("ambientmusic", "Description", nTrack))));
    }

    ES_Util_Log(MUSICPLAYER_LOG_TAG, "* Loaded '" + IntToString(nNumTracks) + "' Music Tracks");
}

void MusicPlayer_CreateConversation()
{
    object oConversation = SimpleDialog_CreateConversation(MUSICPLAYER_SCRIPT_NAME);

    SimpleDialog_AddPage(oConversation, "Music Player Intro Text", TRUE);
        SimpleDialog_AddOption(oConversation, "Play/Stop", TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Change track]"));
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Leave]"));

    SimpleDialog_AddPage(oConversation, "Select a track.", TRUE);
        SimpleDialog_AddOption(oConversation, "1", TRUE);
        SimpleDialog_AddOption(oConversation, "2", TRUE);
        SimpleDialog_AddOption(oConversation, "3", TRUE);
        SimpleDialog_AddOption(oConversation, "4", TRUE);
        SimpleDialog_AddOption(oConversation, "5", TRUE);
        SimpleDialog_AddOption(oConversation, "6", TRUE);
        SimpleDialog_AddOption(oConversation, "7", TRUE);
        SimpleDialog_AddOption(oConversation, "8", TRUE);
        SimpleDialog_AddOption(oConversation, "9", TRUE);
        SimpleDialog_AddOption(oConversation, "10", TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Next]"), TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Previous]"), TRUE);
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Back]"));

    SimpleDialog_AddPage(oConversation, "Sparks are flying and the infernal gnomish contraption is emitting a cacophony of hellish sounds.\n\n... Are those cows?");
        SimpleDialog_AddOption(oConversation, SimpleDialog_Token_Action("[Leave]"));
}

void MusicPlayer_SpawnPlaceables(string sSubsystemScript)
{
    object oDataObject = ES_Util_GetDataObject(MUSICPLAYER_SCRIPT_NAME);

    struct Toolbox_PlaceableData pd;

    pd.nModel = 66;
    pd.sName = "Gnomish Music Contraption";
    pd.sDescription = "A malevolent looking device capable of playing some sick tunes.";
    pd.sTag = MUSICPLAYER_SCRIPT_NAME + "_PLC";
    pd.bPlot = TRUE;
    pd.bUseable = TRUE;

    pd.scriptOnUsed = TRUE;
    pd.scriptOnPhysicalAttacked = TRUE;
    pd.scriptOnSpellCastAt = TRUE;

    string sPlaceableData = Toolbox_GeneratePlaceable(pd);

    int nNth = 0;
    object oSpawnPoint = GetObjectByTag(MUSICPLAYER_WAYPOINT_TAG, nNth);

    while (GetIsObjectValid(oSpawnPoint))
    {
        object oMusicPlayer = Toolbox_CreatePlaceable(sPlaceableData, GetLocation(oSpawnPoint));

        Events_AddObjectToAllDispatchLists(sSubsystemScript, oMusicPlayer);

        SetLocalInt(oMusicPlayer, MUSICPLAYER_CURRENT_TRACK, MusicBackgroundGetDayTrack(GetArea(oMusicPlayer)));

        DestroyObject(oSpawnPoint);

        oSpawnPoint = GetObjectByTag(MUSICPLAYER_WAYPOINT_TAG, ++nNth);
    }
}

void MusicPlayer_PlaySoundAndApplySparks(object oMusicPlayer, string sSound)
{
    PlaySound(sSound);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_COM_BLOOD_SPARK_LARGE), oMusicPlayer);
}

int MusicPlayer_GetIsDisabled(object oMusicPlayer = OBJECT_SELF)
{
    return GetLocalInt(oMusicPlayer, MUSICPLAYER_IS_DISABLED);
}

void MusicPlayer_DisableMusicPlayer()
{
    object oMusicPlayer = OBJECT_SELF;

    if (!MusicPlayer_GetIsDisabled(oMusicPlayer))
    {
        SetLocalInt(oMusicPlayer, MUSICPLAYER_IS_DISABLED, TRUE);

        SimpleDialog_AbortConversation(oMusicPlayer);

        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_GHOST_SMOKE), oMusicPlayer, MUSICPLAYER_DISABLED_DURATION);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_FIREBALL), oMusicPlayer);

        MusicBackgroundStop(GetArea(oMusicPlayer));

        DelayCommand(2.5f, MusicPlayer_ApplyDisabledEffects(oMusicPlayer));

        DelayCommand(MUSICPLAYER_DISABLED_DURATION, DeleteLocalInt(oMusicPlayer, MUSICPLAYER_IS_DISABLED));
    }
}

string MusicPlayer_GetRandomSound()
{
    string sSound;

    switch(Random(36))
    {
        case 0: sSound = "as_cv_drums1"; break;
        case 1: sSound = "as_cv_drums2"; break;
        case 2: sSound = "as_cv_eulpipe1"; break;
        case 3: sSound = "as_cv_eulpipe2"; break;
        case 4: sSound = "as_cv_flute1"; break;
        case 5: sSound = "as_cv_flute2"; break;
        case 6: sSound = "as_cv_lute1"; break;
        case 7: sSound = "as_cv_lute1b"; break;
        case 8: sSound = "as_cv_tamborine1"; break;
        case 9: sSound = "as_cv_tamborine2"; break;
        case 10: sSound = "as_cv_glasbreak1"; break;
        case 11: sSound = "as_cv_glasbreak2"; break;
        case 12: sSound = "as_cv_glasbreak3"; break;
        case 13: sSound = "as_cv_shopmetal1"; break;
        case 14: sSound = "as_cv_shopmetal2"; break;
        case 15: sSound = "as_cv_barglass1"; break;
        case 16: sSound = "as_cv_barglass2"; break;
        case 17: sSound = "as_cv_barglass3"; break;
        case 18: sSound = "as_cv_barglass4"; break;
        case 19: sSound = "as_cv_bell1"; break;
        case 20: sSound = "as_cv_bell2"; break;
        case 21: sSound = "as_an_cow1"; break;
        case 22: sSound = "as_an_cow2"; break;
        case 23: sSound = "as_an_cows1"; break;
        case 24: sSound = "as_an_cows2"; break;
        case 25: sSound = "as_cv_ta-da1"; break;
        case 26: sSound = "c_cow_atk1"; break;
        case 27: sSound = "as_sw_genericcl1"; break;
        case 28: sSound = "as_sw_genericlk1"; break;
        case 29: sSound = "as_sw_genericop1"; break;
        case 30: sSound = "as_sw_lever1"; break;
        case 31: sSound = "as_sw_metalcl1"; break;
        case 32: sSound = "as_sw_metalop1"; break;
        case 33: sSound = "gui_dm_alert"; break;
        case 34: sSound = "gui_magbag_full"; break;
        case 35: sSound = "gui_traparm"; break;
    }

    return sSound;
}

int MusicPlayer_GetRandomVisualEffect()
{
    int nVisualEffect;

    switch(Random(4))
    {
        case 0: nVisualEffect = VFX_IMP_DUST_EXPLOSION; break;
        case 1: nVisualEffect = VFX_IMP_ACID_S; break;
        case 2: nVisualEffect = VFX_IMP_FLAME_M; break;
        case 3: nVisualEffect = VFX_IMP_MAGBLUE; break;
    }

    return nVisualEffect;
}

void MusicPlayer_ApplyDisabledEffects(object oMusicPlayer)
{
    if (MusicPlayer_GetIsDisabled(oMusicPlayer))
    {
        AssignCommand(oMusicPlayer, PlaySound(MusicPlayer_GetRandomSound()));

        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(MusicPlayer_GetRandomVisualEffect()), oMusicPlayer);

        float fDelay = 0.1f + (IntToFloat(Random(40)) / 100.0f);
        DelayCommand(fDelay, AssignCommand(oMusicPlayer, PlaySound(MusicPlayer_GetRandomSound())));

        fDelay = 1.0f + (IntToFloat(Random(25)) / 10.0f);
        DelayCommand(fDelay, MusicPlayer_ApplyDisabledEffects(oMusicPlayer));
    }
}

