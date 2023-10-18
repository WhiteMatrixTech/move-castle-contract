module move_castle::castle_admin {
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::vector;
    use sui::table;
    use move_castle::utils;

    /// Capability to modify game settings
    struct AdminCap has key {
        id: UID
    }

    /// Holding game info
    struct GameStore has key, store {
        id: UID,
        small_castle_count: u64,
        middle_castles_count: u64,
        big_castles_count: u64,
        castles: table::Table<ID, CastleData>
        battle_field: table::Table<ID, CastleBattleBadge>
    }

    /// Holding castle info
    struct CastleData has store {
        size: u64,
        race: u64,
        level: u64,
        attack_power: u64,
        defence_power: u64,
        soldiers: u64,
        expirence_pool: u64,
        economy: Economy,
    }

    struct Economy {
        treasury: u64,
        settle_time: u64,
        soldier_buff: EconomicBuff,
        battle_buff: vector<EconomicBuff>
    }

    struct EconomicBuff has store, drop {
        debuff: bool,
        power: u64,
        start: u64,
        end: u64
    }

    /// Holding a castle's battle info
    struct CastleBattleBadge has store, drop {
        cooldown: u64,
        unsettled_soldier_lost: u64,
        unsettled_economic_reparation: vector<EconomicReparation>
    }

    struct EconomicReparation has store, drop {
        recipient: bool,
        economic_power: u64,
        start_time: u64,
        end_time: u64
    }

    /// Event - castle upgraded
    struct CastleUpgraded has copy, drop {
        id: ID,
        level: u64,
    }

    /// Module initializer create the only one AdminCap and send it to the publisher
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap{id: object::new(ctx)},
            tx_context::sender(ctx)
        );

        transfer::share_object(
            GameStore{
                id: object::new(ctx),
                small_castle_count: 0,
                middle_castles_count: 0,
                big_castles_count: 0,
                castles: table::new<ID, CastleData>(ctx)
                battle_field: table::new<ID, CastleBattleBadge>(ctx)
            }
        );
    }

    public fun new_castle(id: ID,
                            size: u64,
                            race: u64,
                            attack_power: u64,
                            defence_power: u64,
                            base_economic_power: u64,
                            current_timestamp: u64,
                            game_store: &mut GameStore) {

        let castle_data = CastleData {
            size: size,
            race: race,
            level: 1,
            attack_power: attack_power,
            defence_power: defence_power,
            soldiers: INITIAL_SOLDIERS,
            expirence_pool: 0,
            economy: Economy {
                treasury: 0,
                settle_time: 0,
                soldier_buff: EconomicBuff {
                    debuff: false,
                    power: SOLDIER_ECONOMIC_POWER * INITIAL_SOLDIERS,
                    start: current_timestamp,
                    end: 0
                },
                battle_buff: vector::empty<EconomicBuff>();
            }
        };

        table::add(&mut game_store.castles, id, castle_data);

        if (size == CASTLE_SIZE_SMALL) {
            game_store.small_castle_count = game_store.small_castle_count + 1;
        } else if (size == CASTLE_SIZE_MIDDLE) {
            game_store.middle_castle_count = game_store.middle_castle_count + 1;
        } else if (size == CASTLE_SIZE_BIG) {
            game_store.big_castle_count = game_store.big_castle_count + 1;
        } else {
            abort 0
        };
    }

    /// Consume experience points from the experience pool to upgrade the castle
    public fun upgrade_castle(id: ID, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        let castle_data = table::borrow_mut<CastleData>(game_store, id);

        let initial_level = castle_data.level;
        while (castle_data.level < MAX_CASTLE_LEVEL) {
            let exp_required_at_current_level = *vector::borrow(&REQUIRED_EXP_LEVELS, castle_data.level - 1);
            if(castle_data.experience_pool < exp_required_at_current_level) {
                break
            };

            castle_data.experience_pool = castle_data.experience_pool - exp_required_at_current_level;
            castle_data.level = castle_data.level + 1;
        };

        if (castle_data.level > initial_level) {
            event::emit(CastleUpgraded{id: object::uid_to_inner(&id), level: castle_data.level});
            let (base_economic_power, total_economic_power) = calculate_castle_economic_power(freeze(castle_data));
            castle_data.economic.base_power = base_economic_power;

            let (attack_power, defence_power) = calculate_castle_base_attack_defence_power(freeze(castle_data));
            castle_data.attack_power = attack_power;
            castle_data.defence_power = defence_power;
        }
    }

    /// Calculate castle's base economic power and total economic power
    fun calculate_castle_economic_power(castle_data: &CastleData): (u64, u64) {
        let initial_base_power;
        if (castle_data.size == CASTLE_SIZE_SMALL) {
            initial_base_power = INITIAL_ECONOMIC_POWER_SMALL_CASTLE;
        } else if (castle_data.size == CASTLE_SIZE_MIDDLE) {
            initial_base_power = INITIAL_ECONOMIC_POWER_MIDDLE_CASTLE;
        } else if (castle_data.size == CASTLE_SIZE_BIG) {
            initial_base_power = INITIAL_ECONOMIC_POWER_BIG_CASTLE;
        } else {
            abort 0
        };

        let level = get_castle_level(castle);
        let base_power = math::divide_and_round_up(initial_base_power * math::pow(12, ((level - 1) as u8)), 100);
        let total_power = base_power + castle.soldiers * SOLDIER_ECONOMIC_POWER;
        (base_power, total_power)
    }

    /// Calculate castle's base attack power and base defence power based on level
    /// base attack power = (castle_size_factor * initial_attack_power * (1.2 ^ (level - 1)))
    /// base defence power = (castle_size_factor * initial_defence_power * (1.2 ^ (level - 1)))
    fun calculate_castle_base_attack_defence_power(castle_data: &CastleData): (u64, u64) {
        let castle_size_factor = get_castle_size_factor(castle_data.size);
        let (initial_attack, initial_defence) = get_initial_attack_defence_power(castle_data.race);
        let attack_power = math::divide_and_round_up(castle_size_factor * initial_attack * math::pow(12, ((castle_data.level - 1) as u8)), 100);
        let defence_power = math::divide_and_round_up(castle_size_factor * initial_defence * math::pow(12, ((castle_data.level - 1) as u8)), 100);
        (attack_power, defence_power)
    }
    
    /// Get castle size factor
    fun get_castle_size_factor(castle_size: u64): u64 {
        let factor;
        if (castle_size == CASTLE_SIZE_SMALL) {
            factor = CASTLE_SIZE_FACTOR_SMALL;
        } else if (castle_size == CASTLE_SIZE_MIDDLE) {
            factor = CASTLE_SIZE_FACTOR_MIDDLE;
        } else if (castle_size == CASTLE_SIZE_BIG) {
            factor = CASTLE_SIZE_FACTOR_BIG;
        } else {
            abort 0
        };
        factor
    }

    /// Get initial attack power and defence power by race
    fun get_initial_attack_defence_power(race: u64): (u64, u64) {
        let (attack, defence);

        if (race == CASTLE_RACE_HUMAN) {
            (attack, defence) = (INITIAL_ATTCK_POWER_HUMAN, INITIAL_DEFENCE_POWER_HUMAN);
        } else if (race == CASTLE_RACE_ELF) {
            (attack, defence) = (INITIAL_ATTCK_POWER_ELF, INITIAL_DEFENCE_POWER_ELF);
        } else if (race == CASTLE_RACE_ORCS) {
            (attack, defence) = (INITIAL_ATTCK_POWER_ORCS, INITIAL_DEFENCE_POWER_ORCS);
        } else if (race == CASTLE_RACE_GOBLIN) {
            (attack, defence) = (INITIAL_ATTCK_POWER_GOBLIN, INITIAL_DEFENCE_POWER_GOBLIN);
        } else if (race == CASTLE_RACE_UNDEAD) {
            (attack, defence) = (INITIAL_ATTCK_POWER_UNDEAD, INITIAL_DEFENCE_POWER_UNDEAD);
        } else {
            abort 0
        };

        (attack, defence)
    }

    public fun random_battle_target(from_castle: &ID, game_store: &mut GameStore, ctx: &mut TxContext): ID {
        let length_small = vector::length(&game_store.small_castles);
        let length_middle = vector::length(&game_store.middle_castles);
        let length_big = vector::length(&game_store.big_castles);
        let total_length = (length_small + length_middle + length_big);
        assert!(total_length > 1, 0);

        let random_index = utils::random_in_range(total_length, ctx);
        let target;
        if (random_index < length_small) {
            target = vector::borrow(&game_store.small_castles, random_index);
        } else if (random_index < length_small + length_middle) {
            random_index = random_index - length_small;
            target = vector::borrow(&game_store.middle_castles, random_index);
        } else {
            random_index = random_index - length_small - length_middle;
            target = vector::borrow(&game_store.big_castles, random_index);
        };

        while (object::id_to_address(from_castle) == object::id_to_address(target)) {
            // redo random until not equals
            random_index = utils::random_in_range(total_length, ctx);
            if (random_index < length_small) {
                target = vector::borrow(&game_store.small_castles, random_index);
            } else if (random_index < length_small + length_middle) {
                random_index = random_index - length_small;
                target = vector::borrow(&game_store.middle_castles, random_index);
            } else {
                random_index = random_index - length_small - length_middle;
                target = vector::borrow(&game_store.big_castles, random_index);
            };
        };
        
        object::id_from_address(object::id_to_address(target))
    }

    public fun log_battle(id: ID,
                          soldier_lost: u64,
                          economic_reparation: EconomicReparation,
                          cooldown: u64,
                          game_store: &mut GameStore) {
        if (!table::contains(&game_store.battle_field, id)) {
            let economic_reparations = vector::empty<EconomicReparation>();
            vector::push_back(&mut economic_reparations, economic_reparation);
            table::add(&mut game_store.battle_field, id, CastleBattleBadge{
                    cooldown: cooldown, 
                    unsettled_soldier_lost: soldier_lost,
                    unsettled_economic_reparation: economic_reparations
                });
        } else {
            let badge = table::borrow_mut<ID, CastleBattleBadge>(&mut game_store.battle_field, id);
            badge.cooldown = cooldown;
            badge.unsettled_soldier_lost = badge.unsettled_soldier_lost + soldier_lost;
            vector::push_back(&mut badge.unsettled_economic_reparation, economic_reparation);
        };
    }

    public fun new_economic_reparation(recipient: bool,
                                        economic_power: u64,
                                        start_time: u64,
                                        end_time: u64): EconomicReparation {
        EconomicReparation{
                recipient: recipient,
                economic_power: economic_power,
                start_time: start_time,
                end_time: end_time
        }
    }

    #[test_only]
    public fun create_game_store_for_test(ctx: &mut TxContext): GameStore{
            GameStore{
                id: object::new(ctx),
                small_castles: vector::empty<ID>(),
                middle_castles: vector::empty<ID>(),
                big_castles: vector::empty<ID>(),
                battle_field: table::new<ID, CastleBattleBadge>(ctx)
            }
    }

    #[test_only]
    public fun destroy_game_store_for_test(game_store: GameStore) {
        let GameStore {id, small_castles, middle_castles, big_castles:_, battle_field: table} = game_store;
        table::drop(table);
        object::delete(id);
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

    /// Experience points required for castle level 2 - 10
    const REQUIRED_EXP_LEVELS : vector<u64> = vector[100, 150, 225, 338, 507, 760, 1140, 1709, 2563];
    
    /// Max castle level
    const MAX_CASTLE_LEVEL : u64 = 10;

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

    /// Initial defence power - human castle
    const INITIAL_DEFENCE_POWER_HUMAN : u64 = 1000;
    /// Initial defence power - elf castle
    const INITIAL_DEFENCE_POWER_ELF : u64 = 1500;
    /// Initial defence power - orcs castle
    const INITIAL_DEFENCE_POWER_ORCS : u64 = 500;
    /// Initial defence power - goblin castle
    const INITIAL_DEFENCE_POWER_GOBLIN : u64 = 800;
    /// Initial defence power - undead castle
    const INITIAL_DEFENCE_POWER_UNDEAD : u64 = 1200;

    /// Initial economic power - small castle
    const INITIAL_ECONOMIC_POWER_SMALL_CASTLE : u64 = 100;
    /// Initial economic power - middle castle
    const INITIAL_ECONOMIC_POWER_MIDDLE_CASTLE : u64 = 150;
    /// Initial economic power - big castle
    const INITIAL_ECONOMIC_POWER_BIG_CASTLE : u64 = 250;

    /// Initial soldiers
    const INITIAL_SOLDIERS : u64 = 10;
    /// Soldier economic power
    const SOLDIER_ECONOMIC_POWER : u64 = 1;
}