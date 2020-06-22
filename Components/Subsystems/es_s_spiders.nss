/*
    ScriptName: es_s_spiders.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[]

    Description: Help, spiders.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "es_srv_toolbox"
#include "x0_i0_position"

const string SPIDERS_LOG_TAG                = "SpiderExplosion";
const string SPIDERS_SCRIPT_NAME            = "es_s_spiders";

const string SPIDERS_COCOON_WAYPOINT_TAG    = "SPIDERS_COCOON_SPAWN";

void Spiders_PreloadSpider(string sSubsystemScript);
void Spiders_SpawnCocoons(string sSubsystemScript);

// @Load
void Spiders_Load(string sSubsystemScript)
{
    Events_SubscribeEvent_Object(sSubsystemScript, EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER, EVENTS_EVENT_FLAG_DEFAULT, TRUE);

    Spiders_PreloadSpider(sSubsystemScript);
    Spiders_SpawnCocoons(sSubsystemScript);
}

void Spider_DestroySelf(object oSpider)
{
    DestroyObject(oSpider);
}

location GetRandomLocationAroundPoint(location locPoint, float fDistance)
{
    float fAngle = IntToFloat(Random(360));
    float fOrient = IntToFloat(Random(360));

    return GenerateNewLocationFromLocation(locPoint, fDistance, fAngle, fOrient);
}

// @EventHandler
void Spiders_EventHandler(string sSubsystemScript, string sEvent)
{
    switch (StringToInt(sEvent))
    {
        case EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER:
        {
            object oTrigger = OBJECT_SELF;
            object oPlayer = GetEnteringObject();

            // We don't want infinite spiders...
            if (!GetIsPC(oPlayer)) return;

            object oDataObject = ES_Util_GetDataObject(sSubsystemScript);
            object oCocoon = GetLocalObject(oTrigger, "SPIDERS_COCOON");
            object oCocoonArea = GetArea(oCocoon);
            location locCocoon = GetLocation(oTrigger);

            string sSpider = GetLocalString(oDataObject, "SPIDER_TEMPLATE");

            SendMessageToPC(oPlayer, "Oh no, spiderlings!");

            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_GAS_EXPLOSION_ACID), oCocoon);

            effect eFear = EffectLinkEffects(EffectVisualEffect(VFX_DUR_MIND_AFFECTING_FEAR), EffectFrightened());
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFear, oPlayer, 7.5f);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectCutsceneGhost(), oPlayer, 7.5f);

            int nSpider, nNumSpiders = 25;
            for(nSpider = 0; nSpider < nNumSpiders; nSpider++)
            {
                object oSpider = NWNX_Object_Deserialize(sSpider);

                SetObjectVisualTransform(oSpider, OBJECT_VISUAL_TRANSFORM_SCALE, 0.25f + (IntToFloat(Random(25)) / 100.0f));

                location locSpawn = GetRandomLocationAroundPoint(locCocoon, 5.0f);
                NWNX_Object_AddToArea(oSpider, oCocoonArea, GetPositionFromLocation(locSpawn));

                location locMove = GetRandomLocationAroundPoint(locCocoon, 30.0f);

                AssignCommand(oSpider, ActionWait(0.25f));
                AssignCommand(oSpider, JumpToLocation(locSpawn));
                AssignCommand(oSpider, ActionForceMoveToLocation(locMove, TRUE, 15.0f));
                AssignCommand(oSpider, ActionDoCommand(Spider_DestroySelf(oSpider)));
            }

            break;
        }
    }
}

void Spiders_SpawnCocoons(string sSubsystemScript)
{
    struct Toolbox_CircleTriggerData ctd;
    ctd.sTag = "SPIDERS_TRIGGER";
    ctd.fRadius = 2.5f;
    ctd.nPoints = 16;
    ctd.scriptOnEnter = TRUE;

    struct Toolbox_PlaceableData pd;
    pd.nModel = 90;
    pd.sTag = "SPIDERS_COCOON";
    pd.sName = "Cocoon";
    pd.sDescription = "A cocoon filled with icky spiders.";
    pd.bPlot = TRUE;

    string sSerializedCocoon = Toolbox_GeneratePlaceable(pd);
    string sTriggerOnEnter = Events_GetEventName_Object(EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER);

    int nNth = 0;
    object oSpawnpoint;
    while ((oSpawnpoint = GetObjectByTag(SPIDERS_COCOON_WAYPOINT_TAG, nNth++)) != OBJECT_INVALID)
    {
        location locSpawn = GetLocation(oSpawnpoint);
        object oTrigger = Toolbox_CreateCircleTrigger(ctd, locSpawn);

        vector vSpawnpoint = GetPosition(oSpawnpoint);
        vSpawnpoint.z -= 0.15;
        location locCocoon = Location(GetArea(oSpawnpoint), vSpawnpoint, GetFacing(oSpawnpoint));

        object oCocoon = Toolbox_CreatePlaceable(sSerializedCocoon, locCocoon);

        SetLocalObject(oTrigger, GetTag(oCocoon), oCocoon);
        SetLocalObject(oCocoon, GetTag(oTrigger), oTrigger);

        Events_AddObjectToDispatchList(sSubsystemScript, sTriggerOnEnter, oTrigger);
    }
}

void Spiders_PreloadSpider(string sSubsystemScript)
{
    object oSpider = CreateObject(OBJECT_TYPE_CREATURE, "nw_spidgiant", GetStartingLocation(), FALSE, "SPIDERS_SPIDER");

    Events_ClearCreatureEventScripts(oSpider);

    SetName(oSpider, "Spiderling");

    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneGhost(), oSpider);

    string sSpider = NWNX_Object_Serialize(oSpider);
    SetLocalString(ES_Util_GetDataObject(sSubsystemScript), "SPIDER_TEMPLATE", sSpider);

    DestroyObject(oSpider);
}

