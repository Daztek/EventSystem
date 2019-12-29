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
string nssCaseStatement(string sCase, string sContents, int bBreak = TRUE);

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

string nssCaseStatement(string sCase, string sContents, int bBreak = TRUE)
{
    return "case " + sCase + ": { " + sContents + (bBreak ? " break;" : "") + " } ";
}

