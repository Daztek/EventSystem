/*
    ScriptName: es_s_profiler.nss
    Created by: Daz

    Description: A Script Profiler Subsystem
*/

//void main() {}

#include "es_inc_core"
#include "nwnx_time"

const string PROFILER_SYSTEM_TAG                        = "Profiler";
const int    PROFILER_OVERHEAD_COMPENSATION_ITERATIONS  = 1000;

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

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = FALSE);
int Profiler_Stop(struct ProfilerData startData);
int Profiler_GetOverheadCompensation();
void Profiler_SetOverheadCompensation(int nOverhead);
int Profiler_Calibrate(int nIterations);
struct ProfilerStats Profiler_GetStats(string sName);
void Profiler_DeleteStats(string sName);

// @EventSystem_Init
void Profiler_Init(string sSubsystemScript)
{
    int nOverhead = Profiler_Calibrate(PROFILER_OVERHEAD_COMPENSATION_ITERATIONS);

    ES_Util_Log(PROFILER_SYSTEM_TAG, "Overhead Compensation: " + IntToString(nOverhead) + "us");

    Profiler_SetOverheadCompensation(nOverhead);
}

struct ProfilerData Profiler_Start(string sName, int bSkipLog = FALSE, int bEnableStats = FALSE)
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
        object oDataObject = ES_Util_GetDataObject(PROFILER_SYSTEM_TAG + "!" + startData.sName);
        int nMin, nMax, nCount = ES_Util_GetInt(oDataObject, "PROFILER_COUNT") + 1;
        ES_Util_SetInt(oDataObject, "PROFILER_COUNT", nCount);

        if (nCount == 1)
        {
            nMin = nTotalMicroSeconds;
            nMax = nTotalMicroSeconds;

            ES_Util_SetInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            ES_Util_SetInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
        }
        else
        {
            nMin = ES_Util_GetInt(oDataObject, "PROFILER_MIN");
            if (nTotalMicroSeconds < nMin)
            {
                nMin = nTotalMicroSeconds;
                ES_Util_SetInt(oDataObject, "PROFILER_MIN", nTotalMicroSeconds);
            }

            nMax = ES_Util_GetInt(oDataObject, "PROFILER_MAX");
            if (nTotalMicroSeconds > nMax)
            {
                nMax = nTotalMicroSeconds;
                ES_Util_SetInt(oDataObject, "PROFILER_MAX", nTotalMicroSeconds);
            }
        }

        int nSum = ES_Util_GetInt(oDataObject, "PROFILER_SUM") + nTotalMicroSeconds;
        ES_Util_SetInt(oDataObject, "PROFILER_SUM", nSum);

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

        ES_Util_Log(PROFILER_SYSTEM_TAG, "[" + startData.sName + "] " + IntToString(nTotalSeconds) + "." + sZeroPadding + IntToString(nTotalMicroSeconds) + " seconds" + sStats);
    }

    return nTotalMicroSeconds;
}

int Profiler_GetOverheadCompensation()
{
    return ES_Util_GetInt(ES_Util_GetDataObject(PROFILER_SYSTEM_TAG), "OVERHEAD_COMPENSATION");
}

void Profiler_SetOverheadCompensation(int nOverhead)
{
    ES_Util_SetInt(ES_Util_GetDataObject(PROFILER_SYSTEM_TAG), "OVERHEAD_COMPENSATION", nOverhead);
}

int Profiler_Calibrate(int nIterations)
{
    int i, nSum;
    struct ProfilerData pd;

    for (i = 0; i < nIterations; i++)
    {
        nSum += Profiler_Stop(Profiler_Start("Calibration", TRUE));
    }

    return nSum / nIterations;
}

struct ProfilerStats Profiler_GetStats(string sName)
{
    struct ProfilerStats ps;
    object oDataObject = ES_Util_GetDataObject(PROFILER_SYSTEM_TAG + "!" + sName);

    ps.sName = sName;
    ps.nSum = ES_Util_GetInt(oDataObject, "PROFILER_SUM");
    ps.nCount = ES_Util_GetInt(oDataObject, "PROFILER_COUNT");
    ps.nMin = ES_Util_GetInt(oDataObject, "PROFILER_MIN");
    ps.nMax = ES_Util_GetInt(oDataObject, "PROFILER_MAX");
    ps.nAvg = ps.nSum / ps.nCount;

    return ps;
}

void Profiler_DeleteStats(string sName)
{
    ES_Util_DestroyDataObject(PROFILER_SYSTEM_TAG + "!" + sName);

    ES_Util_Log(PROFILER_SYSTEM_TAG, "Destroying Stats for: " +sName);
}

