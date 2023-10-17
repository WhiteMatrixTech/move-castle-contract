module move_castle::battle {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use move_castle::castle::{Self, Castle};
    use move_castle::castle_admin::{Self, GameStore};
    use sui::clock::{Self, Clock};
    use std::debug;
    use std::vector;

    struct BattleTicket has store, drop{
        expiration: u64,
        target: ID
    }

    const TICKET_FIELD_NAME : vector<u8> = b"battle_ticket";
    const EXPIRATION_TIMESTAMP_MS : u64 = 4 * 60 * 60 * 1000;

    public entry fun request_battle_ticket(castle: &mut Castle, clock: &Clock, game_store: &mut GameStore, ctx: &mut TxContext) {
        // make sure battle ticket not exists
        assert!(!castle::has_battle_ticket(castle), 0);

        // random out a target, void current castle
        let target = castle_admin::random_battle_target(&castle::get_castle_id(castle), game_store, ctx);

        // add to castle's dynamic field
        castle::add_dynamic_field(castle, 
                                TICKET_FIELD_NAME, 
                                BattleTicket{
                                    expiration: clock::timestamp_ms(clock) + EXPIRATION_TIMESTAMP_MS, 
                                    target: target
                                });
    }

    public entry fun battle(castle: &mut Castle, target: &mut Castle, clock: &Clock, ctx: &mut TxContext) {
        // make sure battle ticket exists
        assert!(!castle::has_battle_ticket(castle), 0);

        // check ticket
        let ticket = castle::remove_dynamic_field<BattleTicket>(castle, TICKET_FIELD_NAME);
        if (ticket.expiration > clock::timestamp_ms(clock)) {
            // ticket expired
            abort 1;
        };
        if (ticket.target != object::id(target)) {
            // ticket not match the target
            castle::add_dynamic_field(castle, TICKET_FIELD_NAME, ticket);
            abort 1;
        };


        // check target cooldown
        

        // TODO do the battle math
        let attack_power = castle::get_castle_total_attack_power(castle);
        let defence_power = castle::get_castle_total_defence_power(target);
        if (attack_power > defence_power) {
            // win

        } else {
            // lose

        };
    }

}