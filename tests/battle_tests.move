#[test_only]
module move_castle::battle_tests {
    use sui::test_scenario::Self;
    use move_castle::castle::{Self, Castle};
    use move_castle::core::{Self, GameStore};
    use move_castle::battle;
    use sui::clock::{Self, Clock};

    #[test]
    fun battle_test() {
        let owner1 = @0xABC;
        let owner2 = @0xABD;

        let scenario_val = test_scenario::begin(owner1);
        let scenario = &mut scenario_val;
        let scenario_val2 = test_scenario::begin(owner2);
        let scenario2 = &mut scenario_val2;
        let game_store;
        {
            let ctx = test_scenario::ctx(scenario);
            game_store = core::create_game_store_for_test(ctx);
            let clock = clock::create_for_testing(ctx);
            castle::build_castle(1, b"1", b"1", &clock, &mut game_store, ctx);

            let ctx2 = test_scenario::ctx(scenario2);
            castle::build_castle(2, b"2", b"2", &clock, &mut game_store, ctx2);
            clock::destroy_for_testing(clock);
            
        };

        test_scenario::next_tx(scenario, owner1);
        {
            let castle1 = test_scenario::take_from_sender<castle::Castle>(scenario);
            let castle2 = test_scenario::take_from_sender<castle::Castle>(scenario2);
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
            clock::set_for_testing(&mut clock, 1697623670430);
            battle::battle(&mut castle1, &clock, &mut game_store, ctx);
            test_scenario::return_to_sender(scenario, castle1);
            test_scenario::return_to_sender(scenario2, castle2);
            clock::destroy_for_testing(clock);
        };

        core::destroy_game_store_for_test(game_store);

        test_scenario::end(scenario_val);
        test_scenario::end(scenario_val2);
    }

    
}