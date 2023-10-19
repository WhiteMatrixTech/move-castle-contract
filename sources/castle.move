module move_castle::castle {

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use sui::event;

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
    
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            description: string::utf8(desc_bytes),
            serial_number: serial_number,
        };

        let id = object::uid_to_inner(&castle.id);
        let race = get_castle_race(serial_number);
        core::new_castle(
            id, 
            size,
            race,
            clock::timestamp_ms(clock),
            game_store
        );
        
        let owner = tx_context::sender(ctx);
        event::emit(CastleBuilt{id: id, owner: owner});

        transfer::public_transfer(castle, owner);
    }

    /// Settle castle's economy
    public entry fun settle_castle_economy(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore) {
        core::settle_castle_economy(object::id(castle), clock, game_store);
    }

    /// Transfer castle
    public entry fun transfer_castle(castle: Castle, to: address) {
        transfer::transfer(castle, to);
    }

    /// Castle uses treasury to recruit soldiers
    public entry fun recruit_soldiers (castle: &mut Castle, count: u64, clock: &Clock, game_store: &mut GameStore) {
        core::recruit_soldiers(object::id(castle), count, clock, game_store);
    }

    /// Get castle race
    public fun get_castle_race(serial_number: u64): u64 {
        let race_number = serial_number / 10 % 10;
        if (race_number >= 5) {
            race_number = race_number - 5;
        };
        race_number
    }

    public entry fun test_set_exp(castle: &mut Castle, exp: u64, game_store: &mut GameStore) {
        core::test_set_exp(object::id(castle), exp, game_store);
    }

    public entry fun test_clear_battle_cooldown(castle: &mut Castle, game_store: &mut GameStore) {
        core::test_clear_battle_cooldown(object::id(castle), game_store);
    }

}