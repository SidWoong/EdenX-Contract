#[test_only]
module edenx::admin_test {
    use std::signer;
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
}
