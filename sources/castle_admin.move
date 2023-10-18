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
        small_castles: vector<ID>,
        middle_castles: vector<ID>,
        big_castles: vector<ID>,
        battle_field: table::Table<ID, CastleBattleBadge>
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

    /// Module initializer create the only one AdminCap and send it to the publisher
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap{id: object::new(ctx)},
            tx_context::sender(ctx)
        );

        transfer::share_object(
            GameStore{
                id: object::new(ctx),
                small_castles: vector::empty<ID>(),
                middle_castles: vector::empty<ID>(),
                big_castles: vector::empty<ID>(),
                battle_field: table::new<ID, CastleBattleBadge>(ctx)
            }
        );
    }

    public fun record_small_castle(game_store: &mut GameStore, id: ID) {
        vector::push_back(&mut game_store.small_castles, id);
    }

    public fun record_middle_castle(game_store: &mut GameStore, id: ID) {
        vector::push_back(&mut game_store.middle_castles, id);
    }

    public fun record_big_castle(game_store: &mut GameStore, id: ID) {
        vector::push_back(&mut game_store.big_castles, id);
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
}