#[test_only]
module move_castle::castle_tests {
    use move_castle::castle{Self, Castle};
    use sui::test_scenario::Self;

    #[test]
    fun upgrade_castle_test() {
        let owner = @0xABC;

        let senario_val = test_scenario::begin(owner);
    }
}