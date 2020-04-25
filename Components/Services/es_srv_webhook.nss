/*
    ScriptName: es_srv_webhook.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[WebHook]

    Description: An EventSystem Service that allows sending of webhook messages
*/

//void main() {}

#include "es_inc_core"
#include "es_cc_events"
#include "nwnx_webhook"

const string WEBHOOK_LOG_TAG        = "Webhook";
const string WEBHOOK_SCRIPT_NAME    = "es_srv_webhook";

const string WEBHOOK_CHANNEL_PLAYER = "ES_WEBHOOK_API_URL_PLAYER";
const string WEBHOOK_CHANNEL_ADMIN  = "ES_WEBHOOK_API_URL_ADMIN";

// Send a webhook message to a channel
// sChannel: WEBHOOK_CHANNEL_*
void Webhook_SendMessage(string sChannel, string sMessage, string sUserName = "");

// @Load
void Webhook_Load(string sServiceScript)
{
    object oModule = GetModule();
    int bPlayerWebhook = ES_Util_ExecuteScriptChunkAndReturnInt(sServiceScript,
        nssFunction("Webhook_CheckAPIUrl", nssEscapeDoubleQuotes(WEBHOOK_CHANNEL_PLAYER)), oModule);
    int bAdminWebhook = ES_Util_ExecuteScriptChunkAndReturnInt(sServiceScript,
        nssFunction("Webhook_CheckAPIUrl", nssEscapeDoubleQuotes(WEBHOOK_CHANNEL_ADMIN)), oModule);

    if (bPlayerWebhook || bAdminWebhook)
        Events_SubscribeEvent_NWNX(sServiceScript, "NWNX_ON_WEBHOOK_FAILURE");
}

// @EventHandler
void Webhook_EventHandler(string sServiceScript, string sEvent)
{
    if (sEvent == "NWNX_ON_WEBHOOK_FAILURE")
    {
        int nStatus = Events_GetEventData_NWNX_Int("STATUS");

        if (nStatus == 429)
        {// Rate limited
            float fResendDelay = Events_GetEventData_NWNX_Float("RETRY_AFTER") / 1000.0f;
            string sMessage = Events_GetEventData_NWNX_String("MESSAGE");
            string sHost = Events_GetEventData_NWNX_String("HOST");
            string sPath = Events_GetEventData_NWNX_String("PATH");

            ES_Util_Log(WEBHOOK_LOG_TAG, "WARNING: Webhook rate limited, resending in " + FloatToString(fResendDelay) + " seconds.");

            NWNX_WebHook_ResendWebHookHTTPS(sHost, sPath, sMessage, fResendDelay);
        }
    }
}

int Webhook_CheckAPIUrl(string sChannel)
{
    object oDataObject = ES_Util_GetDataObject(WEBHOOK_SCRIPT_NAME);

    string sWebhookUrl = NWNX_Util_GetEnvironmentVariable(sChannel);

    if (sWebhookUrl != "")
        SetLocalString(oDataObject, sChannel, sWebhookUrl);
    else
        ES_Util_Log(WEBHOOK_LOG_TAG, "WARNING: API URL for '" + sChannel + "' is not set");

    return sWebhookUrl != "";
}

void Webhook_SendMessage(string sChannel, string sMessage, string sUserName = "")
{
    string sWebhookUrl = GetLocalString(ES_Util_GetDataObject(WEBHOOK_SCRIPT_NAME), sChannel);

    if (sWebhookUrl != "")
        NWNX_WebHook_SendWebHookHTTPS("discordapp.com", sWebhookUrl, sMessage, sUserName);
    else
        ES_Util_Log(WEBHOOK_LOG_TAG, "WARNING: Tried to send '" + sChannel + "' webhook message but no webhook API url is set");
}

