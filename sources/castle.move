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

    struct CastleBuilt has copy, drop {
        id: ID,
        owner: address,
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

    /// TODO Design the required exp
    /// Experience points required for castle level 2 - 10
    const REQUIRED_EXP_LEVELS : vector<u64> = vector[10, 20, 30, 40, 50, 60, 70, 80, 90];

    /// Max castle level
    const MAX_CASTLE_LEVEL : u64 = 10;

    /// Create new castle
    public entry fun build_castle(size: u8, name_bytes: vector<u8>, clock: &Clock, ctx: &mut TxContext) {
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
        
        let owner = tx_context::sender(ctx);
        event::emit(CastleBuilt{id: object::uid_to_inner(&castle.id), owner: owner});
        transfer::public_transfer(castle, owner);
    }

    fun get_id(castle: &Castle): ID {
        object::uid_to_inner(&castle.id)
    }

    public fun get_level(castle: &Castle): u64 {
        castle.level
    }

    #[test_only]
    /// Only for test
    public fun test_update_castle(castle: &mut Castle) {
        castle.experience_pool = castle.experience_pool + 10;
        castle.economic.treasury = castle.economic.treasury + 10;
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
            /// TODO emit castle upgrade event
        }
    }

    /// Settle castle's treasury, including victory rewards and defeat penalties
    public entry fun settle_castle_treasury(castle: &mut Castle, clock: &Clock, ctx: &mut TxContext) {

    }


    /// Transfer castle
    public entry fun transfer_castle(castle: Castle, to: address) {
        transfer::transfer(castle, to);
    }

    /// Castle uses treasury to recruit soldiers
    public entry fun recruit_soldiers (castle: &mut Castle, count: u32, ctx: &mut TxContext) {

    }

}