module edenx::edenx_resource {
    friend edenx::genesis_sbt;
    friend edenx::achievement_sbt;

    use std::error;
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    const E_RESOURCE_CAP_EXISTS: u64 = 1;
    const E_RESOURCE_CAP_NOT_EXISTS: u64 = 2;
    const E_NOT_AUTHORIZED: u64 = 3;
    const E_ALREADY_INITIALIZED: u64 = 4;

    struct ResourceAccountCap has key {
        signer_cap: SignerCapability,
    }

    struct InitializationState has key {
        initialized: bool,
        deployer: address
    }

    #[event]
    struct ResourceAccountCreated has drop, store {
        resource_address: address,
        creator: address,
        timestamp: u64,
    }

    fun init_module(deployer: &signer) {
        move_to(deployer, InitializationState {
            initialized: false,
            deployer: signer::address_of(deployer)
        });
    }

    public entry fun initialize(deployer: &signer) acquires InitializationState {
        let deployer_addr = signer::address_of(deployer);

        let state = borrow_global_mut<InitializationState>(@edenx);
        assert!(deployer_addr == state.deployer, error::permission_denied(E_NOT_AUTHORIZED));

        assert!(!state.initialized, error::already_exists(E_ALREADY_INITIALIZED));

        assert!(
            !exists<ResourceAccountCap>(deployer_addr),
            error::already_exists(E_RESOURCE_CAP_EXISTS)
        );

        let seed = b"edenx";
        let (resource_signer, resource_cap) = account::create_resource_account(
            deployer,
            seed
        );

        let resource_address = signer::address_of(&resource_signer);

        move_to(deployer, ResourceAccountCap {
            signer_cap: resource_cap
        });

        state.initialized = true;

        event::emit(ResourceAccountCreated {
            resource_address,
            creator: deployer_addr,
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