module move_castle::castle {

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, utf8, String};
    use sui::event;
    use sui::package;
    use sui::display;

    use move_castle::utils;
    use move_castle::core::{Self, GameStore};

    /// The castle
    struct Castle has key, store {
        id: UID,
        name: String,
        description: String,
        serial_number: u64,
        image_id: u64,
    }

    /// One-Time-Witness for the module
    struct CASTLE has drop {}

    /// Event - castle built
    struct CastleBuilt has copy, drop {
        id: ID,
        owner: address,
    }

    fun init(otw: CASTLE, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"https://movecastle.info/castles/{serial_number}"),
            utf8(b"https://movecastle.info/static/media/castles/{image_id}.png"),
            utf8(b"{description}"),
            utf8(b"https://movecastle.info"),
            utf8(b"Castle Builder"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<Castle>(&publisher, keys, values, ctx);

        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    /// Create new castle
    public entry fun build_castle(size: u64, name_bytes: vector<u8>, desc_bytes: vector<u8>, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        // 1. castle amount check
        assert!(core::allow_new_castle(size, game_store), E_CASTLE_AMOUNT_LIMIT);

        // 2. generate serial number
        let obj_id = object::new(ctx);
        let serial_number = utils::generate_castle_serial_number(size, &mut obj_id);
        let image_id = utils::serial_number_to_image_id(serial_number);
    
        // 3. new castle
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            description: string::utf8(desc_bytes),
            serial_number: serial_number,
            image_id: image_id,
        };

        // 4. new castle game data
        let id = object::uid_to_inner(&castle.id);
        let race = get_castle_race(serial_number);
        core::new_castle(
            id, 
            size,
            race,
            clock::timestamp_ms(clock),
            game_store
        );
        
        // 5. transfer to owner
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

    /// Upgrade castle
    public entry fun upgrade_castle(castle: &mut Castle, game_store: &mut GameStore) {
        core::upgrade_castle(object::id(castle), game_store);
    }

    /// Get castle race
    public fun get_castle_race(serial_number: u64): u64 {
        let race_number = serial_number % 10;
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

    const E_CASTLE_AMOUNT_LIMIT : u64 = 0;

}