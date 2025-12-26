#[test_only]
module edenx::admin_test {
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use edenx::admin;

    #[test_only]
    fun setup_test(deployer: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));
        admin::initialize_for_test(deployer);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_initialize(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        assert!(admin::admin_config_exists(), 1);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_initial_state(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        assert!(admin::get_admin() == @edenx, 1);
        assert!(admin::get_version() == 1, 2);
        assert!(!admin::is_paused(), 3);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 524292, location = edenx::admin)]
    fun test_cannot_initzlize_twice(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::initialize_for_test(deployer);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_update_backend_public_key(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        let new_key = x"deadbeef";
        admin::update_backend_public_key(deployer, new_key);

        let current_key = admin::get_backend_public_key();
        assert!(current_key == new_key, 1);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_update_backend_public_key_multiple_times(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        let key1 = x"deadbeef";
        admin::update_backend_public_key(deployer, key1);
        assert!(admin::get_backend_public_key() == key1, 1);

        let key2 = x"cafebabe";
        admin::update_backend_public_key(deployer, key2);
        assert!(admin::get_backend_public_key() == key2, 2);

        let key3 = x"12345678";
        admin::update_backend_public_key(deployer, key3);
        assert!(admin::get_backend_public_key() == key3, 3);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 65542, location = edenx::admin)]
    fun test_cannot_set_empty_public_key(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        let empty_key = vector::empty<u8>();
        admin::update_backend_public_key(deployer, empty_key);
    }

    #[test(deployer = @edenx, non_admin = @0x123, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_non_admin_cannot_update_public_key(deployer: &signer, non_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(non_admin));

        let new_key = x"deadbeef";
        admin::update_backend_public_key(non_admin, new_key);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_pause_contract(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        assert!(!admin::is_paused(), 1);

        admin::pause_contract(deployer);
        assert!(admin::is_paused(), 2);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_resume_contract(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::pause_contract(deployer);
        assert!(admin::is_paused(), 1);

        admin::resume_contract(deployer);
        assert!(!admin::is_paused(), 2);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 196611, location = edenx::admin)]
    fun test_cannot_pause_when_already_paused(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::pause_contract(deployer);

        admin::pause_contract(deployer);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 196610, location = edenx::admin)]
    fun test_cannot_resume_when_not_paused(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::resume_contract(deployer);
    }

    #[test(deployer = @edenx, non_admin = @0x123, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_non_admin_cannot_pause(deployer: &signer, non_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(non_admin));

        admin::pause_contract(non_admin);
    }

    #[test(deployer = @edenx, non_admin = @0x123, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_non_admin_cannot_resume(deployer: &signer, non_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(non_admin));

        admin::pause_contract(deployer);
        admin::resume_contract(non_admin);
    }
}

