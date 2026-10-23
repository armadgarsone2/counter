#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
    name = "Wh1Tes GameDesc",
    author = "Muse",
    description = "Server-list game description: SEMIROMIA",
    version = "1.0.0",
    url = ""
};

public Action:OnGetGameDescription(String:gameDesc[64])
{
    strcopy(gameDesc, 64, "SEMIROMIA");
    return Plugin_Changed;
}
