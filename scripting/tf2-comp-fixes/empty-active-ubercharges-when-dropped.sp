static Handle g_detour_CTFDroppedWeapon_InitDroppedWeapon;

void EmptyActiveUberchargesWhenDropped_Setup(Handle game_config) {
    g_detour_CTFDroppedWeapon_InitDroppedWeapon =
        CheckedDHookCreateFromConf(game_config, "CTFDroppedWeapon::InitDroppedWeapon");

    CreateBoolConVar("sm_empty_active_ubercharges_when_dropped", WhenConVarChange);
}

static void WhenConVarChange(ConVar cvar, const char[] before, const char[] after) {
    if (cvar.BoolValue == TruthyConVar(before)) {
        return;
    }

    if (!DHookToggleDetour(g_detour_CTFDroppedWeapon_InitDroppedWeapon, HOOK_PRE,
                           Detour_Pre, cvar.BoolValue)) {
        SetFailState("Failed to toggle detour on CTFDroppedWeapon::InitDroppedWeapon");
    }
}

static MRESReturn Detour_Pre(int self, Handle params) {
    if (GetEntProp(DHookGetParam(params, 1), Prop_Send, "m_bChargeRelease", 1)) {
        // Set bIsSuicide to true, forces m_flChargeLevel to 0.0
        DHookSetParam(params, 4, true);
        return MRES_Handled;
    }

    return MRES_Ignored;
}
