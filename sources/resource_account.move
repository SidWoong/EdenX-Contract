module edenx::resource_account {

    use std::error;
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    
    const E_RESOURCE_CAP_EXISTS: u64 = 1;
    const E_RESOURCE_CAP_NOT_EXISTS: u64 = 2;

    struct ResourceAccountCap has key {
        signer_cap: SignerCapability,
    }

    #[event]
    struct ResourceAccountCreated has drop, store {
        resource_address: address,
        creator: address,
        timestamp: u64,
    }

    fun init_module(deployer: &signer) {
        let deplpyer_addr = signer::address_of(deployer);

        assert!(
            !exists<ResourceAccountCap>(deplpyer_addr),
            error::already_exists(E_RESOURCE_CAP_EXISTS)
        );

        let seed = b"edenx_resource_v1";

        let (resource_signer, resource_cap) = account::create_resource_account(
            deployer,
            seed
        );

        let resource_address = signer::address_of(&resource_signer);

        move_to(deployer, ResourceAccountCap {
            signer_cap: resource_cap
        });

        event::emit(ResourceAccountCreated {
            resource_address,
            creator: deplpyer_addr,
            timestamp: timestamp::now_seconds()
        });
    }

    public(friend) fun get_resource_signer(): signer acquires ResourceAccountCap {
        let cap = borrow_global<ResourceAccountCap>(@edenx);
        account::create_signer_with_capability(&cap.signer_cap)
    }

    public fun get_resource_address(): address acquires ResourceAccountCap {
        let cap = borrow_global<ResourceAccountCap>(@edenx);
        account::get_signer_capability_address(&cap.signer_cap)
    }

    public fun exists_resource_account(): bool {
        exists<ResourceAccountCap>(@edenx)
    }

    #[test_only]
    public fun initialize_for_test(deployer: &signer){
        init_module(deployer)
    }

    #[test_only]
    public fun get_resource_signer_for_test(): signer acquires ResourceAccountCap {
        get_resource_signer()
    }

}