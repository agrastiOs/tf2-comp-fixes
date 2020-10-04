ConVar g_convar_enabled;
ConVar g_convar_vote;
ConVar g_convar_timeleft;

bool g_votes[MAXPLAYERS] = {false, ...};

void Concede_Setup() {
    g_convar_enabled =
        CreateConVar("sm_concede_command", "0", _, FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_convar_vote = CreateConVar("sm_concede_command_vote", "0", _, FCVAR_NOTIFY, true, 0.0);
    g_convar_timeleft =
        CreateConVar("sm_concede_command_timeleft", "0", _, FCVAR_NOTIFY, true, 0.0);

    RegConsoleCmd("concede", Concede_Command);

    HookEvent("teamplay_restart_round", OnRestartRound);
    HookEvent("player_team", OnPlayerTeam);
}

Action Concede_Command(int client, int args) {
    if (!g_convar_enabled.BoolValue) {
        PrintToChat(client,
                    "[TF2 Competitive Fixes] Cannot concede without `sm_concede_command` set to 1");
        return Plugin_Handled;
    }

    int time_left = 0;
    GetMapTimeLeft(time_left);
    time_left /= 60;
    if (g_convar_timeleft.IntValue > 0 && time_left > g_convar_timeleft.IntValue) {
        PrintToChat(client,
                    "[TF2 Competitive Fixes] Cannot concede until time left (%d) reaches %d",
                    time_left, g_convar_timeleft.IntValue);
        return Plugin_Handled;
    }

    TFTeam team = TF2_GetClientTeam(client);

    if (team != TFTeam_Red && team != TFTeam_Blue) {
        PrintToChat(client, "[TF2 Competitive Fixes] Can only concede while playing...");
        return Plugin_Handled;
    }

    bool vote_before = g_votes[client];
    g_votes[client]  = true;

    int team_votes = VotesByTeam(team);

    char team_name[32];
    GetTeamName(view_as<int>(team), team_name, sizeof(team_name));

    if (g_convar_vote.IntValue < 1 || team_votes >= g_convar_vote.IntValue) {
        PrintToChatAll("[TF2 Competitive Fixes] '%s' has conceded the match", team_name);
        ForceWin(team == TFTeam_Red ? TFTeam_Blue : TFTeam_Red);
        return Plugin_Handled;
    }

    if (!vote_before) {
        PrintToChatAll(
            "[TF2 Competitive Fixes] %N is voting for team '%s' to concede, %d more votes required",
            client, team_name, g_convar_vote.IntValue - team_votes);
    }

    return Plugin_Handled;
}

void OnRestartRound(Event event, const char[] name, bool dontBroadcast) { ResetVotes(); }

void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (g_votes[client]) {
        PrintToChat(client, "[TF2 Competitive Fixes] Removing your !concede vote");
    }

    g_votes[client] = false;
}

int VotesByTeam(TFTeam team) {
    int votes = 0;

    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && team == TF2_GetClientTeam(client) && g_votes[client]) {
            votes += 1;
        }
    }

    return votes;
}

void ResetVotes() {
    for (int client = 1; client <= MaxClients; client++) {
        g_votes[client] = false;
    }
}
