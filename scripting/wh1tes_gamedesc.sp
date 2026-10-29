#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Wh1Tes GameDesc",
    author = "Muse",
    description = "Server-list game description: SEMIROMIA",
    version = "1.0.1",
    url = ""
};

public Action OnGetGameDescription(char gameDesc[64])
{
    strcopy(gameDesc, sizeof(gameDesc), "SEMIROMIA");
    return Plugin_Changed;
}
