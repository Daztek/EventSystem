/*
    ScriptName: es_inc_test.nss
    Created by: Daz

    Description: Event System Test Include
*/

#include "es_inc_util"

const string TEST_SCRIPT_NAME = "es_inc_test";

void Test_Assert(string sTestName, int bTestResult);
void Test_Warn(string sTestName, int bTestResult);

int Test_ExecuteTestFunction(string sComponent, string sFunctionName)
{
    int bReturn;
    string sError = ES_Util_ExecuteScriptChunk(sComponent, nssFunction(sFunctionName, nssEscapeDoubleQuotes(sComponent)), GetModule());

    if (sError != "")
    {
        ES_Util_Log("Test", "    > WARNING: Failed to run tests with error: " + sError);
        bReturn = FALSE;
    }
    else
    {
        object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
        int nTotal = GetLocalInt(oDataObject, "NumberOfTests");
        int nFailed = GetLocalInt(oDataObject, "Failures");
        int nWarn = GetLocalInt(oDataObject, "Warnings");
        int nPassed = nTotal - nFailed - nWarn;

        ES_Util_Log("Test", "    * RESULT: Total: " + IntToString(nTotal) + " -> " +
                                                      IntToString(nPassed) + " Passed | " +
                                                      IntToString(nFailed) + " Failed | " +
                                                      IntToString(nWarn) + (nWarn == 1 ? " Warning" : " Warnings"));

        DeleteLocalInt(oDataObject, "NumberOfTests");
        DeleteLocalInt(oDataObject, "Failures");
        DeleteLocalInt(oDataObject, "Warnings");

        bReturn = !nFailed;
    }

    return bReturn;
}

void Test_Assert(string sTestName, int bTestResult)
{
    object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
    int nCurrentTest = GetLocalInt(oDataObject, "NumberOfTests") + 1;

    ES_Util_Log("Test", "      [" + IntToString(nCurrentTest) + "] " + sTestName + " -> " + (bTestResult ? "PASS" : "FAIL"));

    if (!bTestResult)
        SetLocalInt(oDataObject, "Failures", GetLocalInt(oDataObject, "Failures") + 1);

    SetLocalInt(oDataObject, "NumberOfTests", nCurrentTest);
}

void Test_Warn(string sTestName, int bTestResult)
{
    object oDataObject = ES_Util_GetDataObject(TEST_SCRIPT_NAME);
    int nCurrentTest = GetLocalInt(oDataObject, "NumberOfTests") + 1;

    ES_Util_Log("Test", "      [" + IntToString(nCurrentTest) + "] " + sTestName + " -> " + (bTestResult ? "PASS" : "FAIL (WARNING)"));

    if (!bTestResult)
        SetLocalInt(oDataObject, "Warnings", GetLocalInt(oDataObject, "Warnings") + 1);

    SetLocalInt(oDataObject, "NumberOfTests", nCurrentTest);
}

