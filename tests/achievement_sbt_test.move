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

    // #[test(deployer = @edenx, user = @0x123, framwork = @0x1)]
    // fun test_mint_achievement_sbt(deployer: &signer, user: &signer, framwork: &signer) {
    //     timestamp::set_time_has_started_for_testing(framwork);
    //     account::create_account_for_test(signer::address_of(deployer));
    //     account::create_account_for_test(signer::address_of(user));
    //
    //     admin::initialize_for_test(deployer);
    //     genesis_sbt::initialize_for_test(deployer);
    //     achievement_sbt::initialize_for_test(deployer);
    //
    //     genesis_sbt::mint_genesis_sbt_for_test(user, 1u8);
    //
    //     achievement_sbt::mint_achievement_sbt_for_test(user);
    //
    //     assert!(
    //         achievement_sbt::has_achievement_sbt(signer::address_of(user)),
    //         1
    //     );
    // }
}
