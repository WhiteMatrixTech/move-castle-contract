#[allow(unused_variable)]
module move_castle::castle {

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use sui::event;
    use sui::math;
    use sui::table::{Table, Self};
    use sui::dynamic_field;
    
    use move_castle::utils;
    use move_castle::core::{Self, GameStore};

    struct Castle has key, store {
        id: UID,
        name: String,
        description: String,
        serial_number: u64
    }

    /// Event - castle built
    struct CastleBuilt has copy, drop {
        id: ID,
        owner: address,
    }


    /// Create new castle
    public entry fun build_castle(size: u64, name_bytes: vector<u8>, desc_bytes: vector<u8>, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {

        let obj_id = object::new(ctx);
        let serial_number = utils::generate_castle_serial_number(size, &mut obj_id);

        let race = get_castle_race(serial_number);
        let (attack_power, defence_power) = get_initial_attack_defence_power(race);
    
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            description: string::utf8(desc_bytes),
            serial_number: serial_number,
        };

        let total_economic_power = get_castle_total_economic_power(&castle);
        let id = object::uid_to_inner(&castle.id);
        core::new_castle(
            id, 
            size,
            race,
            attack_power,
            defence_power,
            get_initial_economic_power(size),
            total_economic_power,
            clock::timestamp_ms(clock),
            game_store
        );
        
        let owner = tx_context::sender(ctx);
        event::emit(CastleBuilt{id: id, owner: owner});

        transfer::public_transfer(castle, owner);
    }

    /// Consume experience points from the experience pool to upgrade the castle
    public entry fun upgrade_castle(castle: &mut Castle, clock: &Clock, ctx: &mut TxContext) {
        let initial_level = castle.level;
        while (castle.level < MAX_CASTLE_LEVEL) {
            let exp_required_at_current_level = *vector::borrow(&REQUIRED_EXP_LEVELS, castle.level - 1);
            if(castle.experience_pool < exp_required_at_current_level) {
                break
            };

            castle.experience_pool = castle.experience_pool - exp_required_at_current_level;
            castle.level = castle.level + 1;
        };

        if (castle.level > initial_level) {
            event::emit(CastleUpgraded{id: object::uid_to_inner(&castle.id), level: castle.level});
            let (base_economic_power, total_economic_power) = calculate_castle_economic_power(freeze(castle));
            castle.economic.base_power = base_economic_power;
            vector::push_back(&mut castle.economic.power_timestamps, EconomicPowerTimestamp{
                    total_power: total_economic_power,
                    timestamp: clock::timestamp_ms(clock),
                });

            let (attack_power, defence_power) = calculate_castle_base_attack_defence_power(freeze(castle));
            castle.attack_power = attack_power;
            castle.defence_power = defence_power;
        }
    }

    /// Max soldier count per castle - small castle
    const MAX_SOLDIERS_SMALL_CASTLE : u64 = 500;
    /// Max soldier count per castle - middle castle
    const MAX_SOLDIERS_MIDDLE_CASTLE : u64 = 1000;
    /// Max soldier count per castle - big castle
    const MAX_SOLDIERS_BIG_CASTLE : u64 = 2000;

    /// Soldier attack power - human
    const SOLDIER_ATTACK_POWER_HUMAN : u64 = 100;
    /// Soldier defence power - human
    const SOLDIER_DEFENCE_POWER_HUMAN : u64 = 100;
    /// Soldier attack power - elf
    const SOLDIER_ATTACK_POWER_ELF : u64 = 50;
    /// Soldier defence power - elf
    const SOLDIER_DEFENCE_POWER_ELF : u64 = 150;
    /// Soldier attack power - orcs
    const SOLDIER_ATTACK_POWER_ORCS : u64 = 150;
    /// Soldier defence power - orcs
    const SOLDIER_DEFENCE_POWER_ORCS : u64 = 50;
    /// Soldier attack power - goblin
    const SOLDIER_ATTACK_POWER_GOBLIN : u64 = 120;
    /// Soldier defence power - goblin
    const SOLDIER_DEFENCE_POWER_GOBLIN : u64 = 80;
    /// Soldier attack power - undead
    const SOLDIER_ATTACK_POWER_UNDEAD : u64 = 120;
    /// Soldier defence power - undead
    const SOLDIER_DEFENCE_POWER_UNDEAD : u64 = 80;

    /// Experience points required for castle level 2 - 10
    const REQUIRED_EXP_LEVELS : vector<u64> = vector[100, 150, 225, 338, 507, 760, 1140, 1709, 2563];
    
    /// Max castle level
    const MAX_CASTLE_LEVEL : u64 = 10;

    /// Each soldier's price
    const SOLDIER_PRICE : u64 = 100;

    /// Error - insufficient treasury for recruiting soldiers
    const E_INSUFFICIENT_TREASURY_FOR_SOLDIERS : u64 = 0;
    /// Error - soldiers exceed limit
    const E_SOLDIERS_EXCEED_LIMIT : u64 = 1;

    // Get initial economic power by castle size
    fun get_initial_economic_power(size: u64): u64 {
        let power = INITIAL_ECONOMIC_POWER_SMALL_CASTLE;
        if (size == CASTLE_SIZE_MIDDLE) {
            power = INITIAL_ECONOMIC_POWER_MIDDLE_CASTLE;
        };
        if (size == CASTLE_SIZE_BIG) {
            power = INITIAL_ECONOMIC_POWER_BIG_CASTLE;
        };
        power
    }

    /// Get castle ID
    public fun get_castle_id(castle: &Castle): ID {
        object::uid_to_inner(&castle.id)
    }

    /// Get castle level
    public fun get_castle_level(castle: &Castle): u64 {
        castle.level
    }

    /// Get castle soldiers
    public fun get_castle_soldiers(castle: &Castle): u64 {
        castle.soldiers
    }

    /// Get castle serial number
    public fun get_castle_serial_number(castle: &Castle): u64 {
        castle.serial_number
    }

    /// Get castle race
    public fun get_castle_race(serial_number: u64): u64 {
        let race_number = serial_number / 10 % 10;
        if (race_number >= 5) {
            race_number = race_number - 5;
        };
        race_number
    }

    /// Get castle size
    fun get_castle_size(serial_number: u64): u64 {
        serial_number / 10000000
    }

    /// Is castle small
    public fun is_castle_small(castle: &Castle): bool {
        get_castle_size(castle.serial_number) == CASTLE_SIZE_SMALL
    }

    /// Is castle middle
    public fun is_castle_middle(castle: &Castle): bool {
        get_castle_size(castle.serial_number) == CASTLE_SIZE_MIDDLE
    }

    /// Is castle big
    public fun is_castle_big(castle: &Castle): bool {
        get_castle_size(castle.serial_number) == CASTLE_SIZE_BIG
    }

    /// Get castle battle cooldown
    public fun get_castle_battle_cooldown(castle: &Castle): u64 {
        castle.battle_cooldown
    }

    /// Castle's base attack power plus castle's all soldiers' attack power
    public fun get_castle_total_attack_power(castle: &Castle): u64 {
        let (soldiers_attack_power, _) = get_castle_soldiers_attack_defence_power(castle);
        castle.attack_power + soldiers_attack_power
    }

    /// Castle's base defence power plus castle's all soldiers' defence power
    public fun get_castle_total_defence_power(castle: &Castle): u64 {
        let (_, soldiers_defence_power) = get_castle_soldiers_attack_defence_power(castle);
        castle.defence_power + soldiers_defence_power
    }

    /// Castle's soldiers' attack power and defence power
    fun get_castle_soldiers_attack_defence_power(castle: &Castle): (u64, u64) {
        let (soldier_attack_power, soldier_defence_power) = get_castle_soldier_attack_defence_power(castle);
        (castle.soldiers * soldier_attack_power, castle.soldiers * soldier_defence_power)
    }

     /// Castle's single soldier's attack power and defence power
    public fun get_castle_soldier_attack_defence_power(castle: &Castle): (u64, u64) {
        let race = get_castle_race(castle.serial_number);

        let soldier_attack_power;
        let soldier_defence_power;
        if (race == CASTLE_RACE_HUMAN) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_HUMAN;
            soldier_defence_power = SOLDIER_DEFENCE_POWER_HUMAN;
        } else if (race == CASTLE_RACE_ELF) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_ELF;
            soldier_defence_power = SOLDIER_DEFENCE_POWER_ELF;
        } else if (race == CASTLE_RACE_ORCS) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_ORCS;
            soldier_defence_power = SOLDIER_DEFENCE_POWER_ORCS;
        } else if (race == CASTLE_RACE_GOBLIN) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_GOBLIN;
            soldier_defence_power = SOLDIER_DEFENCE_POWER_GOBLIN;
        } else if (race == CASTLE_RACE_UNDEAD) {
            soldier_attack_power = SOLDIER_ATTACK_POWER_UNDEAD;
            soldier_defence_power = SOLDIER_DEFENCE_POWER_UNDEAD;
        } else {
            abort 0
        };

        (soldier_attack_power, soldier_defence_power)
    }

    /// Castle's base economic power plus castle's all soldier's economic power
    public fun get_castle_total_economic_power(castle: &Castle): u64 {
        castle.economic.base_power + castle.soldiers * SOLDIER_ECONOMIC_POWER
    }

    /// Castle's base economic power 
    public fun get_castle_base_economic_power(castle: &Castle): u64 {
        castle.economic.base_power
    }

    


    /// Everytime castle's economic power mutates, need to mark economic mutate timestamp
    fun mutate_castle_economy(castle: &mut Castle, clock: &Clock) {
        let current_total_power = get_castle_total_economic_power(castle);
        let current_timestamp = clock::timestamp_ms(clock);
        vector::push_back(&mut castle.economic.power_timestamps, EconomicPowerTimestamp {
            total_power: current_total_power, 
            timestamp: current_timestamp,
        });
    }

    /// Settle castle's treasury, including victory rewards and defeat penalties
    public entry fun settle_castle_treasury(castle: &mut Castle, clock: &Clock, ctx: &mut TxContext) {
        // 1. TODO find the castle's economic mutate times in battle results

        // 2. calculate economic benefits period by period
        if (!vector::is_empty(&castle.economic.power_timestamps)) {
            let start = vector::remove(&mut castle.economic.power_timestamps, 0);
            while (!vector::is_empty(&castle.economic.power_timestamps)) {
                let middle = vector::remove(&mut castle.economic.power_timestamps, 0);
                let benefit = math::divide_and_round_up((middle.timestamp - start.timestamp) * start.total_power, 60u64 * 1000u64);
                castle.economic.treasury = castle.economic.treasury + benefit;
                start = middle;
            };

            let current_total_power = get_castle_total_economic_power(castle);
            let current_timestamp = clock::timestamp_ms(clock);
            let benefit = math::divide_and_round_up((current_timestamp - start.timestamp) * start.total_power, 60u64 * 1000u64);
            castle.economic.treasury = castle.economic.treasury + benefit;
            vector::push_back(&mut castle.economic.power_timestamps, EconomicPowerTimestamp {
                total_power: current_total_power, 
                timestamp: current_timestamp,
            });
        };
    }


    /// Transfer castle
    public entry fun transfer_castle(castle: Castle, to: address) {
        transfer::transfer(castle, to);
    }

    /// Get castle soldier limit by castle size
    fun get_castle_soldier_limit(serial_number: u64) : u64 {
        let size = get_castle_size(serial_number);
        let soldier_limit = MAX_SOLDIERS_SMALL_CASTLE;
        if (size == CASTLE_SIZE_MIDDLE) {
            soldier_limit = MAX_SOLDIERS_MIDDLE_CASTLE;
        };
        if (size == CASTLE_SIZE_BIG) {
            soldier_limit = MAX_SOLDIERS_BIG_CASTLE;
        };
        soldier_limit
    }

    /// Castle uses treasury to recruit soldiers
    public entry fun recruit_soldiers (castle: &mut Castle, count: u64, clock: &Clock, ctx: &mut TxContext) {
        let final_soldiers = castle.soldiers + count;
        assert!(final_soldiers <= get_castle_soldier_limit(castle.serial_number), E_SOLDIERS_EXCEED_LIMIT);

        let total_soldier_price = SOLDIER_PRICE * count;
        assert!(castle.economic.treasury >= total_soldier_price, E_INSUFFICIENT_TREASURY_FOR_SOLDIERS);

        castle.economic.treasury = castle.economic.treasury - total_soldier_price;
        castle.soldiers = final_soldiers;

        mutate_castle_economy(castle, clock);
    }

    /// Add castle's treasury directly
    public fun add_castle_treasury(castle: &mut Castle, treasury: u64) {
        castle.economic.treasury = castle.economic.treasury + treasury;
    }

    public fun has_battle_ticket(castle: &Castle): bool {
        castle.has_battle_ticket
    }

    public fun soldiers_survived(castle: &mut Castle, soldier_count: u64, clock: &Clock) {
        castle.soldiers = soldier_count;
        mutate_castle_economy(castle, clock);
    }

    public fun has_race_advantage(c1: &Castle, c2: &Castle): bool {
        let c1_race = get_castle_race(c1.serial_number);
        let c2_race = get_castle_race(c2.serial_number);

        let has;
        if (c1_race == c2_race) {
            has = false;
        } else if (c1_race < c2_race) {
            has = (c2_race - c1_race) == 1;
        } else {
            has = (c1_race - c2_race) == 4;
        };

        has
    }

    public fun add_dynamic_field<T: store>(castle: &mut Castle, name: vector<u8>, field: T) {
        dynamic_field::add(&mut castle.id, name, field);
    }

    public fun remove_dynamic_field<T: store>(castle: &mut Castle, name: vector<u8>) : T{
        dynamic_field::remove(&mut castle.id, name)
    }

    #[test_only]
    /// Only for test
    public fun test_update_castle(castle: &mut Castle) {
        castle.experience_pool = castle.experience_pool + 10;
        castle.economic.treasury = castle.economic.treasury + 10;
    }

    #[test_only]
    public fun add_castle_exp(castle: &mut Castle, exp: u64) {
        castle.experience_pool = castle.experience_pool + exp;
    }

    #[test_only]
    public fun set_castle_level(castle: &mut Castle, level: u64) {
        castle.level = level;
    }

    #[test_only]
    public fun set_castle_exp(castle: &mut Castle, exp: u64) {
        castle.experience_pool = exp;
    }

    #[test_only]
    public fun set_castle_treasury(castle: &mut Castle, treasury: u64) {
        castle.economic.treasury = treasury;
    }

    #[test_only]
    public fun get_castle_exp(castle: &Castle): u64 {
        castle.experience_pool
    }

    public entry fun test_only_set_castle_exp(castle: &mut Castle, exp: u64, ctx: &mut TxContext) {
        castle.experience_pool = exp;
    }

    public entry fun test_only_set_castle_treasury(castle: &mut Castle, treasury: u64, ctx: &mut TxContext) {
        castle.economic.treasury = treasury;
    }

}