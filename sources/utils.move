module move_castle::utils {
    use std::hash;
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, UID};

    public fun generate_castle_serial_number(size: u8, id: &mut UID): u64 {
        let hash = hash::sha2_256(object::uid_to_bytes(id));
        let result_num: u64 = 0;

        // module operation
        while (vector::length(&hash) > 0) {
            let element = vector::remove(&mut hash, 0);
            result_num = ((result_num << 8) | (element as u64)) % 1000000u64;
        };
        result_num = result_num % 1000000u64;

        (size as u64) * 10000000u64 + result_num * 10
    }
}