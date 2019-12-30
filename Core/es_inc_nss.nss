/*
    ScriptName: es_inc_nss.nss
    Created by: Daz

    Description: Event System NSS Utility Include
*/

string nssVoidMain(string sContents);
string nssStartingConditional(string sContents);
string nssInclude(string sIncludeFile);
string nssIfStatement(string sFunction, string sComparison, string sValue);
string nssElseIfStatement(string sFunction, string sComparison, string sValue);
string nssBrackets(string sContents);
string nssEscapeDoubleQuotes(string sText);
string nssSwitch(string sVariable, string sCases);
string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE);
string nssObject(string sVarName, string sFunction = "");
string nssString(string sVarName, string sFunction = "");
string nssInt(string sVarName, string sFunction = "");

string nssVoidMain(string sContents)
{
    return "void main() { " + sContents + " }";
}

string nssStartingConditional(string sContents)
{
    return "int StartingConditional() { return " + sContents + " }";
}

string nssInclude(string sIncludeFile)
{
    return sIncludeFile == "" ? sIncludeFile : "#" + "include \"" + sIncludeFile + "\" ";
}

string nssIfStatement(string sFunction, string sComparison, string sValue)
{
    return "if (" + sFunction + " " + sComparison + " " + sValue + ") ";
}

string nssElseIfStatement(string sFunction, string sComparison, string sValue)
{
    return "else if (" + sFunction + " " + sComparison + " " + sValue + ") ";
}

string nssBrackets(string sContents)
{
    return "{ " + sContents + " } ";
}

string nssEscapeDoubleQuotes(string sText)
{
    return "\"" + sText + "\"";
}

string nssSwitch(string sVariable, string sCases)
{
    return "switch (" + sVariable + ") { " + sCases + " };";
}

string nssCaseStatement(int nCase, string sContents, int bBreak = TRUE)
{
    return "case " + IntToString(nCase) + ": { " + sContents + (bBreak ? " break;" : "") + " } ";
}

string nssVariable(string sType, string sVarName, string sFunction)
{
    return sType + " " + sVarName + (sFunction == "" ? "; " : " = " + sFunction + "; ");
}

string nssObject(string sVarName, string sFunction = "")
{
    return nssVariable("object", sVarName, sFunction);
}

string nssString(string sVarName, string sFunction = "")
{
    return nssVariable("string", sVarName, sFunction);
}

string nssInt(string sVarName, string sFunction = "")
{
    return nssVariable("int", sVarName, sFunction);
}

