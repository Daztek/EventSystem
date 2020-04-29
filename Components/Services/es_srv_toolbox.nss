/*
    ScriptName: es_srv_toolbox.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Area Object]

    Description: An EventSystem Service that allows you to create small items
                 and placeables on the fly.
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_area"
#include "nwnx_object"

const string TOOLBOX_LOG_TAG                            = "Toolbox";
const string TOOLBOX_SCRIPT_NAME                        = "es_srv_toolbox";

const string TOOLBOX_TEMPLATE_SMALL_ITEM_TAG            = "ToolboxSmallItem";
const string TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG      = "ToolboxPlaceable_Normal";
const string TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG   = "ToolboxPlaceable_Inventory";

// Creates and returns a small Item with a single itemproperty
object Toolbox_CreateSmallItem(struct Toolbox_SmallItemData sid);
// Generates a serialized placeable template
string Toolbox_GeneratePlaceable(struct Toolbox_PlaceableData pd);
// Create a new placeable from template string
object Toolbox_CreatePlaceable(string sPlaceable, location locLocation, string sNewTag = "");
// Create a new trigger in the shape of a circle
object Toolbox_CreateCircleTrigger(struct Toolbox_CircleTriggerData ctd, location locLocation);

struct Toolbox_SmallItemData
{
    int nIcon;
    string sName;
    string sTag;
    string sDescription;

    int bPlot;
    int bCursed;
    int bDroppable;
    int bPickpocketable;
    int bStolen;

    itemproperty ipProperty;
};

struct Toolbox_PlaceableData
{
    int nModel;
    string sTag;
    string sName;
    string sDescription;

    int bHasInventory;
    int bPlot;
    int bUseable;

    float fFacingAdjustment;

    int scriptOnClick;
    int scriptOnClose;
    int scriptOnDamaged;
    int scriptOnDeath;
    int scriptOnHeartbeat;
    int scriptOnDisturbed;
    int scriptOnLock;
    int scriptOnPhysicalAttacked;
    int scriptOnOpen;
    int scriptOnSpellCastAt;
    int scriptOnUnlock;
    int scriptOnUsed;
    int scriptOnUserDefined;
    int scriptOnDialog;
    int scriptOnDisarm;
    int scriptOnTrapTriggered;
};

struct Toolbox_CircleTriggerData
{
    string sTag;
    string sName;

    float fRadius;
    int nPoints;

    int bUseSpawnZ;

    int scriptOnClick;
    int scriptOnEnter;
    int scriptOnExit;
    int scriptOnHearbeat;
    int scriptOnUserDefined;
};

// @Load
void Toolbox_Load(string sServiceScript)
{
    ES_Util_Log(TOOLBOX_LOG_TAG, "* Generating Small Item Template");

        object oSmallItem = CreateObject(OBJECT_TYPE_ITEM, "nw_it_msmlmisc22", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_SMALL_ITEM_TAG);

        SetName(oSmallItem, "Item Template, Small");
        SetDescription(oSmallItem, "Item Template, Small");

        string sSmallItem = NWNX_Object_Serialize(oSmallItem);
        SetLocalString(ES_Util_GetDataObject(sServiceScript), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG, sSmallItem);

        object oTemplateSmallItem = NWNX_Object_Deserialize(sSmallItem);
        SetLocalObject(ES_Util_GetDataObject(sServiceScript), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG, oTemplateSmallItem);

        DestroyObject(oSmallItem);

    ES_Util_Log(TOOLBOX_LOG_TAG, "* Generating Placeable Templates");

        object oNormalPlaceable = CreateObject(OBJECT_TYPE_PLACEABLE, "plc_invisobj", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG);
        SetName(oNormalPlaceable, "Placeable Template, Normal");
        NWNX_Object_SetPlaceableIsStatic(oNormalPlaceable, FALSE);
        string sNormalPlaceable = NWNX_Object_Serialize(oNormalPlaceable);
        SetLocalString(ES_Util_GetDataObject(sServiceScript), TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG, sNormalPlaceable);

        object oInventoryPlaceable = CreateObject(OBJECT_TYPE_PLACEABLE, "x1_hen_inv", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG);
        SetName(oInventoryPlaceable, "Placeable Template, Inventory");
        SetEventScript(oInventoryPlaceable, EVENT_SCRIPT_PLACEABLE_ON_CLOSED, "");
        string sInventoryPlaceable = NWNX_Object_Serialize(oInventoryPlaceable);
        SetLocalString(ES_Util_GetDataObject(sServiceScript), TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG, sInventoryPlaceable);

        DestroyObject(oNormalPlaceable);
        DestroyObject(oInventoryPlaceable);
}

object Toolbox_CreateSmallItem(struct Toolbox_SmallItemData sid)
{
    object oTemplateItem = GetLocalObject(ES_Util_GetDataObject(TOOLBOX_SCRIPT_NAME), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG);
    object oSmallItem = CopyItemAndModify(oTemplateItem, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, sid.nIcon, TRUE);

    SetName(oSmallItem, sid.sName);
    SetDescription(oSmallItem, sid.sDescription);
    SetTag(oSmallItem, sid.sTag);

    if (sid.bPlot)              SetPlotFlag(oSmallItem, sid.bPlot);
    if (sid.bDroppable)         SetDroppableFlag(oSmallItem, sid.bDroppable);
    if (sid.bCursed)            SetItemCursedFlag(oSmallItem, sid.bCursed);
    if (sid.bPickpocketable)    SetPickpocketableFlag(oSmallItem, sid.bPickpocketable);
    if (sid.bStolen)            SetStolenFlag(oSmallItem, sid.bStolen);

    if (GetIsItemPropertyValid(sid.ipProperty))
        AddItemProperty(DURATION_TYPE_PERMANENT, sid.ipProperty, oSmallItem);

    return oSmallItem;
}

string Toolbox_GeneratePlaceable(struct Toolbox_PlaceableData pd)
{
    object oPlaceable = NWNX_Object_Deserialize(GetLocalString(
        ES_Util_GetDataObject(TOOLBOX_SCRIPT_NAME), pd.bHasInventory ? TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG : TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG));

    NWNX_Object_SetAppearance(oPlaceable, pd.nModel);

    string sModelName = Get2DAString("placeables", "ModelName", pd.nModel);
    if (sModelName != "")
        SetPortraitResRef(oPlaceable, "po_" + GetStringLowerCase(sModelName) + "_");

    SetName(oPlaceable, pd.sName);
    SetDescription(oPlaceable, pd.sDescription);
    SetTag(oPlaceable, pd.sTag);

    SetLocalFloat(oPlaceable, "ToolboxFacingAdjustment", pd.fFacingAdjustment);

    if (pd.bPlot)       SetPlotFlag(oPlaceable, pd.bPlot);
    if (pd.bUseable)    SetUseableFlag(oPlaceable, pd.bUseable);

    if (pd.scriptOnClick)               Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK, FALSE);
    if (pd.scriptOnClose)               Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_CLOSED, FALSE);
    if (pd.scriptOnDamaged)             Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DAMAGED, FALSE);
    if (pd.scriptOnDeath)               Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DEATH, FALSE);
    if (pd.scriptOnHeartbeat)           Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_HEARTBEAT, FALSE);
    if (pd.scriptOnDisturbed)           Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_INVENTORYDISTURBED, FALSE);
    if (pd.scriptOnLock)                Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_LOCK, FALSE);
    if (pd.scriptOnPhysicalAttacked)    Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_MELEEATTACKED, FALSE);
    if (pd.scriptOnOpen)                Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_OPEN, FALSE);
    if (pd.scriptOnSpellCastAt)         Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_SPELLCASTAT, FALSE);
    if (pd.scriptOnUnlock)              Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_UNLOCK, FALSE);
    if (pd.scriptOnUsed)                Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_USED, FALSE);
    if (pd.scriptOnUserDefined)         Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_USER_DEFINED_EVENT, FALSE);
    if (pd.scriptOnDialog)              Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DIALOGUE, FALSE);
    if (pd.scriptOnDisarm)              Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DISARM, FALSE);
    if (pd.scriptOnTrapTriggered)       Events_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_TRAPTRIGGERED, FALSE);

    DestroyObject(oPlaceable);

    return NWNX_Object_Serialize(oPlaceable);
}

object Toolbox_CreatePlaceable(string sPlaceable, location locLocation, string sNewTag = "")
{
    object oPlaceable = NWNX_Object_Deserialize(sPlaceable);

    if (sNewTag != "")
        SetTag(oPlaceable, sNewTag);

    NWNX_Object_AddToArea(oPlaceable, GetAreaFromLocation(locLocation), GetPositionFromLocation(locLocation));

    float fFacingAdjustment = GetLocalFloat(oPlaceable, "ToolboxFacingAdjustment");
    float fFacing = GetFacingFromLocation(locLocation) + fFacingAdjustment;

    NWNX_Object_SetFacing(oPlaceable, fFacing);
    DeleteLocalFloat(oPlaceable, "ToolboxFacingAdjustment");

    return oPlaceable;
}

object Toolbox_CreateCircleTrigger(struct Toolbox_CircleTriggerData ctd, location locLocation)
{
    object oArea = GetAreaFromLocation(locLocation);
    vector vPosition = GetPositionFromLocation(locLocation);

    object oTrigger = NWNX_Area_CreateGenericTrigger(oArea, vPosition.x, vPosition.y, vPosition.z, ctd.sTag);

    if (ctd.sName != "") SetName(oTrigger, ctd.sName);

    ctd.nPoints = abs(ctd.nPoints);
    ctd.fRadius = fabs(ctd.fRadius);
    if (ctd.nPoints < 3) ctd.nPoints = 3;
    if (ctd.fRadius == 0.0f) ctd.fRadius = 1.0f;

    float fAngleIncrement = 360.0f / ctd.nPoints;
    string sGeometry;

    int i;
    for (i = 0; i < ctd.nPoints; i++)
    {
        float fAngle = fAngleIncrement * i;
        float x = (ctd.fRadius * cos(fAngle)) + vPosition.x;
        float y = (ctd.fRadius * sin(fAngle)) + vPosition.y;

        sGeometry += "{" + FloatToString(x) + ", " + FloatToString(y) + (ctd.bUseSpawnZ ? ", " + FloatToString(vPosition.z) + "}" : "}");
    }

    NWNX_Object_SetTriggerGeometry(oTrigger, sGeometry);

    if (ctd.scriptOnClick)          Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_CLICKED, FALSE);
    if (ctd.scriptOnEnter)          Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_OBJECT_ENTER, FALSE);
    if (ctd.scriptOnExit)           Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_OBJECT_EXIT, FALSE);
    if (ctd.scriptOnHearbeat)       Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_HEARTBEAT, FALSE);
    if (ctd.scriptOnUserDefined)    Events_SetObjectEventScript(oTrigger, EVENT_SCRIPT_TRIGGER_ON_USER_DEFINED_EVENT, FALSE);

    return oTrigger;
}

