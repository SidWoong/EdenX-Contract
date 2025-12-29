#[test_only]
module edenx::genesis_bot_test {

    use std::signer;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use edenx::genesis_sbt;
    use edenx::admin;

    const CAREER_HUNTER: u8 = 1;
    const CAREER_BUILDER: u8 = 2;
    const CAREER_EXPLORER: u8 = 3;

    #[test_only]
    fun setup_test(deployer: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_initialize(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);

        assert!(admin::admin_config_exists(), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_hunter(deployer: &signer, user: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(user));

        genesis_sbt::mint_genesis_sbt_for_test(user, CAREER_HUNTER);

        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user)), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_builder(deployer: &signer, user: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(user));

        genesis_sbt::mint_genesis_sbt_for_test(user, CAREER_BUILDER);

        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user)), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_explorer(deployer: &signer, user: &signer, framework: &signer) {
        setup_test(deployer, framework);
        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);

        genesis_sbt::mint_genesis_sbt_for_test(user, CAREER_EXPLORER);

        assert!(genesis_sbt::has_genesis_sbt(user_addr), 1);
    }

}