/*
    ScriptName: es_cc_profiler.nss
    Created by: Daz

    Required NWNX Plugins:
        @NWNX[Time]

    Description: An EventSystem Core Component that adds a Script Profiler
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_time"

const string PROFILER_LOG_TAG                           = "Profiler";
const string PROFILER_SCRIPT_NAME                       = "es_cc_profiler";

const int PROFILER_OVERHEAD_COMPENSATION_ITERATIONS     = 1000;

struct ProfilerData
{
    string sName;
    int bEnableStats;
    int bSkipLog;
    int nSeconds;
    int nMicroseconds;
};

struct ProfilerStats
{
    string sName;
    int nSum;
    int nCount;
    int nMin;
    int nMax;
    int nAvg;
};

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = TRUE);
int Profiler_Stop(struct ProfilerData startData);
int Profiler_GetOverheadCompensation();
void Profiler_SetOverheadCompensation(int nOverhead);
int Profiler_Calibrate(int nIterations);
struct ProfilerStats Profiler_GetStats(string sName);
void Profiler_DeleteStats(string sName);
string nssProfiler(string sName, string sContents, int bSkipLog = FALSE, int bEnableStats = TRUE);

// @Load
void Profiler_Load(string sCoreComponentScript)
{
    int nOverhead = Profiler_Calibrate(PROFILER_OVERHEAD_COMPENSATION_ITERATIONS);

    ES_Util_Log(PROFILER_LOG_TAG, "* Overhead Compensation: " + IntToString(nOverhead) + "us");
    Profiler_SetOverheadCompensation(nOverhead);
}

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = TRUE)
{
    struct ProfilerData pd;
    pd.sName = sName;
    pd.bEnableStats = bEnableStats;
    pd.bSkipLog = bSkipLog;

    struct NWNX_Time_HighResTimestamp ts = NWNX_Time_GetHighResTimeStamp();
    pd.nSeconds = ts.seconds;
    pd.nMicroseconds = ts.microseconds;

    return pd;
}

int Profiler_Stop(struct ProfilerData startData)
{
    struct NWNX_Time_HighResTimestamp endTimestamp = NWNX_Time_GetHighResTimeStamp();
    int nTotalSeconds = endTimestamp.seconds - startData.nSeconds;
    int nTotalMicroSeconds = endTimestamp.microseconds - startData.nMicroseconds - Profiler_GetOverheadCompensation();

    if (nTotalMicroSeconds < 0)
    {
        nTotalMicroSeconds = 1000000 + nTotalMicroSeconds;
        nTotalSeconds--;
    }

    string sStats;
    if (startData.bEnableStats)
    {
        object oDataObject = ES_Util_GetDataObject(PROFILER_SCRIPT_NAME + "!" + startData.sName);
        int nMin, nMax, nCount = GetLocalInt(oDataObject, "PROFILER_COUNT") + 1;
        SetLocalInt(oDataObject, "PROFILER_COUNT", nCount);

        if (nCount == 1)
        {
            nMin = nTotalMicroSeconds;
            nMax = nTotalMicroSeconds;

            SetLocalInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            SetLocalInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
        }
        else
        {
            nMin = GetLocalInt(oDataObject, "PROFILER_MIN");
            if (nTotalMicroSeconds < nMin)
            {
                nMin = nTotalMicroSeconds;
                SetLocalInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            }

            nMax = GetLocalInt(oDataObject, "PROFILER_MAX");
            if (nTotalMicroSeconds > nMax)
            {
                nMax = nTotalMicroSeconds;
                SetLocalInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
            }
        }

        int nSum = GetLocalInt(oDataObject, "PROFILER_SUM") + nTotalMicroSeconds;
        SetLocalInt(oDataObject, "PROFILER_SUM", nSum);

        sStats = " (MIN: " + IntToString(nMin) + "us, MAX: " + IntToString(nMax) + "us, AVG: " + IntToString((nSum / nCount)) + "us)";
    }

    if (!startData.bSkipLog)
    {
        int nLength = GetStringLength(IntToString(nTotalMicroSeconds));

        string sZeroPadding;
        while (nLength < 6)
        {
            sZeroPadding += "0";
            nLength++;
        }

        ES_Util_Log(PROFILER_LOG_TAG, "[" + startData.sName + "] " + IntToString(nTotalSeconds) + "." + sZeroPadding + IntToString(nTotalMicroSeconds) + " seconds" + sStats);
    }

    return nTotalMicroSeconds;
}

int Profiler_GetOverheadCompensation()
{
    return GetLocalInt(ES_Util_GetDataObject(PROFILER_SCRIPT_NAME), "OVERHEAD_COMPENSATION");
}

void Profiler_SetOverheadCompensation(int nOverhead)
{
    SetLocalInt(ES_Util_GetDataObject(PROFILER_SCRIPT_NAME), "OVERHEAD_COMPENSATION", nOverhead);
}

int Profiler_Calibrate(int nIterations)
{
    int i, nSum;

    for (i = 0; i < nIterations; i++)
    {
        nSum += Profiler_Stop(Profiler_Start("Calibration", TRUE, FALSE));
    }

    return nIterations == 0 ? 0 : nSum / nIterations;
}

struct ProfilerStats Profiler_GetStats(string sName)
{
    struct ProfilerStats ps;
    object oDataObject = ES_Util_GetDataObject(PROFILER_SCRIPT_NAME + "!" + sName, FALSE);

    ps.sName = sName;

    if (GetIsObjectValid(oDataObject))
    {
        ps.nSum = GetLocalInt(oDataObject, "PROFILER_SUM");
        ps.nCount = GetLocalInt(oDataObject, "PROFILER_COUNT");
        ps.nMin = GetLocalInt(oDataObject, "PROFILER_MIN");
        ps.nMax = GetLocalInt(oDataObject, "PROFILER_MAX");
        ps.nAvg = ps.nCount == 0 ? 0 : ps.nSum / ps.nCount;
    }

    return ps;
}

void Profiler_DeleteStats(string sName)
{
    ES_Util_DestroyDataObject(PROFILER_SCRIPT_NAME + "!" + sName);

    ES_Util_Log(PROFILER_LOG_TAG, "Deleted stats for: '" + sName + "'");
}

string nssProfiler(string sName, string sContents, int bSkipLog = FALSE, int bEnableStats = TRUE)
{
    return "struct ProfilerData pd = " + nssFunction("Profiler_Start",
        nssEscapeDoubleQuotes(sName) + ", " + IntToString(bSkipLog) + ", " +
        IntToString(bEnableStats)) + sContents + " Profiler_Stop(pd);";
}

