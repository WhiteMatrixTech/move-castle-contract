#[test_only]
module move_castle::utils_tests {
    use sui::test_scenario::Self;
    use sui::table;
    use move_castle::castle;
    use move_castle::utils;
    use std::debug::print;
    use std::string;
    use std::vector;
    use sui::object::{Self, UID};
    use std::hash;
    
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

    #[test]
    fun u64_to_string_test() {
        let num1: u64 = 12345;
        let str1 = utils::u64_to_string(num1, 5);
        print(&str1);
        assert!(string::bytes(&str1) == & b"12345", 0);

        let num2: u64 = 123;
        let str2 = utils::u64_to_string(num2, 5);
        print(&str2);
        assert!(string::bytes(&str2) == & b"00123", 0);
    }

    #[test]
    fun serial_number_test() {
        let sender = @0xABC;

        let scenario_val = test_scenario::begin(sender);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            let uid = object::new(ctx);
            let result = utils::generate_castle_serial_number(0, &mut uid);
            print(&result);
            assert!(result >= 0, 0);
            assert!(result < 100000, 0);
            object::delete(uid);
        };

        test_scenario::end(scenario_val);
    }
}