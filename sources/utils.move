module move_castle::utils {
    use std::hash;
    use std::string::{Self, String};
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    public fun generate_castle_serial_number(size: u64, id: &mut UID): u64 {
        let hash = hash::sha2_256(object::uid_to_bytes(id));
        let result_num: u64 = 0;

        // module operation
        while (vector::length(&hash) > 0) {
            let element = vector::remove(&mut hash, 0);
            result_num = ((result_num << 8) | (element as u64)) % 1000000u64;
        };
        result_num = result_num % 1000000u64;

        size * 10000000u64 + result_num * 10
    }

    public fun random_in_range(range: u64, ctx: &mut TxContext):u64 {
        let uid = object::new(ctx);
        let hash = hash::sha2_256(object::uid_to_bytes(&uid));
        object::delete(uid);

        let result_num: u64 = 0;
        // module operation
        while (vector::length(&hash) > 0) {
            let element = vector::remove(&mut hash, 0);
            result_num = ((result_num << 8) | (element as u64)) % 1000000u64;
        };
        result_num = result_num % range;

        result_num
    }

    public fun abs_minus(a: u64, b: u64): u64 {
        let result;
        if (a > b) {
            result = a - b;
        } else {
            result = b - a;
        };
        result
    }

}