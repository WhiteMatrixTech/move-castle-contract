#[test_only]
module move_castle::castle_tests {
    use move_castle::castle;
    use sui::test_scenario::Self;
    use sui::clock;

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
            castle::test_update_castle(&mut test_castle);
            castle::upgrade_castle(&mut test_castle, test_scenario::ctx(scenario));
            assert!(castle::get_level(&test_castle) == 2, 0);
            test_scenario::return_to_sender(scenario, test_castle);
        };
        
        test_scenario::end(scenario_val);
    }
}