module move_castle::castle_admin {
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::vector;
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
        big_castles: vector<ID>
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
                big_castles: vector::empty<ID>()
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

    #[test_only]
    public fun create_game_store_for_test(ctx: &mut TxContext): GameStore{
            GameStore{
                id: object::new(ctx),
                small_castles: vector::empty<ID>(),
                middle_castles: vector::empty<ID>(),
                big_castles: vector::empty<ID>()
            }
    }

    #[test_only]
    public fun destroy_game_store_for_test(game_store: GameStore) {
        let GameStore {id, small_castles, middle_castles, big_castles: _} = game_store;
        object::delete(id);
    }
}