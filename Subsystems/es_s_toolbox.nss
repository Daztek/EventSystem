/*
    ScriptName: es_s_toolbox.nss
    Created by: Daz

    Description: An EventSystem subsystem that allows you to create small items
                 and placeables on the fly.
*/

//void main() {}

#include "es_inc_core"

const string TOOLBOX_SYSTEM_TAG                         = "Toolbox";

const string TOOLBOX_TEMPLATE_SMALL_ITEM_TAG            = "ToolboxSmallItem";
const string TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG      = "ToolboxPlaceable_Normal";
const string TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG   = "ToolboxPlaceable_Inventory";

// Creates and returns a small Item with a single itemproperty
object Toolbox_CreateSmallItem(struct Toolbox_SmallItemData sid);
// Generates a serialized placeable template
string Toolbox_GeneratePlaceable(struct Toolbox_PlaceableData pd);
// Create a new placeable from template string
object Toolbox_CreatePlaceable(string sPlaceable, location locLocation, string sNewTag = "");

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

// @EventSystem_Init
void Toolbox_Init(string sEventHandlerScript)
{
    ES_Util_Log(TOOLBOX_SYSTEM_TAG, "* Generating Small Item Template");

        object oSmallItem = CreateObject(OBJECT_TYPE_ITEM, "nw_it_msmlmisc22", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_SMALL_ITEM_TAG);

        SetName(oSmallItem, "Item Template, Small");
        SetDescription(oSmallItem, "Item Template, Small");

        string sSmallItem = NWNX_Object_Serialize(oSmallItem);
        SetLocalString(ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG, sSmallItem);

        object oTemplateSmallItem = NWNX_Object_Deserialize(sSmallItem);
        SetLocalObject(ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG, oTemplateSmallItem);

        DestroyObject(oSmallItem);

    ES_Util_Log(TOOLBOX_SYSTEM_TAG, "* Generating Placeable Templates");

        object oNormalPlaceable = CreateObject(OBJECT_TYPE_PLACEABLE, "plc_invisobj", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG);
        SetName(oNormalPlaceable, "Placeable Template, Normal");
        NWNX_Object_SetPlaceableIsStatic(oNormalPlaceable, FALSE);
        string sNormalPlaceable = NWNX_Object_Serialize(oNormalPlaceable);
        SetLocalString(ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG, sNormalPlaceable);

        object oInventoryPlaceable = CreateObject(OBJECT_TYPE_PLACEABLE, "x1_hen_inv", GetStartingLocation(), FALSE, TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG);
        SetName(oInventoryPlaceable, "Placeable Template, Inventory");
        SetEventScript(oInventoryPlaceable, EVENT_SCRIPT_PLACEABLE_ON_CLOSED, "");
        string sInventoryPlaceable = NWNX_Object_Serialize(oInventoryPlaceable);
        SetLocalString(ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG, sInventoryPlaceable);

        DestroyObject(oNormalPlaceable);
        DestroyObject(oInventoryPlaceable);

}

object Toolbox_CreateSmallItem(struct Toolbox_SmallItemData sid)
{
    object oTemplateItem = GetLocalObject(ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), TOOLBOX_TEMPLATE_SMALL_ITEM_TAG);
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
        ES_Util_GetDataObject(TOOLBOX_SYSTEM_TAG), pd.bHasInventory ? TOOLBOX_TEMPLATE_PLACEABLE_INVENTORY_TAG : TOOLBOX_TEMPLATE_PLACEABLE_NORMAL_TAG));

    NWNX_Object_SetAppearance(oPlaceable, pd.nModel);

    string sModelName = Get2DAString("placeables", "ModelName", pd.nModel);
    if (sModelName != "")
        SetPortraitResRef(oPlaceable, "po_" + GetStringLowerCase(sModelName) + "_");

    SetName(oPlaceable, pd.sName);
    SetDescription(oPlaceable, pd.sDescription);
    SetTag(oPlaceable, pd.sTag);

    if (pd.bPlot)       SetPlotFlag(oPlaceable, pd.bPlot);
    if (pd.bUseable)    SetUseableFlag(oPlaceable, pd.bUseable);

    if (pd.scriptOnClick)               ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_LEFT_CLICK, FALSE);
    if (pd.scriptOnClose)               ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_CLOSED, FALSE);
    if (pd.scriptOnDamaged)             ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DAMAGED, FALSE);
    if (pd.scriptOnDeath)               ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DEATH, FALSE);
    if (pd.scriptOnHeartbeat)           ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_HEARTBEAT, FALSE);
    if (pd.scriptOnDisturbed)           ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_INVENTORYDISTURBED, FALSE);
    if (pd.scriptOnLock)                ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_LOCK, FALSE);
    if (pd.scriptOnPhysicalAttacked)    ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_MELEEATTACKED, FALSE);
    if (pd.scriptOnOpen)                ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_OPEN, FALSE);
    if (pd.scriptOnSpellCastAt)         ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_SPELLCASTAT, FALSE);
    if (pd.scriptOnUnlock)              ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_UNLOCK, FALSE);
    if (pd.scriptOnUsed)                ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_USED, FALSE);
    if (pd.scriptOnUserDefined)         ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_USER_DEFINED_EVENT, FALSE);
    if (pd.scriptOnDialog)              ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DIALOGUE, FALSE);
    if (pd.scriptOnDisarm)              ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_DISARM, FALSE);
    if (pd.scriptOnTrapTriggered)       ES_Core_SetObjectEventScript(oPlaceable, EVENT_SCRIPT_PLACEABLE_ON_TRAPTRIGGERED, FALSE);

    DestroyObject(oPlaceable);

    return NWNX_Object_Serialize(oPlaceable);
}

object Toolbox_CreatePlaceable(string sPlaceable, location locLocation, string sNewTag = "")
{
    object oPlaceable = NWNX_Object_Deserialize(sPlaceable);

    if (sNewTag != "")
        SetTag(oPlaceable, sNewTag);

    AssignCommand(oPlaceable, SetFacing(GetFacingFromLocation(locLocation)));

    NWNX_Object_AddToArea(oPlaceable, GetAreaFromLocation(locLocation), GetPositionFromLocation(locLocation));

    return oPlaceable;
}

