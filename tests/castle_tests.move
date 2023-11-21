#[test_only]
module move_castle::castle_tests {
    use move_castle::castle;
    use move_castle::core;
    use sui::test_scenario::Self;
    use sui::clock;
    use std::debug;

    #[test]
    fun get_castle_race_test() {
        let serial_number_1: u64 = 123453;
        let race1 = castle::get_castle_race(serial_number_1);
        assert!(race1 == 3, 0);
        
        let serial_number_2: u64 = 123456;
        let race1 = castle::get_castle_race(serial_number_2);
        assert!(race1 == 1, 0);
    }
}