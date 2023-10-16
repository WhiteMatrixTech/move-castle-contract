#[allow(unused_variable)]
module move_castle::castle {

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use move_castle::utils;
    use sui::event;
    use sui::math;
    use sui::table::{Table, Self};

    struct Castle has key, store {
        id: UID,
        name: String,
        serial_number: u64,
        level: u64,
        attack_power: u64,
        defence_power: u64,
        experience_pool: u64,
        economic: Economic,
        solders: u64,
    }

    struct Economic has store {
        treasury: u64,
        base_power: u64,
        last_settle_time: u64,
    }

    /// Event - castle built
    struct CastleBuilt has copy, drop {
        id: ID,
        owner: address,
    }

    /// Event - castle upgraded
    struct CastleUpgraded has copy, drop {
        id: ID,
        level: u64,
    }

    /// Castle size - small
    const CASTLE_SIZE_SMALL : u64 = 1;
    /// Castle size - middle
    const CASTLE_SIZE_MIDDLE : u64 = 2;
    /// Castle size - big
    const CASTLE_SIZE_BIG : u64 = 3;

    /// Castle race - human
    const CASTLE_RACE_HUMAN : u64 = 0;
    /// Castle race - elf
    const CASTLE_RACE_ELF : u64 = 1;
    /// Castle race - orcs
    const CASTLE_RACE_ORCS : u64 = 2;
    /// Castle race - goblin
    const CASTLE_RACE_GOBLIN : u64 = 3;
    /// Castle race - undead
    const CASTLE_RACE_UNDEAD : u64 = 4;

    /// Max soldier count per castle - small castle
    const MAX_SOLDIERS_SMALL_CASTLE : u64 = 500;
    /// Max soldier count per castle - middle castle
    const MAX_SOLDIERS_MIDDLE_CASTLE : u64 = 1000;
    /// Max soldier count per castle - big castle
    const MAX_SOLDIERS_BIG_CASTLE : u64 = 2000;

    /// Castle size factor - small
    const CASTLE_SIZE_FACTOR_SMALL : u64 = 2;
    /// Castle size factor - middle
    const CASTLE_SIZE_FACTOR_MIDDLE : u64 = 3;
    /// Castle size factor - big
    const CASTLE_SIZE_FACTOR_BIG : u64 = 5;

    /// Initial attack power - human castle
    const INITIAL_ATTCK_POWER_HUMAN : u64 = 1000;
    /// Initial attack power - elf castle
    const INITIAL_ATTCK_POWER_ELF : u64 = 500;
    /// Initial attack power - orcs castle
    const INITIAL_ATTCK_POWER_ORCS : u64 = 1500;
    /// Initial attack power - goblin castle
    const INITIAL_ATTCK_POWER_GOBLIN : u64 = 1200;
    /// Initial attack power - undead castle
    const INITIAL_ATTCK_POWER_UNDEAD : u64 = 800;

    /// Initial defenceDEFENCE power - human castle
    const INITIAL_DEFENCE_POWER_HUMAN : u64 = 1000;
    /// Initial defence power - elf castle
    const INITIAL_DEFENCE_POWER_ELF : u64 = 1500;
    /// Initial defence power - orcs castle
    const INITIAL_DEFENCE_POWER_ORCS : u64 = 500;
    /// Initial defence power - goblin castle
    const INITIAL_DEFENCE_POWER_GOBLIN : u64 = 800;
    /// Initial defence power - undead castle
    const INITIAL_DEFENCE_POWER_UNDEAD : u64 = 1200;

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

    /// Create new castle
    public entry fun build_castle(size: u64, name_bytes: vector<u8>, clock: &Clock, ctx: &mut TxContext) {
        let castle_economic = Economic {
            treasury: 0,
            base_power: 1,
            last_settle_time: clock::timestamp_ms(clock),
        };

        let obj_id = object::new(ctx);
        let serial_number = utils::generate_castle_serial_number(size, &mut obj_id);

        let race = get_castle_race(serial_number);
        let (attack_power, defence_power) = get_initial_attack_defence_power(race);
    
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            serial_number: serial_number,
            level: 1,
            attack_power: attack_power,
            defence_power: defence_power,
            experience_pool: 0,
            economic: castle_economic,
            solders: 10,
        };
        
        let owner = tx_context::sender(ctx);
        event::emit(CastleBuilt{id: object::uid_to_inner(&castle.id), owner: owner});
        transfer::public_transfer(castle, owner);
    }

    /// Get initial attack power and defence power by race
    fun get_initial_attack_defence_power(race: u64): (u64, u64) {
        let (attack, defence) = (INITIAL_ATTCK_POWER_HUMAN, INITIAL_DEFENCE_POWER_HUMAN);
        if (race == CASTLE_RACE_ELF) {
            (attack, defence) = (INITIAL_ATTCK_POWER_ELF, INITIAL_DEFENCE_POWER_ELF);
        };
        if (race == CASTLE_RACE_ORCS) {
            (attack, defence) = (INITIAL_ATTCK_POWER_ORCS, INITIAL_DEFENCE_POWER_ORCS);
        };
        if (race == CASTLE_RACE_GOBLIN) {
            (attack, defence) = (INITIAL_ATTCK_POWER_GOBLIN, INITIAL_DEFENCE_POWER_GOBLIN);
        };
        if (race == CASTLE_RACE_UNDEAD) {
            (attack, defence) = (INITIAL_ATTCK_POWER_UNDEAD, INITIAL_DEFENCE_POWER_UNDEAD);
        };
        (attack, defence)
    }

    /// Get castle level
    public fun get_castle_level(castle: &Castle): u64 {
        castle.level
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
    public fun get_castle_size(serial_number: u64): u64 {
        serial_number / 10000000
    }

    /// Consume experience points from the experience pool to upgrade the castle
    public entry fun upgrade_castle(castle: &mut Castle, ctx: &mut TxContext) {
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
            let (attack_power, defence_power) = calculate_castle_base_attack_defence_power(freeze(castle));
            castle.attack_power = attack_power;
            castle.defence_power = defence_power;
        }
    }

    /// Calculate castle's base attack power and base defence power based on level
    /// base attack power = (castle_size_factor * initial_attack_power * (1.2 ^ (level - 1)))
    /// base defence power = (castle_size_factor * initial_defence_power * (1.2 ^ (level - 1)))
    fun calculate_castle_base_attack_defence_power(castle: &Castle): (u64, u64) {
        let castle_size_factor = get_castle_size_factor(castle.serial_number);
        let (initial_attack, initial_defence) = get_initial_attack_defence_power(get_castle_race(castle.serial_number));
        let attack_power = math::divide_and_round_up(castle_size_factor * initial_attack * math::pow(12, ((castle.level - 1) as u8)), 100);
        let defence_power = math::divide_and_round_up(castle_size_factor * initial_defence * math::pow(12, ((castle.level - 1) as u8)), 100);
        (attack_power, defence_power)
    }

    /// Get castle size factor
    fun get_castle_size_factor(serial_number: u64): u64 {
        let castle_size = get_castle_size(serial_number);
        let factor = CASTLE_SIZE_FACTOR_SMALL;
        if (castle_size == CASTLE_SIZE_MIDDLE) {
            factor = CASTLE_SIZE_FACTOR_MIDDLE;
        };
        if (castle_size == CASTLE_SIZE_BIG) {
            factor = CASTLE_SIZE_FACTOR_BIG;
        };
        factor
    }

    /// Settle castle's treasury, including victory rewards and defeat penalties
    public entry fun settle_castle_treasury(castle: &mut Castle, clock: &Clock, ctx: &mut TxContext) {

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
    public entry fun recruit_soldiers (castle: &mut Castle, count: u64, ctx: &mut TxContext) {
        let final_soldiers = castle.solders + count;
        assert!(final_soldiers <= get_castle_soldier_limit(castle.serial_number), E_SOLDIERS_EXCEED_LIMIT);

        let total_soldier_price = SOLDIER_PRICE * count;
        assert!(castle.economic.treasury >= total_soldier_price, E_INSUFFICIENT_TREASURY_FOR_SOLDIERS);

        castle.economic.treasury = castle.economic.treasury - total_soldier_price;
        castle.solders = final_soldiers;
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
    public fun add_castle_treasury(castle: &mut Castle, treasury: u64) {
        castle.economic.treasury = castle.economic.treasury + treasury;
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

}