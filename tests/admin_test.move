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

    #[test(deployer = @edenx, new_admin = @0x456, framework = @0x1)]
    fun test_transfer_admin(deployer: &signer, new_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        let new_admin_addr = signer::address_of(new_admin);

        account::create_account_for_test(new_admin_addr);

        assert!(admin::get_admin() == @edenx, 1);

        admin::tranfer_admin(deployer, new_admin_addr);

        assert!(admin::get_admin() == new_admin_addr, 2);
    }

    #[test(deployer = @edenx, new_admin = @0x456, framework = @0x1)]
    fun test_new_admin_can_operate(deployer: &signer, new_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        let new_admin_addr = signer::address_of(new_admin);

        account::create_account_for_test(new_admin_addr);

        assert!(admin::get_admin() == @edenx, 1);
        admin::tranfer_admin(deployer, new_admin_addr);

        assert!(admin::get_admin() == new_admin_addr, 2);

        admin::pause_contract(new_admin);
        assert!(admin::is_paused(), 3);

        let new_key = x"bbbbbbbb";
        admin::update_backend_public_key(new_admin, new_key);
        assert!(admin::get_backend_public_key() == new_key, 4);
    }

    #[test(deployer = @edenx, new_admin = @0x456, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_old_admin_cannot_operate_after_transfer(deployer: &signer, new_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        let new_admin_addr = signer::address_of(new_admin);

        account::create_account_for_test(new_admin_addr);

        admin::tranfer_admin(deployer, new_admin_addr);

        assert!(admin::get_admin() == new_admin_addr, 1);

        admin::pause_contract(deployer);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 65541, location = edenx::admin)]
    fun test_cannot_transfer_to_zero_address(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);
        admin::tranfer_admin(deployer, @0x0);
    }

    #[test(deployer = @edenx, non_admin = @0x123, new_admin = @0x456, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_non_admin_cannot_transfer_admin(deployer: &signer, non_admin: &signer, new_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);
        let non_admin_addr = signer::address_of(non_admin);
        let new_admin_addr = signer::address_of(new_admin);

        account::create_account_for_test(non_admin_addr);
        account::create_account_for_test(new_admin_addr);

        admin::tranfer_admin(non_admin, new_admin_addr);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_mark_upgrade(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        assert!(admin::get_version() == 1, 1);

        admin::mark_upgrade(deployer);
        assert!(admin::get_version() == 2, 2);

        admin::mark_upgrade(deployer);
        assert!(admin::get_version() == 3, 3);
    }

    #[test(deployer = @edenx, non_admin = @0x123, framework = @0x1)]
    #[expected_failure(abort_code = 327681, location = edenx::admin)]
    fun test_non_admin_cannot_mark_upgrade(deployer: &signer, non_admin: &signer, framework: &signer) {
        setup_test(deployer, framework);

        account::create_account_for_test(signer::address_of(non_admin));

        admin::mark_upgrade(non_admin);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_assert_not_paused_when_not_paused(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::assert_not_paused();
    }

    #[test(deployer = @edenx, framework = @0x1)]
    #[expected_failure(abort_code = 851970, location = edenx::admin)]
    fun test_assert_not_paused_fails_when_paused(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        admin::pause_contract(deployer);
        //
        assert!(admin::get_admin() == @edenx, 1);
        //
        admin::assert_not_paused();
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_full_admin_workflow(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        let key1 = x"deadbeef";
        admin::update_backend_public_key(deployer, key1);
        assert!(admin::get_backend_public_key() == key1, 1);

        admin::pause_contract(deployer);
        assert!(admin::is_paused(), 2);

        admin::resume_contract(deployer);
        assert!(!admin::is_paused(), 3);

        admin::mark_upgrade(deployer);
        assert!(admin::get_version() == 2, 4);

        let key2 = x"cafebabe";
        admin::update_backend_public_key(deployer, key2);
        assert!(admin::get_backend_public_key() == key2, 5);
    }

    #[test(deployer = @edenx, new_admin = @0x456, framework = @0x1)]
    fun test_admin_transfer_workflow(
        deployer: &signer,
        new_admin: &signer,
        framework: &signer
    ) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(new_admin));

        let new_admin_addr = signer::address_of(new_admin);

        let key1 = x"deadbeef";
        admin::update_backend_public_key(deployer, key1);

        admin::pause_contract(deployer);
        assert!(admin::is_paused(), 1);

        admin::tranfer_admin(deployer, new_admin_addr);
        assert!(admin::get_admin() == new_admin_addr, 2);

        admin::resume_contract(new_admin);
        assert!(!admin::is_paused(), 3);

        let key2 = x"cafebabe";
        admin::update_backend_public_key(new_admin, key2);
        assert!(admin::get_backend_public_key() == key2, 4);

        admin::mark_upgrade(new_admin);
        assert!(admin::get_version() == 2, 5);
    }
}

