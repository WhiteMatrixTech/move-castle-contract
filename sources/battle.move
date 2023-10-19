module move_castle::battle {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use sui::math;
    use sui::event;
    use move_castle::castle::{Self, Castle};
    use move_castle::core::{Self, GameStore};
    use sui::clock::{Self, Clock};
    use std::debug;
    use std::vector;
    
    /// Battle event
    struct CastleBattleLog has store, copy, drop {
        attacker_win: bool,
        attacker: ID,
        defender: ID,
        attacker_soldiers_lost: u64,
        defender_soldiers_lost: u64,
        economic_reparation: u64,
        battle_time: u64,
        reparation_end_time: u64
    }
    
    const BATTLE_WINNER_COOLDOWN_MS : u64 = 1 * 60 * 60 * 1000;
    const BATTLE_LOSER_COOLDOWN_MS : u64 = 4 * 60 * 60 * 1000;

    const E_TICKET_EXPIRED : u64 = 0;
    const E_TARGET_NOT_MATCH : u64 = 1;
    const E_BATTLE_COOLDOWN : u64 = 2;

    public entry fun battle(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        // 1. random out a target
        let target_id = core::random_battle_target(object::id(castle), game_store, ctx);

        // 2. castle data
        let (attacker, defender) = core::fetch_castle_data(object::id(castle), target_id, game_store);

        // 3. check battle cooldown
        assert!(attacker.millitary.battle_cooldown < current_timestamp, E_BATTLE_COOLDOWN);
        assert!(defender.millitary.battle_cooldown < current_timestamp, E_BATTLE_COOLDOWN);

        // 4. battle
        // 4.1 calculate total attack power and defence power
        let attack_power = castle::get_castle_total_attack_power(castle);
        let defence_power = castle::get_castle_total_defence_power(target);
        if (castle::has_race_advantage(castle, target)) {
            attack_power = attack_power * 15 / 10
        } else if (castle::has_race_advantage(target, castle)) {
            defence_power = defence_power * 15 / 10
        };
        
        // // 4.2 determine win loss
        // let (attacker_soldiers_left, defender_soldiers_left);
        // let (attacker_cooldown, defender_cooldown);
        // let reparation_economic_power;
        // let attacker_win: bool;
        // if (attack_power > defence_power) {
        //     // attacker win
        //     attacker_win = true;
        //     let (_, attacker_soldier_defence_power) = castle::get_castle_soldier_attack_defence_power(castle);
        //     attacker_soldiers_left = math::divide_and_round_up((attack_power - defence_power), attacker_soldier_defence_power);
        //     defender_soldiers_left = 0;
        //     attacker_cooldown = current_timestamp + BATTLE_WINNER_COOLDOWN_MS;
        //     defender_cooldown = current_timestamp + BATTLE_LOSER_COOLDOWN_MS;
        //     reparation_economic_power = castle::get_castle_base_economic_power(target);
        // } else {
        //     // defender win
        //     attacker_win = false;
        //     let (_, defender_soldier_defence_power) = castle::get_castle_soldier_attack_defence_power(target);
        //     attacker_soldiers_left = 0;
        //     defender_soldiers_left = math::divide_and_round_up((defence_power - attack_power), defender_soldier_defence_power);
        //     attacker_cooldown = current_timestamp + BATTLE_LOSER_COOLDOWN_MS;
        //     defender_cooldown = current_timestamp + BATTLE_WINNER_COOLDOWN_MS;
        //     reparation_economic_power = castle::get_castle_base_economic_power(castle);
        // };

        // // 5. settle attacker's result immediately
        // // 5.1 soldiers
        // castle::soldiers_survived(castle, attacker_soldiers_left, clock);

        // // 6. update game store, log battle
        // // 6.1 attacker
        // let attacker_id = object::id(castle);
        // castle_admin::log_battle(
        //     attacker_id,
        //     0, // settled immediately
        //     castle_admin::new_economic_reparation(
        //         true,
        //         reparation_economic_power,
        //         current_timestamp,
        //         defender_cooldown
        //     ),
        //     attacker_cooldown,
        //     game_store
        // );
        // // 6.2 defender
        // castle_admin::log_battle(
        //     defender_id,
        //     0, // settled immediately
        //     castle_admin::new_economic_reparation(
        //         false,
        //         reparation_economic_power,
        //         current_timestamp,
        //         defender_cooldown
        //     ),
        //     defender_cooldown,
        //     game_store
        // );

        // // 7. emit event
        // event::emit(CastleBattleLog{
        //     attacker_win: attacker_win,
        //     attacker: attacker_id,
        //     defender: defender_id,
        //     attacker_soldiers_lost: castle::get_castle_soldiers(castle) - attacker_soldiers_left,
        //     defender_soldiers_lost: castle::get_castle_soldiers(target) - defender_soldiers_left,
        //     economic_reparation: reparation_economic_power,
        //     battle_time: current_timestamp,
        //     reparation_end_time: defender_cooldown
        // });
    }

}