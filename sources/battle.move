module move_castle::battle {
    use sui::clock::{Self, Clock};
    use sui::math;
    use sui::event;

    use move_castle::castle::Castle;
    use move_castle::core::{Self, GameStore};
    
    /// Battle event
    public struct CastleBattleLog has store, copy, drop {
        attacker: ID,
        winner: ID,
        loser: ID,
        winner_soldiers_lost: u64,
        loser_soldiers_lost: u64,
        reparation_economic_power: u64,
        battle_time: u64,
        reparation_end_time: u64
    }

    entry fun battle(castle: &Castle, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        // 1. random out a target
        let attacker_id = object::id(castle);
        let target_id = core::random_battle_target(attacker_id, game_store, ctx);

        // 2. castle data
        let (attacker, defender) = core::fetch_castle_data(attacker_id, target_id, game_store);

        // 3. check battle cooldown
        let current_timestamp = clock::timestamp_ms(clock);
        assert!(core::get_castle_battle_cooldown(&attacker) < current_timestamp, EBattleCooldown);
        assert!(core::get_castle_battle_cooldown(&defender) < current_timestamp, EBattleCooldown);

        // 4. battle
        // 4.1 calculate total attack power and defense power
        let mut attack_power = core::get_castle_total_attack_power(&attacker);
        let mut defense_power = core::get_castle_total_defense_power(&defender);
        if (core::has_race_advantage(&attacker, &defender)) {
            attack_power = math::divide_and_round_up(attack_power * 15, 10)
        } else if (core::has_race_advantage(&defender, &attacker)) {
            defense_power = math::divide_and_round_up(defense_power * 15, 10)
        };

        // 4.2 determine win lose
        let (mut winner, mut loser);
        if (attack_power > defense_power) {
            winner = attacker;
            loser = defender;
        } else {
            winner = defender;
            loser = attacker;
        };
        let winner_id = core::get_castle_id(&winner);
        let loser_id = core::get_castle_id(&loser);

        // 5. battle settlement   
        // 5.1 setting winner
        core::settle_castle_economy_inner(clock, &mut winner);
        let winner_solders_total_defense_power = core::get_castle_total_soldiers_defense_power(&winner);
        let loser_solders_total_attack_power = core::get_castle_total_soldiers_attack_power(&loser);
        let winner_soldiers_left;
        if (winner_solders_total_defense_power > loser_solders_total_attack_power) {
            let (_, winner_soldier_defense_power) = core::get_castle_soldier_attack_defense_power(core::get_castle_race(&winner));
            winner_soldiers_left = math::divide_and_round_up(winner_solders_total_defense_power - loser_solders_total_attack_power, winner_soldier_defense_power);
        } else {
            winner_soldiers_left = 0;
        };
        let winner_soldiers_lost = core::get_castle_soldiers(&winner) - winner_soldiers_left;
        let winner_exp_gain = core::battle_winner_exp(&winner);
        let reparation_economic_power = core::get_castle_economic_base_power(&loser);
        core::battle_settlement_save_castle_data(
            game_store,
            winner, 
            true, 
            current_timestamp + BATTLE_WINNER_COOLDOWN_MS,
            reparation_economic_power,
            current_timestamp,
            current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME,
            winner_soldiers_left,
            winner_exp_gain
        );

        // 5.2 settling loser
        core::settle_castle_economy_inner(clock, &mut loser);
        let loser_soldiers_left = 0;
        let loser_soldiers_lost = core::get_castle_soldiers(&loser) - loser_soldiers_left;
        core::battle_settlement_save_castle_data(
            game_store,
            loser, 
            false, 
            current_timestamp + BATTLE_LOSER_COOLDOWN_MS,
            reparation_economic_power,
            current_timestamp,
            current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME,
            loser_soldiers_left,
            0
        );

        // 6. emit event
        event::emit(CastleBattleLog {
            attacker: attacker_id,
            winner: winner_id,
            loser: loser_id,
            winner_soldiers_lost: winner_soldiers_lost,
            loser_soldiers_lost: loser_soldiers_lost,
            reparation_economic_power: reparation_economic_power,
            battle_time: current_timestamp,
            reparation_end_time: current_timestamp + BATTLE_LOSER_ECONOMIC_PENALTY_TIME
        });
    }

    const BATTLE_WINNER_COOLDOWN_MS : u64 = 30 * 1000; // 30 sec
    const BATTLE_LOSER_ECONOMIC_PENALTY_TIME : u64 = 2 * 60 * 1000; // 2 min
    const BATTLE_LOSER_COOLDOWN_MS : u64 = 2 * 60 * 1000; // 2 min

    /// One or both sides of the battle are in battle cooldown
    const EBattleCooldown: u64 = 0;
}