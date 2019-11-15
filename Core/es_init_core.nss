/*
    ScriptName: es_init_core.nss
    Created by: Daz

    Description:
*/

#include "es_inc_core"

void main()
{
    object oModule = GetModule();

    SetLocalInt(oModule, "es_s_kobmurder", TRUE);
    SetLocalInt(oModule, "es_s_chair", TRUE);
    //SetLocalInt(oModule, "es_s_pocketitem", TRUE);
    SetLocalInt(oModule, "es_s_iditem", TRUE);
    SetLocalInt(oModule, "es_s_chat", TRUE);
    SetLocalInt(oModule, "es_s_example", TRUE);

    ES_Core_Init();
}
