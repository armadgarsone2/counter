#pragma semicolon 1
// NOTE: no `#pragma newdecls required` — the live server tree spcomp is SM 1.7.3
// and its sdktools includes are old-style (error 147 otherwise). Transitional compiles.
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Wh1Tes Skin Shop",
    author = "Wh1Tes",
    description = "!shop - pick your player skin (saved per player name)",
    version = "1.2.0"
};

// REVERSED layout (Ali's final call 2026-10-23): the shop carries the 8 OLD
// backup skins; the 10 new G7 skins are the auto-assigned defaults
// (wh1tes_defaults). Menu "Default" = back to the new-pack default.
char g_sCTNames[][] = {
    "GIGN (BZ)",
    "GSG9 (TF141)",
    "SAS (TF141)",
    "Urban (TF141)"
};
char g_sCTModels[][] = {
    "models/player/bzplayer/ct_gign.mdl",
    "models/player/tf141/ct_gsg9.mdl",
    "models/player/tf141/ct_sas.mdl",
    "models/player/tf141/ct_urban.mdl"
};
char g_sTNames[][] = {
    "Phoenix (Gorka)",
    "Leet (Merc)",
    "Guerilla (Jug)",
    "Arctic (Spetz)"
};
char g_sTModels[][] = {
    "models/player/gorka/t_phoenix.mdl",
    "models/player/merc/t_leet.mdl",
    "models/player/jug1/t_guerilla.mdl",
    "models/player/spetz/t_arctic.mdl"
};

KeyValues g_kv;
char g_sKvPath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
    RegConsoleCmd("sm_shop", Cmd_Shop, "Open the skin shop");
    RegConsoleCmd("sm_skin", Cmd_Shop, "Open the skin shop");
    RegConsoleCmd("sm_skins", Cmd_Shop, "Open the skin shop");
    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);

    BuildPath(Path_SM, g_sKvPath, sizeof(g_sKvPath), "data/wh1tes_shop.txt");
    g_kv = new KeyValues("shop");
    if (FileExists(g_sKvPath))
        g_kv.ImportFromFile(g_sKvPath);
}

public void OnMapStart()
{
    for (int i = 0; i < sizeof(g_sCTModels); i++)
        PrecacheModel(g_sCTModels[i], true);
    for (int i = 0; i < sizeof(g_sTModels); i++)
        PrecacheModel(g_sTModels[i], true);
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_alpha.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_alpha.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_alpha_n.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_soccom_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_soccom_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_head_hero_soap_soccom_a_n.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_headgear_hero_soap_coms.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_headgear_hero_soap_coms.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_headgear_hero_soap_coms_n.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_lightblue_eye.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/mtl_lightblue_eye.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/soap/normalmap_flat.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141arctic/mtl_weapon_glock.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_brown_eye.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_brown_eye.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_hazel_eye.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_hazel_eye.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_lightblue_eye.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_lightblue_eye.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_alpha.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_alpha.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_alpha_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_a_metal.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_a_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_b.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_b.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_b_metal.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_b_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_assault_b_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_a_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_b.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_b.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_b_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_head_b_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_headgear_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_headgear_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_headgear_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_headgear_a_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_a_metal.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_a_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_ac.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_ac.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_b.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_lower_body_b.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_upper_body_a.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_upper_body_a.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_upper_body_a_n.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_soccom_upper_body_a_s.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_b.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_b.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_b_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_b_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_bc.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_seal_socom_upper_body_bc.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_weapon_glock.vmt");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_weapon_glock.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_weapon_glock_nml.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/mtl_weapon_glock_spec.vtf");
	AddFileToDownloadsTable("materials/models/humangrunt/mw2/tf141brazil/normalmap_flat.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_gign.vmt");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_gign.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_gign_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_glass.vmt");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_urban_glass.vmt");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_urban_glass.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/ct_urban_glass_spec.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/gign_face.vmt");
	AddFileToDownloadsTable("materials/models/player/mwghost/gign_face.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/micro_green.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/micro_sheet.vmt");
	AddFileToDownloadsTable("materials/models/player/mwghost/micro_sheet.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/micro_sheet_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/mwghost/old_gign_face_normal.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_assault_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_assault_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_assault_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_assault_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_boots_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_boots_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_boots_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_boots_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_hands_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_hands_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_hands_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_hands_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lmg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lmg_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lmg_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lmg_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lowerbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lowerbody_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lowerbody_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_lowerbody_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_rpg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_rpg_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_rpg_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_rpg_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_sidearm_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_sidearm_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_sidearm_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_sidearm_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_smg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_smg_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_smg_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_smg_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_upperbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_upperbody_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_upperbody_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/mw3_spetsnaz_upperbody_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_leatherboots_a_col_arctic.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_lower_body_c_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_lower_body_d_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_lower_body_f_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_upper_body_c_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_upper_body_d_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault/russian_military_upper_body_f_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_assault_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_boots_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_hands_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_lmg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_lowerbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_rpg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_sidearm_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_smg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_arctic/mw3_spetsnaz_upperbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_assault_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_boots_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_hands_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_lmg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_lowerbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_rpg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_sidearm_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_smg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_guerilla/mw3_spetsnaz_upperbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_assault_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_boots_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_hands_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_lmg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_lowerbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_rpg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_sidearm_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_smg_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_assault_leet/mw3_spetsnaz_upperbody_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_shiny_lense_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_shiny_lense_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_shiny_lense_eye_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_alpha_b_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_alpha_b_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_alpha_b_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_alpha_b_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_c_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_c_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_d_arc.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_d_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_d_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_d_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_head_d_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_a_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_a_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_a_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_a_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_b_arc.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_b_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_b_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_b_n.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_b_s.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head/mw3_spetsnaz_headgear_g_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/delta_sniper_head_col.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_shiny_lense_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_shiny_lense_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_alpha_b_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_alpha_b_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_head_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_head_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_head_d_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_head_d_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_headgear_a_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_headgear_b_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_headgear_b_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_arctic/mw3_spetsnaz_headgear_g_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_shiny_lense_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_shiny_lense_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_spetsnaz_eye_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_spetsnaz_eye_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_spetsnaz_head_c.vtf");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_spetsnaz_head_d_c.vmt");
	AddFileToDownloadsTable("materials/models/player/spetsnaz_head_guerilla/mw3_spetsnaz_head_d_c.vtf");
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
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_hands_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_hands_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_head_a_clr.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_head_a_clr.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_head_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_loadout_lmg_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_loadout_lmg_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_loadout_lmg_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_lower_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_lower_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_lower_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_upper_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_upper_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/airborne_upper_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/eye.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36airborne/eye.vtf");
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
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-1-2_d.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-1-2_d.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-1-2_stit_d.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-1-2_stit_d.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-2-2_d.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-2-2_d.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-2-2_stit_d.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/ZSH-2-2_stit_d.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/c_rus_spet_mp_armor_c.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/c_rus_spet_mp_armor_c.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_alpha_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_alpha_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_alpha_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_headgear_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_headgear_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_headgear_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_lower_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_lower_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_lower_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_mask_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_mask_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_mask_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_upper_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_upper_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eswat_upper_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eye.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/eye.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/gear_mask.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/gear_mask.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/gear_mask_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_face_shield_lod0.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_face_shield_lod0.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_face_shield_lod0_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_lod0.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_lod0.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_lod0_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v1_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v2.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v2.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/helmet_zsh_1-2m_v2_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/juggernaut_nogear_lowerbody_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/juggernaut_nogear_lowerbody_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/juggernaut_nogear_lowerbody_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/pockets_r.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/pockets_r.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/pockets_rU.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/pockets_rU.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/pockets_r_norm.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/riot_gear_RU.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/riot_gear_RU.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/riot_gear_n.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/sov_armor_diff.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36eswat/sov_armor_diff.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/arctic_support_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/arctic_support_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/arctic_support_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/eye.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/eye.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_head_e_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_head_e_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_head_e_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_d_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_d_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_d_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_e_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_e_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_headgear_e_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_lower_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_lower_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_lower_body_b_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_upper_body_a_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_upper_body_a_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/merc_upper_body_a_nml.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/us_army_smg_alpha_col.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/us_army_smg_alpha_col.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36mercenary/us_army_smg_alpha_nml.vtf");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.dx80.vtx");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.dx90.vtx");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.mdl");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.phy");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.sw.vtx");
	AddFileToDownloadsTable("models/player/bzplayer/ct_gign.vvd");
	AddFileToDownloadsTable("models/player/gorka/t_phoenix.dx80.vtx");
	AddFileToDownloadsTable("models/player/gorka/t_phoenix.dx90.vtx");
	AddFileToDownloadsTable("models/player/gorka/t_phoenix.mdl");
	AddFileToDownloadsTable("models/player/gorka/t_phoenix.sw.vtx");
	AddFileToDownloadsTable("models/player/gorka/t_phoenix.vvd");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.dx80.vtx");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.dx90.vtx");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.mdl");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.phy");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.sw.vtx");
	AddFileToDownloadsTable("models/player/jug1/t_guerilla.vvd");
	AddFileToDownloadsTable("models/player/merc/t_leet.dx80.vtx");
	AddFileToDownloadsTable("models/player/merc/t_leet.dx90.vtx");
	AddFileToDownloadsTable("models/player/merc/t_leet.mdl");
	AddFileToDownloadsTable("models/player/merc/t_leet.phy");
	AddFileToDownloadsTable("models/player/merc/t_leet.sw.vtx");
	AddFileToDownloadsTable("models/player/merc/t_leet.vvd");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.dx80.vtx");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.dx90.vtx");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.mdl");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.phy");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.sw.vtx");
	AddFileToDownloadsTable("models/player/spetz/t_arctic.vvd");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.dx80.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.dx90.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.mdl");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.phy");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.sw.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_gsg9.vvd");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.dx80.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.dx90.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.mdl");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.phy");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.sw.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_sas.vvd");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.dx80.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.dx90.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.mdl");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.phy");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.sw.vtx");
	AddFileToDownloadsTable("models/player/tf141/ct_urban.vvd");
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

void SaveKv()
{
    g_kv.Rewind();
    g_kv.ExportToFile(g_sKvPath);
}

bool GetChoice(int client, char[] model, int maxlen)
{
    int team = GetClientTeam(client);
    if (team != 2 && team != 3)
        return false;
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    g_kv.Rewind();
    if (!g_kv.JumpToKey(name))
        return false;
    g_kv.GetString(team == 3 ? "ct" : "t", model, maxlen, "");
    g_kv.Rewind();
    return model[0] != '\0';
}

void SetChoice(int client, const char[] model)
{
    int team = GetClientTeam(client);
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    g_kv.Rewind();
    g_kv.JumpToKey(name, true);
    g_kv.SetString(team == 3 ? "ct" : "t", model);
    g_kv.Rewind();
    SaveKv();
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && !IsFakeClient(client))
        CreateTimer(0.8, Timer_Apply, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Apply(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
        ApplyChoice(client);
    return Plugin_Stop;
}

void ApplyChoice(int client)
{
    char model[PLATFORM_MAX_PATH];
    if (GetChoice(client, model, sizeof(model)))
        SetEntityModel(client, model);
}

public Action Cmd_Shop(int client, int args)
{
    if (client == 0)
        return Plugin_Handled;
    int team = GetClientTeam(client);
    if (team != 2 && team != 3)
    {
        PrintToChat(client, "[Wh1Tes Shop] Join a team first.");
        return Plugin_Handled;
    }

    Menu menu = new Menu(Menu_Shop);
    menu.SetTitle(team == 3 ? "Skin Shop - CT" : "Skin Shop - T");
    menu.AddItem("", "Default (server choice)");
    if (team == 3)
    {
        for (int i = 0; i < sizeof(g_sCTModels); i++)
            menu.AddItem(g_sCTModels[i], g_sCTNames[i]);
    }
    else
    {
        for (int i = 0; i < sizeof(g_sTModels); i++)
            menu.AddItem(g_sTModels[i], g_sTNames[i]);
    }
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int Menu_Shop(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char model[PLATFORM_MAX_PATH], display[64];
        menu.GetItem(item, model, sizeof(model), _, display, sizeof(display));
        SetChoice(client, model);
        if (model[0] == '\0')
            PrintToChat(client, "[Wh1Tes Shop] Back to default skin.");
        else
        {
            PrintToChat(client, "[Wh1Tes Shop] Skin set: %s", display);
            if (IsPlayerAlive(client))
                SetEntityModel(client, model);
        }
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}
