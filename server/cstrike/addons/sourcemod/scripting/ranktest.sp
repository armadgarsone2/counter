
#include <sourcemod>

public Plugin:myinfo = { name = "RankTest", author = "Muse", description = "sync SQL self-test", version = "1.0.0", url = "" };

public OnPluginStart()
{
    RegServerCmd("sm_ranktest", Cmd_Test);
}

public Action:Cmd_Test(args)
{
    new String:err[255];
    new Handle:db = SQL_Connect("storage-local", true, err, sizeof(err));
    if (db == INVALID_HANDLE) { PrintToServer("[RANKTEST] connect FAILED: %s", err); return Plugin_Handled; }
    SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS ranks (id TEXT PRIMARY KEY, name TEXT, points INTEGER DEFAULT 0, kills INTEGER DEFAULT 0, deaths INTEGER DEFAULT 0, headshots INTEGER DEFAULT 0)");
    SQL_FastQuery(db, "INSERT OR REPLACE INTO ranks (id,name,points,kills,deaths,headshots) VALUES ('__test__','TestPlayer',42,10,5,3)");
    SQL_FastQuery(db, "UPDATE ranks SET points=43 WHERE id='__test__'");
    new Handle:q = SQL_Query(db, "SELECT name,points,kills,deaths FROM ranks WHERE id='__test__'");
    if (q != INVALID_HANDLE && SQL_FetchRow(q))
    {
        new String:nm[64];
        SQL_FetchString(q, 0, nm, sizeof(nm));
        PrintToServer("[RANKTEST] row: %s points=%d kills=%d deaths=%d", nm, SQL_FetchInt(q, 1), SQL_FetchInt(q, 2), SQL_FetchInt(q, 3));
        CloseHandle(q);
    }
    else
        PrintToServer("[RANKTEST] SELECT FAILED");
    SQL_FastQuery(db, "DELETE FROM ranks WHERE id='__test__'");
    PrintToServer("[RANKTEST] cleanup done");
    CloseHandle(db);
    return Plugin_Handled;
}
