/*
    ScriptName: es_inc_test.nss
    Created by: Daz

    Description: Event System Test Include
*/

#include "es_inc_util"

const string TEST_SCRIPT_NAME = "es_inc_test";

int Test_Assert(string sTestName, int bAssert);

int Test_ExecuteTestFunction(string sComponent, string sFunction)
{
    object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);

    SetLocalString(oDataObject, "CurrentTestComponent", sComponent);

    int bResult = ES_Util_ExecuteScriptChunkAndReturnInt(sComponent, nssFunction(sFunction, nssEscapeDoubleQuotes(sComponent)), GetModule());

    int nTotal = GetLocalInt(oDataObject, "NumTests");
    int nFailed = GetLocalInt(oDataObject, "FailedTests");
    int nPassed = nTotal - nFailed;

    ES_Util_Log("Test", "    * RESULT: Total: " + IntToString(nTotal) + " -> " + IntToString(nPassed) + " Passed | " + IntToString(nFailed) + " Failed");

    DeleteLocalString(oDataObject, "CurrentTestComponent");
    DeleteLocalInt(oDataObject, "NumTests");
    DeleteLocalInt(oDataObject, "FailedTests");

    return bResult;
}

int Test_Assert(string sTestName, int bAssert)
{
    object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
    string sCurrentTestComponent = GetLocalString(oDataObject, "CurrentTestComponent");
    int nCurrentTest = GetLocalInt(oDataObject, "NumTests") + 1;

    ES_Util_Log("Test", "      [" + IntToString(nCurrentTest) + "] " + sTestName + " -> " + (bAssert ? "PASS" : "FAIL"));

    if (!bAssert)
        SetLocalInt(oDataObject, "FailedTests", GetLocalInt(oDataObject, "FailedTests") + 1);

    SetLocalInt(oDataObject, "NumTests", nCurrentTest);

    return bAssert;
}

