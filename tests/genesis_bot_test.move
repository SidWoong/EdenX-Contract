#[test_only]
module edenx::genesis_bot_test {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use edenx::admin;
    use edenx::genesis_sbt;

    #[test(deployer = @edenx, framework = @0x1)]
    fun test_collection_created(deployer: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_hunter(deployer: &signer, user: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));
        account::create_account_for_test(signer::address_of(user));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);

        genesis_sbt::mint_genesis_sbt_for_test(
            user,
            genesis_sbt::get_career_hunter()
        );

        // assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user)), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_builder(deployer: &signer, user: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));
        account::create_account_for_test(signer::address_of(user));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);

        genesis_sbt::mint_genesis_sbt_for_test(
            user,
            genesis_sbt::get_career_builder()
        );

        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user)), 1);
    }

    #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    fun test_mint_explorer(deployer: &signer, user: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));
        account::create_account_for_test(signer::address_of(user));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);

        genesis_sbt::mint_genesis_sbt_for_test(
            user,
            genesis_sbt::get_career_explorer()
        );

        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user)), 1);
    }

    // #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    // #[expected_failure(abort_code = 524289, location = edenx::genesis_sbt)]
    // fun test_cannot_mint_twice(deployer: &signer, user: &signer, framework: &signer) {
    //     timestamp::set_time_has_started_for_testing(framework);
    //     account::create_account_for_test(signer::address_of(deployer));
    //     account::create_account_for_test(signer::address_of(user));
    //
    //     admin::initialize_for_test(deployer);
    //     genesis_sbt::initialize_for_test(deployer);
    //
    //     let career = genesis_sbt::get_career_hunter();
    //
    //     genesis_sbt::mint_genesis_sbt_for_test(user, career);
    //
    //     genesis_sbt::mint_genesis_sbt_for_test(user, career);
    // }

    // #[test(deployer = @edenx, user = @0x123, framework = @0x1)]
    // #[expected_failure(abort_code = 65539, location = edenx::genesis_sbt)]
    // fun test_invalid_career_type(deployer: &signer, user: &signer, framework: &signer) {
    //     timestamp::set_time_has_started_for_testing(framework);
    //     account::create_account_for_test(signer::address_of(deployer));
    //     account::create_account_for_test(signer::address_of(user));
    //
    //     admin::initialize_for_test(deployer);
    //     genesis_sbt::initialize_for_test(deployer);
    //
    //     genesis_sbt::mint_genesis_sbt_for_test(user, 99u8);
    // }

    #[test(deployer = @edenx, user1 = @0x123, user2 = @0x456, framework = @0x1)]
    fun test_token_id_increment(deployer: &signer, user1: &signer, user2: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        account::create_account_for_test(signer::address_of(deployer));
        account::create_account_for_test(signer::address_of(user1));
        account::create_account_for_test(signer::address_of(user2));

        admin::initialize_for_test(deployer);
        genesis_sbt::initialize_for_test(deployer);

        genesis_sbt::mint_genesis_sbt_for_test(user1, genesis_sbt::get_career_hunter());

        genesis_sbt::mint_genesis_sbt_for_test(user2, genesis_sbt::get_career_builder());

        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user1)), 1);
        assert!(genesis_sbt::has_genesis_sbt(signer::address_of(user2)), 2);
    }
}
