/*
    ScriptName: es_inc_array.nss
    Created by: Daz

    Description: Event System Array Include
*/

// *** STRING

// Insert a string to sArrayName
void StringArray_Insert(object oObject, string sArrayName, string sValue);
// Set nIndex of sArrayName to sValue
void StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue);
// Get the size of sArrayName
int StringArray_Size(object oObject, string sArrayName);
// Get the string at nIndex of sArrayName
string StringArray_At(object oObject, string sArrayName, int nIndex);
// Delete sArrayName
void StringArray_Clear(object oObject, string sArrayName);
// Returns the index of sValue if it exists in sArrayName or -1 if not
int StringArray_Contains(object oObject, string sArrayName, string sValue);
// Delete nIndex from sArrayName on oObject
void StringArray_Delete(object oObject, string sArrayName, int nIndex);
// Delete sValue from sArrayName on oObject
void StringArray_DeleteByValue(object oObject, string sArrayName, string sValue);

void StringArray_Insert(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName);
    SetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), sValue);
    SetLocalInt(oObject, "SA!NUM!" + sArrayName, ++nSize);
}

void StringArray_Set(object oObject, string sArrayName, int nIndex, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        SetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), sValue);
}

int StringArray_Size(object oObject, string sArrayName)
{
    return GetLocalInt(oObject, "SA!NUM!" + sArrayName);
}

string StringArray_At(object oObject, string sArrayName, int nIndex)
{
    return GetLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void StringArray_Clear(object oObject, string sArrayName)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndex;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            DeleteLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
        }

        DeleteLocalInt(oObject, "SA!NUM!" + sArrayName);
    }
}

int StringArray_Contains(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndex;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            string sElement = StringArray_At(oObject, sArrayName, nIndex);

            if (sElement == sValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void StringArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            StringArray_Set(oObject, sArrayName, nIndexNew, StringArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        DeleteLocalString(oObject, "SA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        SetLocalInt(oObject, "SA!NUM!" + sArrayName, nSize - 1);
    }
}

void StringArray_DeleteByValue(object oObject, string sArrayName, string sValue)
{
    int nSize = StringArray_Size(oObject, sArrayName), nIndex;
    string sElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        sElement = StringArray_At(oObject, sArrayName, nIndex);

        if (sElement == sValue)
        {
            StringArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}

// *** OBJECT

// Insert an object to sArrayName
void ObjectArray_Insert(object oObject, string sArrayName, object oValue);
// Set nIndex of sArrayName to oValue
void ObjectArray_Set(object oObject, string sArrayName, int nIndex, object oValue);
// Get the size of sArrayName
int ObjectArray_Size(object oObject, string sArrayName);
// Get the object at nIndex of sArrayName
object ObjectArray_At(object oObject, string sArrayName, int nIndex);
// Delete sArrayName
void ObjectArray_Clear(object oObject, string sArrayName);
// Returns the index of oValue if it exists in sArrayName or -1 if not
int ObjectArray_Contains(object oObject, string sArrayName, object oValue);
// Delete nIndex from sArrayName on oObject
void ObjectArray_Delete(object oObject, string sArrayName, int nIndex);
// Delete oObject from sArrayName on oObject
void ObjectArray_DeleteByValue(object oObject, string sArrayName, object oValue);

void ObjectArray_Insert(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName);
    SetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nSize), oValue);
    SetLocalInt(oObject, "OA!NUM!" + sArrayName, ++nSize);
}

void ObjectArray_Set(object oObject, string sArrayName, int nIndex, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName);

    if (nIndex < nSize)
        SetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex), oValue);
}

int ObjectArray_Size(object oObject, string sArrayName)
{
    return GetLocalInt(oObject, "OA!NUM!" + sArrayName);
}

object ObjectArray_At(object oObject, string sArrayName, int nIndex)
{
    return GetLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
}

void ObjectArray_Clear(object oObject, string sArrayName)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            DeleteLocalString(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nIndex));
        }

        DeleteLocalInt(oObject, "OA!NUM!" + sArrayName);
    }

}

int ObjectArray_Contains(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;
    object oElement;

    if (nSize)
    {
        for (nIndex = 0; nIndex < nSize; nIndex++)
        {
            oElement = ObjectArray_At(oObject, sArrayName, nIndex);

            if (oElement == oValue)
            {
                return nIndex;
            }
        }
    }

    return -1;
}

void ObjectArray_Delete(object oObject, string sArrayName, int nIndex)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndexNew;
    if (nIndex < nSize)
    {
        for (nIndexNew = nIndex; nIndexNew < nSize - 1; nIndexNew++)
        {
            ObjectArray_Set(oObject, sArrayName, nIndexNew, ObjectArray_At(oObject, sArrayName, nIndexNew + 1));
        }

        DeleteLocalObject(oObject, "OA!ELEMENT!" + sArrayName + "!" + IntToString(nSize - 1));
        SetLocalInt(oObject, "OA!NUM!" + sArrayName, nSize - 1);
    }
}

void ObjectArray_DeleteByValue(object oObject, string sArrayName, object oValue)
{
    int nSize = ObjectArray_Size(oObject, sArrayName), nIndex;
    object oElement;

    for (nIndex = 0; nIndex < nSize; nIndex++)
    {
        oElement = ObjectArray_At(oObject, sArrayName, nIndex);

        if (oElement == oValue)
        {
            ObjectArray_Delete(oObject, sArrayName, nIndex);
            break;
        }
   }
}

