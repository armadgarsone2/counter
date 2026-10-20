#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = { name = "Wh1Tes Models", author = "Wh1Tes", description = "Custom player models (late precache)", version = "4.0.0" };

bool g_bPrecached = false;

char g_Models[][] = {
	"models/player/bzplayer/ct_gign.mdl",
	"models/player/tf141/ct_gsg9.mdl",
	"models/player/tf141/ct_sas.mdl",
	"models/player/tf141/ct_urban.mdl",
	"models/player/gorka/t_phoenix.mdl",
	"models/player/merc/t_leet.mdl",
	"models/player/jug1/t_guerilla.mdl",
	"models/player/spetz/t_arctic.mdl",
};

public void OnMapStart()
{
	g_bPrecached = false;
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
	CreateTimer(8.0, Timer_Precache);
}

public Action Timer_Precache(Handle timer)
{
	DoPrecache();
	return Plugin_Stop;
}

void DoPrecache()
{
	if (g_bPrecached) return;
	for (int i = 0; i < sizeof(g_Models); i++)
		PrecacheModel(g_Models[i], true);
	g_bPrecached = true;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0)
		CreateTimer(0.5, Timer_Apply, GetClientUserId(client));
	return Plugin_Continue;
}

public Action Timer_Apply(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	DoPrecache();
	char model[PLATFORM_MAX_PATH];
	GetClientModel(client, model, sizeof(model));
	int idx = -1;
	if (StrContains(model, "ct_gign") != -1) idx = 0;
	else if (StrContains(model, "ct_gsg9") != -1) idx = 1;
	else if (StrContains(model, "ct_sas") != -1) idx = 2;
	else if (StrContains(model, "ct_urban") != -1) idx = 3;
	else if (StrContains(model, "t_phoenix") != -1) idx = 4;
	else if (StrContains(model, "t_leet") != -1) idx = 5;
	else if (StrContains(model, "t_guerilla") != -1) idx = 6;
	else if (StrContains(model, "t_arctic") != -1) idx = 7;
	if (idx >= 0)
		SetEntityModel(client, g_Models[idx]);
	return Plugin_Stop;
}
