module move_castle::battle {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_field;
    use move_castle::castle::{Self, Castle};
    use move_castle::castle_admin::{Self, GameStore};
    use sui::test_scenario::Self;
    use sui::clock::{Self, Clock};
    use std::debug;
    use std::vector;

    struct BattleTicket has store, drop{
        expiration: u64,
        target: ID
    }

    const TICKET_FIELD_NAME : vector<u8> = b"battle_ticket";
    const EXPIRATION_TIMESTAMP_MS : u64 = 4 * 60 * 60 * 1000;

    public entry fun request_battle_ticket(castle: &mut Castle, clock: &Clock, ctx: &mut TxContext) {
        // make sure battle ticket not exists
        assert!(!castle::has_battle_ticket(castle), 0);

        // TODO random out a target, void current castle

        // add to castle's dynamic field
        let target = object::new(ctx);
        castle::add_dynamic_field(castle, 
                                TICKET_FIELD_NAME, 
                                BattleTicket{
                                    expiration: clock::timestamp_ms(clock) + EXPIRATION_TIMESTAMP_MS, 
                                    target: object::uid_to_inner(&target)
                                });
        object::delete(target);
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

    #[test]
    fun ticket_test() {
        let owner = @0xABC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            let game_store = castle_admin::create_game_store_for_test(ctx);
            let clock = clock::create_for_testing(ctx);
            castle::build_castle(1, vector[72, 101, 108, 108, 111], &clock, &mut game_store, ctx);
            clock::destroy_for_testing(clock);
            castle_admin::destroy_game_store_for_test(game_store);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
            request_battle_ticket(&mut test_castle, &clock, ctx);
            test_scenario::return_to_sender(scenario, test_castle);
            clock::destroy_for_testing(clock);
        };

        test_scenario::end(scenario_val);
    }
}