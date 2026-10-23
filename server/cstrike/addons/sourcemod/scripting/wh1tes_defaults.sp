#pragma semicolon 1
// Transitional style on purpose: the live tree spcomp is SM 1.7.3 (error 147
// with `#pragma newdecls required` + sdktools includes).
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes Default Models",
    author = "Wh1Tes",
    description = "Default player models = the new G7 pack skins (slot rotation)",
    version = "1.0.0"
};

char g_sCT[][] = {
    "models/player/vad36_swat/bio_haz.mdl",
    "models/player/vad36_swat/chem_haz.mdl",
    "models/player/vad36_swat/jamison.mdl",
    "models/player/vad36_swat/van_healen.mdl",
    "models/player/vad36csgomaster/sas.mdl"
};
char g_sT[][] = {
    "models/player/vad36_professional/darryl.mdl",
    "models/player/vad36_professional/littlekev.mdl",
    "models/player/vad36_professional/number_k.mdl",
    "models/player/vad36_professional/sally.mdl",
    "models/player/vad36csgomaster/phoenix.mdl"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
}

public void OnMapStart()
{
    for (int i = 0; i < sizeof(g_sCT); i++)
        PrecacheModel(g_sCT[i], true);
    for (int i = 0; i < sizeof(g_sT); i++)
        PrecacheModel(g_sT[i], true);
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/bare_arm_133.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/bare_arm_133.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/bare_arm_133_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_normal_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_normal_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varf.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varh.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varh.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varh_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_vari.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_vari.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_vari_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varj.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_body_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_normal_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_normal_varh.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_normal_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varf.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varh.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varh.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_vari.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_vari.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_vari_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varj.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_head_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_normal_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_normal_varh.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_normal_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varf.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varh.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varh.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_vari.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_vari.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_vari_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varj.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_lowerbody_varj.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_mask_varf.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_mask_varf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/tm_professional_mask_varf_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/w_t_base_fullfinger_glove.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/w_t_base_fullfinger_glove.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_professional/2020/w_t_base_fullfinger_glove_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_blue.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_blue.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_visor.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_visor.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_visor_blue.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_helmet_visor_blue.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_pant.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_pant.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_pant_blue.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_pant_blue.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_pant_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_upperbody.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_upperbody.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_upperbody_blue.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_upperbody_blue.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_gasmask_upperbody_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_lead_head.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_lead_head.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_lead_head_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_hair.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_hair.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_hair_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_headset.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_headset.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_headset_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_pant.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_pant.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_pant_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_upperbody.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_upperbody.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_leader_upperbody_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_head.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_head.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_head_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_headgear.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_headgear.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_headgear_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_pant.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_pant.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_pant_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_upperbody.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_upperbody.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/ctm_swat_medic_upperbody_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/w_ct_fbi_glov.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/w_ct_fbi_glov.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36_swat/2020/w_ct_fbi_glov_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/bare_arm_103.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/bare_arm_103.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/bare_arm_133_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/t_base_fullfinger_glove.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/t_base_fullfinger_glove.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/t_base_fullfinger_glove_exp.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/t_base_fullfinger_glove_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_legs_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_balaclava_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_balaclava_variantd.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_balaclava_variantd.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_balaclava_variantg.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_balaclava_variantg.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_body_variantb.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_body_variantb.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_body_variantg.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_body_variantg.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_legs_variantb.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_legs_variantb.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_legs_variantg.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/phoenix/tm_phoenix_v2_legs_variantg.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_body.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_body.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_body_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_head_gasmask.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_head_gasmask.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_head_gasmask_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_legs.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_legs.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_legs_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_lenses_variantf.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/ctm_sas_lenses_variantf.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/w_ct_base_glove_exp.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/w_ct_base_glove_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/w_ct_fbi_glove.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36csgomaster/sas/w_ct_fbi_glove.vtf");
	AddFileToDownloadsTable("models/player/vad36_professional/darryl.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_professional/darryl.mdl");
	AddFileToDownloadsTable("models/player/vad36_professional/darryl.phy");
	AddFileToDownloadsTable("models/player/vad36_professional/darryl.vvd");
	AddFileToDownloadsTable("models/player/vad36_professional/littlekev.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_professional/littlekev.mdl");
	AddFileToDownloadsTable("models/player/vad36_professional/littlekev.phy");
	AddFileToDownloadsTable("models/player/vad36_professional/littlekev.vvd");
	AddFileToDownloadsTable("models/player/vad36_professional/number_k.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_professional/number_k.mdl");
	AddFileToDownloadsTable("models/player/vad36_professional/number_k.phy");
	AddFileToDownloadsTable("models/player/vad36_professional/number_k.vvd");
	AddFileToDownloadsTable("models/player/vad36_professional/sally.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_professional/sally.mdl");
	AddFileToDownloadsTable("models/player/vad36_professional/sally.phy");
	AddFileToDownloadsTable("models/player/vad36_professional/sally.vvd");
	AddFileToDownloadsTable("models/player/vad36_swat/bio_haz.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_swat/bio_haz.mdl");
	AddFileToDownloadsTable("models/player/vad36_swat/bio_haz.phy");
	AddFileToDownloadsTable("models/player/vad36_swat/bio_haz.vvd");
	AddFileToDownloadsTable("models/player/vad36_swat/chem_haz.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_swat/chem_haz.mdl");
	AddFileToDownloadsTable("models/player/vad36_swat/chem_haz.phy");
	AddFileToDownloadsTable("models/player/vad36_swat/chem_haz.vvd");
	AddFileToDownloadsTable("models/player/vad36_swat/jamison.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_swat/jamison.mdl");
	AddFileToDownloadsTable("models/player/vad36_swat/jamison.phy");
	AddFileToDownloadsTable("models/player/vad36_swat/jamison.vvd");
	AddFileToDownloadsTable("models/player/vad36_swat/van_healen.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36_swat/van_healen.mdl");
	AddFileToDownloadsTable("models/player/vad36_swat/van_healen.phy");
	AddFileToDownloadsTable("models/player/vad36_swat/van_healen.vvd");
	AddFileToDownloadsTable("models/player/vad36csgomaster/phoenix.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36csgomaster/phoenix.mdl");
	AddFileToDownloadsTable("models/player/vad36csgomaster/phoenix.phy");
	AddFileToDownloadsTable("models/player/vad36csgomaster/phoenix.vvd");
	AddFileToDownloadsTable("models/player/vad36csgomaster/sas.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36csgomaster/sas.mdl");
	AddFileToDownloadsTable("models/player/vad36csgomaster/sas.phy");
	AddFileToDownloadsTable("models/player/vad36csgomaster/sas.vvd");
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
        CreateTimer(0.5, Timer_Apply, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Apply(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
    int team = GetClientTeam(client);
    if (team == 3)
        SetEntityModel(client, g_sCT[client % sizeof(g_sCT)]);
    else if (team == 2)
        SetEntityModel(client, g_sT[client % sizeof(g_sT)]);
    return Plugin_Stop;
}
