module move_castle::castle {

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use move_castle::utils;

    struct Castle has key, store {
        id: UID,
        name: String,
        serial_number: u64,
        level: u64,
        attack_power: u64,
        defence_power: u64,
        experience_pool: u64,
        economic: Economic,
    }

    struct Economic has store {
        treasury: u64,
        base_power: u64,
        last_settle_time: u64,
    }

    /// Castle size - small
    const CASTLE_SIZE_SMALL : u8 = 1;
    /// Castle size - middle
    const CASTLE_SIZE_MIDDLE : u8 = 2;
    /// Castle size - big
    const CASTLE_SIZE_BIG : u8 = 3;

    /// Max soldier count per castle - small castle
    const MAX_SOLDIERS_SMALL_CASTLE : u16 = 500;
    /// Max soldier count per castle - middle castle
    const MAX_SOLDIERS_MIDDLE_CASTLE : u16 = 1000;
    /// Max soldier count per castle - big castle
    const MAX_SOLDIERS_MAX_CASTLE : u16 = 2000;

    /// Create new castle
    public entry fun build_castle(size: u8, name_bytes: vector<u8>, serial_number: u64, clock: &Clock, ctx: &mut TxContext) {
        let castle_economic = Economic {
            treasury: 0,
            base_power: 1,
            last_settle_time: clock::timestamp_ms(clock),
        };

        let obj_id = object::new(ctx);
        let serial_number = utils::generate_castle_serial_number(size, &mut obj_id);
        let castle = Castle {
            id: obj_id,
            name: string::utf8(name_bytes),
            serial_number: serial_number,
            level: 1,
            attack_power: 1,
            defence_power: 1,
            experience_pool: 0,
            economic: castle_economic,
        };
        
        transfer::public_transfer(castle, tx_context::sender(ctx));
    }

    /// Transfer castle
    public entry fun transfer_castle(castle: Castle, to: address) {
        transfer::transfer(castle, to);
    }

    /// Castle uses treasury to recruit soldiers
    public entry fun recruit_soldiers (castle: &mut Castle, count: u32, ctx: &mut TxContext) {

    }
}