module move_castle::castle_admin {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use move_castle::castle::{Self, Castle};

    /// Capability to modify game settings
    struct AdminCap has key {
        id: UID
    }

    /// Module initializer create the only one AdminCap and send it to the publisher
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            AdminCap{id: object::new(ctx)},
            tx_context::sender(ctx)
        )
    }

    /// Only the owner of the AdminCap can call this function to distribute treasury rewards
    public entry fun distribute_treasury_rewards(_: &AdminCap, amount: u64, castle: &mut Castle, ctx: &mut TxContext) {
        castle::add_castle_treasury(castle, amount);
    }
}