module edenx::admin {
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    const E_NOT_ADMIN: u64 = 1;
    const E_CONTRACT_PAUSED: u64 = 2;
    const E_CONTRACT_NOT_PAUSED: u64 = 3;
    const E_ADMIN_CONFIG_EXISTS: u64 = 4;
    const E_EMPTY_PUBLIC_KEY: u64 = 6;
    const E_INVALID_NEW_ADMIN: u64 = 5;

    struct AdminConfig has key {
        admin: address,
        backend_public_key: vector<u8>,
        version: u64,
        is_paused: bool,
        last_upgrade_at: u64,
        create_at: u64,
    }

    #[event]
    struct AdminInitialized has drop, store {
        admin: address,
        timestamp: u64,
    }

    #[event]
    struct BackendPublicKeyUpdated has drop, store {
        old_public_key: vector<u8>,
        new_public_key: vector<u8>,
        timestamp: u64,
    }

    #[event]
    struct ContractPaused has drop, store {
        paused: bool,
        timestamp: u64,
    }

    #[event]
    struct AdminTransferred has drop, store {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }

    #[event]
    struct ContractUpgraded has drop, store {
        version: u64,
        timestamp: u64,
    }

    fun init_module(admin: &signer) {
        let admin_addr = signer::address_of(admin);

        assert!(
            !exists<AdminConfig>(admin_addr),
            error::already_exists(E_ADMIN_CONFIG_EXISTS)
        );

        let config = AdminConfig {
            admin: admin_addr,
            backend_public_key: vector::empty(),
            version: 1,
            is_paused: false,
            last_upgrade_at: timestamp::now_seconds(),
            create_at: timestamp::now_seconds(),
        };

        move_to(admin, config);

        event::emit(AdminInitialized {
            admin: admin_addr,
            timestamp: timestamp::now_seconds(),
        })
    }

    public entry fun update_backend_public_key(admin: &signer, new_public_key: vector<u8>) acquires AdminConfig {
        assert_is_admin(admin);

        assert!(
            !vector::is_empty(&new_public_key),
            error::invalid_argument(E_EMPTY_PUBLIC_KEY)
        );

        let config = borrow_global_mut<AdminConfig>(@edenx);

        let old_public_key = config.backend_public_key;

        config.backend_public_key = new_public_key;

        event::emit(BackendPublicKeyUpdated {
            old_public_key,
            new_public_key: config.backend_public_key,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun pause_contract(admin: &signer) acquires AdminConfig {
        assert_is_admin(admin);

        let config = borrow_global_mut<AdminConfig>(@edenx);

        assert!(
            !config.is_paused,
            error::invalid_state(E_CONTRACT_NOT_PAUSED)
        );

        config.is_paused = true;

        event::emit(ContractPaused {
            paused: true,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun resume_contract(admin: &signer) acquires AdminConfig {
        assert_is_admin(admin);

        let config = borrow_global_mut<AdminConfig>(@edenx);

        assert!(
            config.is_paused,
            error::invalid_state(E_CONTRACT_PAUSED)
        );

        config.is_paused = false;

        event::emit(ContractPaused {
            paused: true,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun tranfer_admin(admin: &signer, new_admin: address) acquires AdminConfig {
        assert_is_admin(admin);

        assert!(
            new_admin != @0x0,
            error::invalid_argument(E_INVALID_NEW_ADMIN),
        );

        let config = borrow_global_mut<AdminConfig>(@edenx);
        let old_admin = config.admin;

        config.admin = new_admin;

        event::emit(AdminTransferred {
            old_admin,
            new_admin,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun mark_upgrade(admin: &signer) acquires AdminConfig {
        assert_is_admin(admin);

        let config = borrow_global_mut<AdminConfig>(@edenx);

        config.version = config.version + 1;
        config.last_upgrade_at = timestamp::now_seconds();

        event::emit(ContractUpgraded {
            version: config.version,
            timestamp: timestamp::now_seconds(),
        });
    }

    public fun get_backend_public_key(): vector<u8> acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);
        config.backend_public_key
    }

    public fun is_paused(): bool acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);
        config.is_paused
    }

    public fun get_admin(): address acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);
        config.admin
    }

    public fun get_version(): u64 acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);
        config.version
    }

    fun assert_is_admin(accout: &signer) acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);

        assert!(
            signer::address_of(accout) == config.admin,
            error::permission_denied(E_NOT_ADMIN)
        )
    }

    public fun assert_not_paused() acquires AdminConfig {
        let config = borrow_global<AdminConfig>(@edenx);
        assert!(
            !config.is_paused,
            error::unavailable(E_CONTRACT_PAUSED)
        );
    }

    #[test_only]
    public fun initialize_for_test(admin: &signer) {
        init_module(admin);
    }

    #[test_only]
    public fun admin_config_exists(): bool {
        exists<AdminConfig>(@edenx)
    }

    #[test_only]
    public fun set_backend_public_key_for_test(
        admin: &signer,
        public_key: vector<u8>
    ) acquires AdminConfig {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @edenx, error::permission_denied(E_NOT_ADMIN));

        let config = borrow_global_mut<AdminConfig>(@edenx);
        config.backend_public_key = public_key;
    }
}