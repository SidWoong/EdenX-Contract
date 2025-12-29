#[test_only]
module edenx::achievement_sbt_test {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use edenx::achievement_sbt;
    use edenx::genesis_sbt;
    use edenx::admin;


    const SKILL_PROGRAMMING: u8 = 1;
    const SKILL_WEB3: u8 = 2;
    const SKILL_APPS: u8 = 3;

    const CAREER_HUNTER: u8 = 1;
    const CAREER_BUILDER: u8 = 2;
    const CAREER_EXPLORER: u8 = 3;

    #[test_only]
    fun setup_test(deployer: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);
        achievement_sbt::initialize_for_test(deployer);
    }

    #[test_only]
    fun setup_user_with_genesis(user: &signer, career_type: u8) {
        account::create_account_for_test(signer::address_of(user));
        genesis_sbt::mint_genesis_sbt_for_test(user, career_type);
    }

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_initalize(deployer: &signer, framework: &signer) {
        setup_test(deployer, framework);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_achievement_sbt_test(deployer: &signer, user: &signer, framework: &signer) {
        setup_test(deployer, framework);
        setup_user_with_genesis(user, CAREER_HUNTER);

        achievement_sbt::mint_achievement_sbt_for_test(user);

        assert!(achievement_sbt::has_achievement_sbt(signer::address_of(user)), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framewrok = @0x1)]
    #[expected_failure(abort_code = 524289, location = edenx::achievement_sbt)]
    fun test_cannot_mint_twice(deployer: &signer, user: &signer, framewrok: &signer) {
        setup_test(deployer, framewrok);
        setup_user_with_genesis(user, CAREER_BUILDER);

        achievement_sbt::mint_achievement_sbt_for_test(user);
        achievement_sbt::mint_achievement_sbt_for_test(user);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    #[expected_failure(abort_code = 393226, location = edenx::achievement_sbt)]
    fun test_cannot_mint_without_genesis(deployer: &signer, user: &signer, framework: &signer) {
        setup_test(deployer, framework);
        account::create_account_for_test(signer::address_of(user));

        achievement_sbt::mint_achievement_sbt_for_test(user);
    }
}