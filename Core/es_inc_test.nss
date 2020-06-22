/*
    ScriptName: es_inc_test.nss
    Created by: Daz

    Description: Event System Test Include
*/

#include "es_inc_util"

const string TEST_SCRIPT_NAME = "es_inc_test";

void Test_Assert(string sTestName, int bAssert);

int Test_ExecuteTestFunction(string sComponent, string sFunction)
{
    int bReturn;
    string sResult = ES_Util_ExecuteScriptChunk(sComponent, nssFunction(sFunction, nssEscapeDoubleQuotes(sComponent)), GetModule());

    if (sResult != "")
    {
        ES_Util_Log("Test", "    > WARNING: Failed to run tests with error: " + sResult);
        bReturn = FALSE;
    }
    else
    {
        object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
        int nTotal = GetLocalInt(oDataObject, "NumTests");
        int nFailed = GetLocalInt(oDataObject, "FailedTests");
        int nPassed = nTotal - nFailed;

        ES_Util_Log("Test", "    * RESULT: Total: " + IntToString(nTotal) + " -> " + IntToString(nPassed) + " Passed | " + IntToString(nFailed) + " Failed");

        DeleteLocalInt(oDataObject, "NumTests");
        DeleteLocalInt(oDataObject, "FailedTests");

        bReturn = !nFailed;
    }

    return bReturn;
}

void Test_Assert(string sTestName, int bAssert)
{
    object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
    int nCurrentTest = GetLocalInt(oDataObject, "NumTests") + 1;

    ES_Util_Log("Test", "      [" + IntToString(nCurrentTest) + "] " + sTestName + " -> " + (bAssert ? "PASS" : "FAIL"));

    if (!bAssert)
        SetLocalInt(oDataObject, "FailedTests", GetLocalInt(oDataObject, "FailedTests") + 1);

    SetLocalInt(oDataObject, "NumTests", nCurrentTest);
}

