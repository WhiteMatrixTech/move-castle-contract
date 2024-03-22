#[test_only]
module move_castle::castle_tests {

    #[test]
    fun sample_test() {
        let result = 1 + 2;
		assert!(result == 3, 0);
    }
}