module move_castle::utils {
    use std::hash;
    use std::vector;
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    public fun generate_castle_serial_number(size: u64, id: &mut UID): u64 {
        let hash = hash::sha2_256(object::uid_to_bytes(id));
        let result_num: u64 = 0;

        // module operation
        while (vector::length(&hash) > 0) {
            let element = vector::remove(&mut hash, 0);
            result_num = ((result_num << 8) | (element as u64)) % 10000u64;
        };
        result_num = result_num % 10000u64;

        size * 100000u64 + result_num * 10
    }

    public fun serial_number_to_image_id(serial_number: u64): u64 {
        serial_number / 10 % 10000u64
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

    public fun u64_to_string(n: u64): String {
        let result: vector<u8> = vector::empty<u8>();
        if (n == 0) {
            vector::push_back(&mut result, 48);
        } else {
            while (n > 0) {
                let digit = ((n % 10) as u8) + 48;
                vector::push_back(&mut result, digit);
                n = n / 10;
            };
            vector::reverse<u8>(&mut result);
        };
        string::utf8(result)
    }
}