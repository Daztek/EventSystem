/*
    ScriptName: es_s_webhook.nss
    Created by: Daz

    Description: A Webhook Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_webhook"

const string WEBHOOK_SYSTEM_TAG     = "Webhook";
const string WEBHOOK_API_URL_PLAYER = "ES_WEBHOOK_API_URL_PLAYER";
const string WEBHOOK_API_URL_ADMIN  = "ES_WEBHOOK_API_URL_ADMIN";

// Send a webhook message to a channel
// sChannel: WEBHOOK_API_URL_*
void Webhook_SendMessage(string sChannel, string sMessage, string sUserName = "");

// @EventSystem_Init
void Webhook_Init(string sSubsystemScript)
{
    object oModule = GetModule();
    int bPlayerWebhook = ES_Util_ExecuteScriptChunkAndReturnInt(sSubsystemScript,
        nssFunction("Webhook_CheckAPIUrl", nssEscapeDoubleQuotes(WEBHOOK_API_URL_PLAYER)), oModule);
    int bAdminWebhook = ES_Util_ExecuteScriptChunkAndReturnInt(sSubsystemScript,
        nssFunction("Webhook_CheckAPIUrl", nssEscapeDoubleQuotes(WEBHOOK_API_URL_ADMIN)), oModule);

    if (bPlayerWebhook || bAdminWebhook)
        ES_Core_SubscribeEvent_NWNX(sSubsystemScript, "NWNX_ON_WEBHOOK_FAILURE");

    Webhook_SendMessage(WEBHOOK_API_URL_PLAYER, "Test Message");
}

// @EventSystem_EventHandler
void Webhook_EventHandler(string sSubsystemScript, string sEvent)
{
    if (sEvent == "NWNX_ON_WEBHOOK_FAILURE")
    {
        int nStatus = ES_Core_GetEventData_NWNX_Int("STATUS");

        if (nStatus == 429)
        {// Rate limited
            float fResendDelay = ES_Core_GetEventData_NWNX_Float("RETRY_AFTER") / 1000.0f;
            string sMessage = ES_Core_GetEventData_NWNX_String("MESSAGE");
            string sHost = ES_Core_GetEventData_NWNX_String("HOST");
            string sPath = ES_Core_GetEventData_NWNX_String("PATH");

            ES_Util_Log(WEBHOOK_SYSTEM_TAG, "WARNING: Webhook rate limited, resending in " + FloatToString(fResendDelay) + " seconds.");

            NWNX_WebHook_ResendWebHookHTTPS(sHost, sPath, sMessage, fResendDelay);
        }
    }
}

int Webhook_CheckAPIUrl(string sChannel)
{
    object oDataObject = ES_Util_GetDataObject(WEBHOOK_SYSTEM_TAG);

    string sPlayerWebhookUrl = NWNX_Util_GetEnvironmentVariable(sChannel);
    if (sPlayerWebhookUrl != "")
    {
        ES_Util_SetString(oDataObject, sChannel, sPlayerWebhookUrl);
    }
    else
        ES_Util_Log(WEBHOOK_SYSTEM_TAG, "WARNING: API URL for '" + sChannel + "' is not set");

    return sPlayerWebhookUrl != "";
}

void Webhook_SendMessage(string sChannel, string sMessage, string sUserName = "")
{
    string sWebhookUrl = ES_Util_GetString(ES_Util_GetDataObject(WEBHOOK_SYSTEM_TAG), sChannel);

    if (sWebhookUrl != "")
        NWNX_WebHook_SendWebHookHTTPS("discordapp.com", sWebhookUrl, sMessage, sUserName);
    else
        ES_Util_Log(WEBHOOK_SYSTEM_TAG, "WARNING: Tried to send '" + sChannel + "' webhook message but no webhook API url is set");
}

