module edenx::genesis_sbt {
    use std::error;
    use std::string::{Self, String};
    use std::signer;
    use std::option;
    use std::vector;
    use aptos_framework::object::{Self};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self};
    use aptos_token_objects::property_map;
    use aptos_std::ed25519;
    use aptos_std::bcs;
    use edenx::edenx_resource;
    use edenx::admin;

    const E_GENESIS_SBT_EXISTS: u64 = 1;
    const E_GENESIS_SBT_NOT_EXISTS: u64 = 2;
    const E_INVALID_CAREER_TYPE: u64 = 3;
    const E_INVALID_SIGNATURE: u64 = 4;
    const E_SIGNATURE_EXPIRED: u64 = 5;
    const E_COLLECTION_NOT_EXISTS: u64 = 6;

    const COLLECTION_NAME: vector<u8> = b"EdenX Genesis";
    const COLLECTION_DESCRIPTION: vector<u8> = b"Genesis Soulbound Tokens for EdenX Explorers";
    const COLLECTION_URI: vector<u8> = b"https://edenx.io/api/collection/genesis";

    const CAREER_HUNTER: u8 = 1;
    const CAREER_BUILDER: u8 = 2;
    const CAREER_EXPLORER: u8 = 3;

    const SIGNATURE_VALIDITY_SECONDS: u64 = 300;

    struct GenesisSBTData has key {
        career_type: u8,
        owner: address,
        mint_timestamp: u64,
        token_id: u64,
    }

    #[test_only]
    struct UserGenesisSBTForTest has key {
        career_type: u8,
        token_id: u64,
        mint_timestamp: u64,
    }

    struct TokenCounter has key {
        next_token_id: u64,
    }

    struct UserTokenMapping has key {
        token_address: address,
    }

    #[event]
    struct GenesisSBTMinted has drop, store {
        user: address,
        token_address: address,
        career_type: u8,
        token_id: u64,
        timestamp: u64,
    }

    fun init_module(_deployer: &signer) {}

    public entry fun initialize_collection(admin: &signer) {
        admin::assert_is_admin(admin);

        let resource_signer = edenx_resource::get_resource_signer();

        collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(COLLECTION_DESCRIPTION),
            string::utf8(COLLECTION_NAME),
            option::none(),
            string::utf8(COLLECTION_URI)
        );
        move_to(admin, TokenCounter {
            next_token_id: 1,
        })

    }

    public entry fun mint_genesis_sbt(user: &signer, career_type: u8, backend_signature: vector<u8>, timestamp: u64) acquires TokenCounter {
        let user_addr = signer::address_of(user);

        assert!(
            !has_genesis_sbt(user_addr),
            error::already_exists(E_GENESIS_SBT_EXISTS)
        );

        assert!(
            is_valid_career_type(career_type),
            error::invalid_argument(E_INVALID_CAREER_TYPE)
        );

        verify_backend_signature(
            user_addr,
            career_type,
            timestamp,
            backend_signature
        );

        let current_time = timestamp::now_seconds();
        assert!(
            current_time >= timestamp,
            error::invalid_state(E_SIGNATURE_EXPIRED)
        );
        assert!(
            current_time - timestamp <= SIGNATURE_VALIDITY_SECONDS,
            error::invalid_state(E_SIGNATURE_EXPIRED)
        );

        let counter = borrow_global_mut<TokenCounter>(@edenx);
        let token_id = counter.next_token_id;
        counter.next_token_id = token_id + 1;

        let token_name = string::utf8(b"Genesis SBT #");
        string::append(&mut token_name, u64_to_string(token_id));

        let token_description = string::utf8(b"You are the ");
        string::append(&mut token_description, u64_to_string(token_id));
        string::append_utf8(&mut token_description, b" explorer to join EdenX!");

        let token_uri = get_token_uri(career_type, token_id);

        let resource_signer = edenx_resource::get_resource_signer();

        let constructor_ref = token::create_named_token(
            &resource_signer,
            string::utf8(COLLECTION_NAME),
            token_description,
            token_name,
            option::none(),
            token_uri
        );

        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, user_addr);

        object::disable_ungated_transfer(&transfer_ref);

        let mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Career"),
            get_career_name(career_type)
        );

        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Token ID"),
            token_id
        );

        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Mint Date"),
            current_time
        );

        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Transferable"),
            false
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let token_address = signer::address_of(&token_signer);

        move_to(&token_signer, GenesisSBTData {
            career_type,
            owner: user_addr,
            mint_timestamp: current_time,
            token_id
        });

        move_to(user, UserTokenMapping {
            token_address
        });

        event::emit(GenesisSBTMinted {
            user: user_addr,
            token_address,
            career_type,
            token_id,
            timestamp: current_time
        });
    }

    fun get_token_uri(career_type: u8, token_id: u64): String {
        let base_uri = string::utf8(b"https://edenx.io/api/sbt/genesis/");

        if (career_type == CAREER_HUNTER) {
            string::append_utf8(&mut base_uri, b"hunter/");
        } else if (career_type == CAREER_BUILDER) {
            string::append_utf8(&mut base_uri, b"builder/");
        } else {
            string::append_utf8(&mut base_uri, b"explorer/");
        };

        string::append(&mut base_uri, u64_to_string(token_id));
        string::append_utf8(&mut base_uri, b".json");

        base_uri
    }

    public fun has_genesis_sbt(user_addr: address): bool {
        exists<UserTokenMapping>(user_addr)
    }

    fun u64_to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };

        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    fun is_valid_career_type(career_type: u8): bool {
        career_type == CAREER_HUNTER || career_type == CAREER_BUILDER || career_type == CAREER_EXPLORER
    }

    fun get_career_name(career_type: u8): String {
        if (career_type == CAREER_HUNTER) {
            string::utf8(b"Hunter")
        } else if (career_type == CAREER_BUILDER) {
            string::utf8(b"Builder")
        } else if (career_type == CAREER_EXPLORER) {
            string::utf8(b"Explorer")
        } else {
            string::utf8(b"Unknown")
        }
    }

    public fun get_token_address(user_addr: address): address acquires UserTokenMapping {
        assert!(
            has_genesis_sbt(user_addr),
            error::not_found(E_GENESIS_SBT_NOT_EXISTS)
        );

        let mapping = borrow_global<UserTokenMapping>(user_addr);
        mapping.token_address
    }

    fun verify_backend_signature(
        user_addr: address,
        career_type: u8,
        timestamp: u64,
        signature: vector<u8>
    ) {
        let message = construct_message(user_addr, career_type, timestamp);

        let public_key_bytes = admin::get_backend_public_key();

        let public_key = ed25519::new_unvalidated_public_key_from_bytes(public_key_bytes);
        let signature_obj = ed25519::new_signature_from_bytes(signature);

        let is_valid = ed25519::signature_verify_strict(
            &signature_obj,
            &public_key,
            message
        );

        assert!(
            is_valid,
            error::invalid_argument(E_INVALID_SIGNATURE)
        );
    }

    fun construct_message(
        user_addr: address,
        career_type: u8,
        timestamp: u64
    ): vector<u8> {
        let message = vector::empty<u8>();

        vector::append(&mut message, bcs::to_bytes(&user_addr));

        vector::append(&mut message, bcs::to_bytes(&career_type));

        vector::append(&mut message, bcs::to_bytes(&timestamp));

        message
    }

    #[test_only]
    public fun initialize_for_test(deployer: &signer) {
        init_module(deployer);
    }

    #[test_only]
    public fun get_career_hunter(): u8 { CAREER_HUNTER }

    #[test_only]
    public fun get_career_builder(): u8 { CAREER_BUILDER }

    #[test_only]
    public fun get_career_explorer(): u8 { CAREER_EXPLORER }

    #[test_only]
    public fun get_signature_validity_seconds(): u64 { SIGNATURE_VALIDITY_SECONDS }

    #[test_only]
    public fun construct_message_for_test(
        user_addr: address,
        career_type: u8,
        timestamp: u64
    ): vector<u8> {
        construct_message(user_addr, career_type, timestamp)
    }

    #[test_only]
    public entry fun mint_genesis_sbt_for_test(user: &signer, career_type: u8) acquires TokenCounter {
        let user_addr = signer::address_of(user);

        assert!(
            !has_genesis_sbt(user_addr),
            error::already_exists(E_GENESIS_SBT_EXISTS)
        );

        assert!(
            is_valid_career_type(career_type),
            error::invalid_argument(E_INVALID_CAREER_TYPE)
        );

        let current_time = timestamp::now_seconds();

        let counter = borrow_global_mut<TokenCounter>(@edenx);
        let token_id = counter.next_token_id;
        counter.next_token_id = token_id + 1;

        let token_address = @0x0;

        move_to(user, UserTokenMapping {
            token_address
        });

        event::emit(GenesisSBTMinted {
            user: user_addr,
            token_address,
            career_type,
            token_id,
            timestamp: current_time
        });
    }
}