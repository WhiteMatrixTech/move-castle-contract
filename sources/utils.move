module move_castle::utils {
    use std::hash;
    use std::vector;
    use std::string::{Self, utf8, String};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::debug::print;

    /// Generating the castle's serial number.
    public fun generate_castle_serial_number(size: u64, id: &mut UID): u64 {
        // hashing on the castle's UID.
        let hash = hash::sha2_256(object::uid_to_bytes(id));

        let result_num: u64 = 0;
        // convert the hash vector to u64.
        while (vector::length(&hash) > 0) {
            let element = vector::remove(&mut hash, 0);
            result_num = ((result_num << 8) | (element as u64));
        };

        // keep the last 5 digits. 
        result_num = result_num % 100000u64;

        // concat the size digit.
        size * 100000u64 + result_num
    }

    public fun serial_number_to_image_id(serial_number: u64): String {
        let id = serial_number / 10 % 10000u64;
        u64_to_string(id, 4)
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

    /// convert u64 to string, if length < fixed length, prepend "0"
    public fun u64_to_string(n: u64, fixed_length: u64): String {
        let result: vector<u8> = vector::empty<u8>();
        if (n == 0) {
            vector::push_back(&mut result, 48);
        } else {
            while (n > 0) {
                let digit = ((n % 10) as u8) + 48;
                vector::push_back(&mut result, digit);
                n = n / 10;
            };

            // add "0" at the string front util fixed length.
            while (vector::length(&result) < fixed_length) {
                vector::push_back(&mut result, 48);
            };

            vector::reverse<u8>(&mut result);
        };
        string::utf8(result)
    }
}