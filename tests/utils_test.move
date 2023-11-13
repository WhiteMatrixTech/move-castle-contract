#[test_only]
module move_castle::utils_tests {
    use sui::test_scenario::Self;
    use move_castle::utils;
    
    #[test]
    fun random_in_range_test() {
        let sender = @0xABC;

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            let result = utils::random_in_range(3, ctx);
            assert!(result >= 0, 0);
            assert!(result < 3, 0);
        };

        test_scenario::end(scenario_val);
    }
}