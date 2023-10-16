#[test_only]
module move_castle::castle_tests {
    use move_castle::castle;
    use sui::test_scenario::Self;
    use sui::clock;
    use std::debug;

    #[test]
    fun upgrade_castle_test() {
        let owner = @0xABC;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
            castle::build_castle(1, vector[72, 101, 108, 108, 111], &clock, ctx);
            clock::destroy_for_testing(clock);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 99);
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 1, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 101);
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 2, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 249);
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 2, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 250);
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 3, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 7491); // 7492, level up to 10 exp needed
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 9, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let test_castle = test_scenario::take_from_sender<castle::Castle>(scenario);
            castle::set_castle_level(&mut test_castle, 1);
            castle::set_castle_exp(&mut test_castle, 7492); // 7492, level up to 10 exp needed
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_castle_level(&test_castle) == 10, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };
        
        test_scenario::end(scenario_val);
    }
}