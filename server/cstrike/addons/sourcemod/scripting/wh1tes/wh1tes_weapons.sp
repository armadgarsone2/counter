#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name        = "Wh1Tes Weapons",
	author      = "Server Owner",
	description = "MW3 weapon models via new paths (index-based)",
	version     = "1.6.0",
	url         = ""
};

char g_NewModels[][] = {
	"models/weapons/mw3/v_c4.mdl",
	"models/weapons/mw3/v_eq_flashbang.mdl",
	"models/weapons/mw3/v_eq_fraggrenade.mdl",
	"models/weapons/mw3/v_eq_smokegrenade.mdl",
	"models/weapons/mw3/v_knife_t.mdl",
	"models/weapons/mw3/v_mach_m249para.mdl",
	"models/weapons/mw3/v_pist_deagle.mdl",
	"models/weapons/mw3/v_pist_elite.mdl",
	"models/weapons/mw3/v_pist_fiveseven.mdl",
	"models/weapons/mw3/v_pist_glock18.mdl",
	"models/weapons/mw3/v_pist_p228.mdl",
	"models/weapons/mw3/v_pist_usp.mdl",
	"models/weapons/mw3/v_rif_ak47.mdl",
	"models/weapons/mw3/v_rif_aug.mdl",
	"models/weapons/mw3/v_rif_famas.mdl",
	"models/weapons/mw3/v_rif_galil.mdl",
	"models/weapons/mw3/v_rif_m4a1.mdl",
	"models/weapons/mw3/v_rif_sg552.mdl",
	"models/weapons/mw3/v_shot_m3super90.mdl",
	"models/weapons/mw3/v_shot_xm1014.mdl",
	"models/weapons/mw3/v_smg_mac10.mdl",
	"models/weapons/mw3/v_smg_mp5.mdl",
	"models/weapons/mw3/v_smg_p90.mdl",
	"models/weapons/mw3/v_smg_tmp.mdl",
	"models/weapons/mw3/v_smg_ump45.mdl",
	"models/weapons/mw3/v_snip_awp.mdl",
	"models/weapons/mw3/v_snip_g3sg1.mdl",
	"models/weapons/mw3/v_snip_scout.mdl",
	"models/weapons/mw3/v_snip_sg550.mdl",
	"models/weapons/mw3/w_c4.mdl",
	"models/weapons/mw3/w_c4_planted.mdl",
	"models/weapons/mw3/w_defuser.mdl",
	"models/weapons/mw3/w_eq_eholster.mdl",
	"models/weapons/mw3/w_eq_eholster_elite.mdl",
	"models/weapons/mw3/w_eq_flashbang.mdl",
	"models/weapons/mw3/w_eq_flashbang_thrown.mdl",
	"models/weapons/mw3/w_eq_fraggrenade.mdl",
	"models/weapons/mw3/w_eq_fraggrenade_thrown.mdl",
	"models/weapons/mw3/w_eq_smokegrenade.mdl",
	"models/weapons/mw3/w_eq_smokegrenade_thrown.mdl",
	"models/weapons/mw3/w_knife_ct.mdl",
	"models/weapons/mw3/w_knife_t.mdl",
	"models/weapons/mw3/w_mach_m249para.mdl",
	"models/weapons/mw3/w_pist_deagle.mdl",
	"models/weapons/mw3/w_pist_elite.mdl",
	"models/weapons/mw3/w_pist_elite_dropped.mdl",
	"models/weapons/mw3/w_pist_elite_single.mdl",
	"models/weapons/mw3/w_pist_fiveseven.mdl",
	"models/weapons/mw3/w_pist_glock18.mdl",
	"models/weapons/mw3/w_pist_p228.mdl",
	"models/weapons/mw3/w_pist_usp.mdl",
	"models/weapons/mw3/w_pist_usp_silencer.mdl",
	"models/weapons/mw3/w_rif_ak47.mdl",
	"models/weapons/mw3/w_rif_aug.mdl",
	"models/weapons/mw3/w_rif_famas.mdl",
	"models/weapons/mw3/w_rif_galil.mdl",
	"models/weapons/mw3/w_rif_m4a1.mdl",
	"models/weapons/mw3/w_rif_m4a1_silencer.mdl",
	"models/weapons/mw3/w_rif_sg552.mdl",
	"models/weapons/mw3/w_shot_m3super90.mdl",
	"models/weapons/mw3/w_shot_xm1014.mdl",
	"models/weapons/mw3/w_smg_mac10.mdl",
	"models/weapons/mw3/w_smg_mp5.mdl",
	"models/weapons/mw3/w_smg_p90.mdl",
	"models/weapons/mw3/w_smg_tmp.mdl",
	"models/weapons/mw3/w_smg_ump45.mdl",
	"models/weapons/mw3/w_snip_awp.mdl",
	"models/weapons/mw3/w_snip_g3sg1.mdl",
	"models/weapons/mw3/w_snip_scout.mdl",
	"models/weapons/mw3/w_snip_sg550.mdl",
};
int g_Idx[sizeof(g_NewModels)];

void FillIdx()
{
	for (int i = 0; i < sizeof(g_NewModels); i++)
		g_Idx[i] = PrecacheModel(g_NewModels[i], true);
}

int FindModel(const char[] basename)
{
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "models/weapons/mw3/%s", basename);
	for (int i = 0; i < sizeof(g_NewModels); i++)
		if (StrEqual(g_NewModels[i], path))
			return i;
	return -1;
}

void FixWeapon(int weapon)
{
	if (!IsValidEntity(weapon))
		return;
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(weapon, Prop_Data, "m_ModelName", model, sizeof(model));
	char base[64];
	int pos = FindCharInString(model, '/', true);
	if (pos == -1)
		return;
	strcopy(base, sizeof(base), model[pos + 1]);
	if (base[0] == 'v' && base[1] == '_')
	{
		int vi = FindModel(base);
		if (vi == -1)
			return;
		SetEntProp(weapon, Prop_Send, "m_iViewModelIndex", g_Idx[vi]);
		char wbase[64];
		Format(wbase, sizeof(wbase), "w_%s", base[2]);
		int wi = FindModel(wbase);
		if (wi != -1)
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", g_Idx[wi]);
	}
}

public void OnMapStart()
{
	FillIdx();
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/m67_grenade_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/m67_grenade_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/m84_flashbang_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/m84_flashbang_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/us_smoke_grenade_c.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/COD_G/us_smoke_grenade_c.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW2_Knife/knife_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW2_Knife/knife_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW2_Knife/knife_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW2_Knife/knife_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/ak47_iw5_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/ak47_iw5_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/ak47_iw5_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/ak47_iw5_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/rail_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/rail_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/rail_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_AK47/rail_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_alpha_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_alpha_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_alpha_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_alpha_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_BOMB/briefbomb_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Deagle/de_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Deagle/de_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Deagle/de_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Deagle/de_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_FN57/fiveseven_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_FN57/fiveseven_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_FN57/fiveseven_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_FN57/fiveseven_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/g18_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/g18_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/g18_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/g18_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/rail_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/rail_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/rail_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/rail_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/red_dot_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/red_dot_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/red_dot_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/red_dot_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/reflex_lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G18/reflex_lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/acog_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/acog_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/acog_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/acog_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/g36_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/g36_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/g36c_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/g36c_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/lens_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_G36/lens_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_KSG12/ksg_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_KSG12/ksg_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_KSG12/ksg_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_KSG12/ksg_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/aw_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/aw_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/aw_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/aw_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/dsr50_l.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/dsr50_l.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/dsr50_l2.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/s_c.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/s_c.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/s_g.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_L118A/s_n.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/eotech_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/eotech_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/eotech_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/eotech_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/foregrip_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/foregrip_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/foregrip_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/foregrip_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lens_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lens_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lense_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/lense_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/m4_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/m4_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/m4_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/m4_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/magnifier_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/magnifier_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/magnifier_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/magnifier_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/sm_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/sm_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/sm_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/sm_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/suppressor_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/suppressor_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/suppressor_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M4A1/suppressor_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bipod_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bipod_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bipod_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bipod_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bullet_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bullet_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bullet_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/bullet_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/m60_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/m60_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/m60_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M60/m60_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/dsr50_l.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/dsr50_l.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/lens_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/lens_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82_iw5_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82_iw5_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82_iw5_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82_iw5_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82scope_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82scope_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82scope_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_M82/m82scope_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/bullet_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/bullet_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/bullet_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/bullet_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/mp412_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/mp412_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/mp412_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP412/mp412_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/eotech_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/eotech_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/eotech_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/eotech_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/lense_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/lense_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/mp9_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/mp9_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/mp9_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/mp9_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/rail_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/rail_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/rail_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MP9/rail_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/bipod_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/bipod_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/bipod_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/bipod_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/dsr50_l.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/dsr50_l.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/msr_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/msr_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/msr_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/msr_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/scope_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/scope_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/scope_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_MSR/scope_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_innermag_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_innermag_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_innermag_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_innermag_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_mag_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/p90_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/red_dot_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/red_dot_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/red_dot_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/red_dot_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/reflex_lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/reflex_lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/reflex_lense_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/suppressor_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/suppressor_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/suppressor_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P90/suppressor_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/knife_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/knife_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/knife_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/knife_nrml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/p99_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/p99_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/p99_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_P99/p99_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/acog_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/acog_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/acog_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/acog_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/lens_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/lens_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/weapon_scar_l_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/weapon_scar_l_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/weapon_scar_l_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SCAR/weapon_scar_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/Lens2.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dragunov_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dragunov_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dragunov_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dragunov_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dsr50_l.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dsr50_l2.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/dsr50_l_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/lens_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/scope_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/scope_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/scope_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_SVD/scope_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/rail_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/rail_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/rail_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/rail_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/red_dot_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/red_dot_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/red_dot_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/red_dot_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/reflex_lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/reflex_lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/reflex_lense_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/skorpion_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/skorpion_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/skorpion_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_Skorpion/skorpion_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/eotech_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/eotech_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/eotech_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/eotech_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/lense_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/lense_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/lense_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/lense_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/weapon_ump45_iw5_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/weapon_ump45_iw5_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/weapon_ump45_iw5_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_UMP45/weapon_ump45_iw5_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/suppressor_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/suppressor_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/suppressor_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/suppressor_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/usp45_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/usp45_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/usp45_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/MW3_USP45/usp45_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/alpha_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/alpha_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/alpha_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/digit_anim.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/digit_anim.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/glove_3_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/glove_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/glove_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/glove_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/sleeve_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/sleeve_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/sleeve_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/delta/sleeve_shg_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_cm901/cm901_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_cm901/cm901_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_cm901/cm901_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_cm901/weapon_cm901_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_mp5/mp5_new_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_mp5/mp5_new_col.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_mp5/mp5_new_gloss.vtf");
	AddFileToDownloadsTable("materials/models/weapons/v_models/mw3_mp5/mp5_new_nml.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/MW3_Deagle/de_col.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_eq_defuser/w_eq_defuser.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_eq_eholster/w_eq_eholster.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/w_pist_elite.vmt");
	AddFileToDownloadsTable("models/weapons/mw3/v_c4.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_c4.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_c4.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_c4.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_c4.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_flashbang.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_flashbang.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_flashbang.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_flashbang.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_flashbang.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_fraggrenade.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_fraggrenade.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_fraggrenade.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_fraggrenade.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_fraggrenade.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_smokegrenade.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_smokegrenade.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_smokegrenade.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_smokegrenade.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_eq_smokegrenade.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_knife_t.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_knife_t.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_knife_t.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_knife_t.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_knife_t.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_mach_m249para.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_mach_m249para.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_mach_m249para.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_mach_m249para.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_mach_m249para.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_deagle.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_deagle.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_deagle.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_deagle.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_deagle.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_elite.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_elite.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_elite.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_elite.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_elite.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_fiveseven.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_fiveseven.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_fiveseven.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_fiveseven.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_fiveseven.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_glock18.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_glock18.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_glock18.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_glock18.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_glock18.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_p228.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_p228.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_p228.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_p228.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_p228.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_usp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_usp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_usp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_usp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_pist_usp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_ak47.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_ak47.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_ak47.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_ak47.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_ak47.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_aug.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_aug.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_aug.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_aug.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_aug.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_famas.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_famas.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_famas.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_famas.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_famas.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_galil.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_galil.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_galil.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_galil.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_galil.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_m4a1.xbox.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_sg552.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_sg552.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_sg552.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_sg552.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_rif_sg552.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_m3super90.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_m3super90.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_m3super90.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_m3super90.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_m3super90.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_xm1014.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_xm1014.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_xm1014.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_xm1014.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_shot_xm1014.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mac10.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mac10.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mac10.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mac10.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mac10.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mp5.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mp5.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mp5.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mp5.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_mp5.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_p90.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_p90.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_p90.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_p90.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_p90.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_tmp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_tmp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_tmp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_tmp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_tmp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_ump45.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_ump45.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_ump45.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_ump45.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_smg_ump45.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_awp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_awp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_awp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_awp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_awp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_g3sg1.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_g3sg1.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_g3sg1.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_g3sg1.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_g3sg1.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_scout.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_scout.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_scout.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_scout.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_scout.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_sg550.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_sg550.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_sg550.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_sg550.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/v_snip_sg550.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_c4_planted.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_defuser.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_defuser.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_defuser.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_defuser.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster_elite.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster_elite.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster_elite.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_eholster_elite.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_flashbang_thrown.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_fraggrenade_thrown.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_eq_smokegrenade_thrown.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_ct.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_knife_t.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_mach_m249para.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_deagle.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_dropped.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_elite_single.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_fiveseven.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_glock18.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_p228.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_pist_usp_silencer.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_ak47.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_aug.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_famas.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_galil.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_m4a1_silencer.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_rif_sg552.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_m3super90.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_shot_xm1014.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mac10.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_mp5.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_p90.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_tmp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_smg_ump45.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_awp.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_g3sg1.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_scout.vvd");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.mdl");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.phy");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.sw.vtx");
	AddFileToDownloadsTable("models/weapons/mw3/w_snip_sg550.vvd");
}

public void OnPluginStart()
{
	FillIdx();
	HookEvent("item_pickup", Event_Pickup);
	HookEvent("player_spawn", Event_SpawnW);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_WeaponSwitchPost, OnSwitch);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, OnSwitch);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "weapon_") == 0)
		CreateTimer(0.15, Timer_FixWeapon, EntIndexToEntRef(entity));
}

public Action Timer_FixWeapon(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity != INVALID_ENT_REFERENCE)
		FixWeapon(entity);
	return Plugin_Stop;
}

public void OnSwitch(int client, int weapon)
{
	if (weapon > 0)
		FixWeapon(weapon);
}

public void Event_Pickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
		CreateTimer(0.1, Timer_FixClient, GetClientSerial(client));
}

public void Event_SpawnW(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
		CreateTimer(0.4, Timer_FixClient, GetClientSerial(client));
}

public Action Timer_FixClient(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (client > 0 && IsClientInGame(client))
	{
		for (int s = 0; s < 5; s++)
		{
			int w = GetPlayerWeaponSlot(client, s);
			if (w > 0)
				FixWeapon(w);
		}
	}
	return Plugin_Stop;
}
