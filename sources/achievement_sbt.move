module edenx::achievement_sbt {
    use std::bcs;
    use std::error;
    use std::option;
    use std::signer;
    use std::string;
    use std::string::String;
    use std::vector;
    use aptos_std::ed25519;
    use aptos_framework::event;
    use aptos_framework::object;
    use aptos_framework::timestamp;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use edenx::edenx_resource;
    use edenx::admin;
    use edenx::genesis_sbt::has_genesis_sbt;

    const E_ACHIEVEMENT_SBT_EXISTS: u64 = 1;
    const E_ACHIEVEMENT_SBT_NOT_EXISTS: u64 = 2;
    const E_INVALID_LEVEL: u64 = 3;
    const E_INVALID_SIGNATURE: u64 = 4;
    const E_SIGNATURE_EXPIRED: u64 = 5;
    const E_NOT_WONER: u64 = 6;
    const E_LEVEL_NOT_COMPLETED: u64 = 7;
    const E_ACHIEVEMENT_ALREADY_UNLOCKED: u64 = 8;
    const E_INVALID_SKILL_TYPE: u64 = 9;
    const E_NO_GENESIS_SBT: u64 = 10;

    const COLLECTION_NAME: vector<u8> = b"EdenX Achievement";
    const COLLECTION_DECRIPTION: vector<u8> = b"Achievment Soulbound Tokens for EdenX Learners";
    const COLLECTION_URI: vector<u8> = b"https://edenx.io/api/collection/achievement";

    const SIGNATURE_VALIDITY_SECONDS: u64 = 300;

    const MAX_LEVEL: u8 = 100;

    const LEVEL_STATUS_NOT_STARTED: u8 = 0;
    const LEVEL_STATUS_IN_PROGRESS: u8 = 1;
    const LEVEL_STATUS_COMPLETED: u8 = 2;

    const RARITY_COMMON: u8 = 1;
    const RARITY_RARE: u8 = 2;
    const RARITY_EPIC: u8 = 3;
    const RARITY_LEGENDARY: u8 = 4;

    const SKILL_PROGRAMMING: u8 = 1;
    const SKILL_WEB3_FUNDAMENTALS: u8 = 2;
    const SKILL_BLOCKCHAIN_APPS: u8 = 3;

    struct LevelProgress has store, copy, drop {
        level_id: u8,
        status: u8,
        score: u64,
        completed_timestamp: u64,
    }

    struct Achievement has store, copy, drop {
        achievement_id: u64,
        name: String,
        rarity: u8,
        unlock_timestamp: u64,
    }

    struct SkillLevels has store, copy, drop {
        programming_level: u8,
        web3_fundamentals: u8,
        blockchain_apps: u8,
    }

    struct AchievementSBTData has key {
        owner: address,
        mint_timestamp: u64,

        current_level: u8,
        total_experience: u64,
        levels: vector<LevelProgress>,

        achievements: vector<Achievement>,

        total_study_time: u64,
        quiz_correct_rate: u64,
        streak_days: u64,

        skill_levels: SkillLevels,

        last_updated: u64,
    }

    struct UserAchievementMapping has key {
        token_address: address,
    }

    #[event]
    struct AchievementSBTMinted has drop, store {
        user: address,
        token_address: address,
        timestamp: u64,
    }

    #[event]
    struct LevelCompleted has drop, store {
        user: address,
        level_id: u8,
        score: u64,
        timestamp: u64,
    }

    #[event]
    struct AchievementUnlocked has drop, store {
        user: address,
        achievement_id: u64,
        achievement_name: String,
        rarity: u8,
        tiemstamp: u64,
    }

    #[event]
    struct SkillLevelUpdated has drop, store {
        user: address,
        skill_type: u8,
        old_level: u8,
        new_level: u8,
        timestamp: u64,
    }

    fun init_module(_deployer: &signer) {}

    public entry fun initialize_collection(admin: &signer) {
        admin::assert_is_admin(admin);

        let resource_signer = edenx_resource::get_resource_signer();

        collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(COLLECTION_DECRIPTION),
            string::utf8(COLLECTION_NAME),
            option::none(),
            string::utf8(COLLECTION_URI)
        );
    }

    public entry fun mint_achievement_sbt(user: &signer, backend_signature: vector<u8>, timestamp: u64) {
        let user_addr = signer::address_of(user);

        assert!(
            !has_achievement_sbt(user_addr),
            error::already_exists(E_ACHIEVEMENT_SBT_EXISTS)
        );

        assert!(
            has_genesis_sbt(user_addr),
            error::not_found(E_NO_GENESIS_SBT)
        );

        verify_mint_signature(user_addr, timestamp, backend_signature);

        let current_time = timestamp::now_seconds();
        assert!(
            current_time >= timestamp,
            error::invalid_state(E_SIGNATURE_EXPIRED)
        );
        assert!(
            current_time - timestamp <= SIGNATURE_VALIDITY_SECONDS,
            error::invalid_state(E_SIGNATURE_EXPIRED)
        );

        let token_name = string::utf8(b"EdenX Achievement SBT");
        let token_description = string::utf8(b"Track your learning journey in EdenX");
        let token_uri = string::utf8(b"https://edenx.io/api/sbt/achievement/metadata.json");

        let resource_signer = edenx_resource::get_resource_signer();

        let constructor_ref = token::create(
            &resource_signer,
            string::utf8(COLLECTION_NAME),
            token_description,
            token_name,
            option::none(),
            token_uri,
        );

        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, user_addr);

        object::disable_ungated_transfer(&transfer_ref);

        let mutator_ref = property_map::generate_mutator_ref(&constructor_ref);
        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Current Level"),
            0u64
        );
        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Total Experience"),
            0u64
        );
        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Achievements Unlocked"),
            0u64
        );
        property_map::add_typed(
            &mutator_ref,
            string::utf8(b"Transferable"),
            false
        );

        let skill_levels = SkillLevels {
            programming_level: 0,
            web3_fundamentals: 0,
            blockchain_apps: 0,
        };

        let token_signer = object::generate_signer(&constructor_ref);
        let token_address = signer::address_of(&token_signer);

        move_to(&token_signer, AchievementSBTData {
            owner: user_addr,
            mint_timestamp: current_time,
            current_level: 0,
            total_experience: 0,
            levels: vector::empty(),
            achievements: vector::empty(),
            total_study_time: 0,
            quiz_correct_rate: 0,
            streak_days: 0,
            skill_levels,
            last_updated: current_time,
        });

        move_to(user, UserAchievementMapping {
            token_address,
        });

        event::emit(AchievementSBTMinted {
            user: user_addr,
            token_address,
            timestamp: current_time
        });
    }

    public entry fun update_level_progress(user: &signer, level_id: u8, score: u64, experience_gained: u64, backend_signature: vector<u8>, timestamp: u64) acquires AchievementSBTData, UserAchievementMapping {
        let user_addr = signer::address_of(user);

        assert!(
            has_achievement_sbt(user_addr),
            error::not_found(E_ACHIEVEMENT_SBT_NOT_EXISTS)
        );

        assert!(
            level_id > 0 && level_id <= MAX_LEVEL,
            error::invalid_argument(E_INVALID_LEVEL)
        );

        verify_level_signature(
            user_addr,
            level_id,
            score,
            experience_gained,
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

        let token_address = get_achievement_token_address(user_addr);
        let achievement_data = borrow_global_mut<AchievementSBTData>(token_address);

        let new_level = LevelProgress {
            level_id,
            status: LEVEL_STATUS_COMPLETED,
            score,
            completed_timestamp: current_time
        };
        vector::push_back(&mut achievement_data.levels, new_level);

        achievement_data.total_experience = achievement_data.total_experience + experience_gained;

        if (level_id > 0 && level_id <= MAX_LEVEL) {
            achievement_data.current_level = level_id;
        };

        achievement_data.last_updated = current_time;

        event::emit(LevelCompleted {
            user: user_addr,
            level_id,
            score,
            timestamp: current_time
        });
    }

    public entry fun unlock_achievement(
        user: &signer,
        achievement_id: u64,
        achievement_name: vector<u8>,
        rarity: u8,
        backend_signature: vector<u8>,
        timestamp: u64
    ) acquires AchievementSBTData, UserAchievementMapping {
        let user_addr = signer::address_of(user);

        assert!(
            has_achievement_sbt(user_addr),
            error::not_found(E_ACHIEVEMENT_SBT_NOT_EXISTS)
        );

        verify_achievement_signature(
            user_addr,
            achievement_id,
            achievement_name,
            rarity,
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

        let token_address = get_achievement_token_address(user_addr);
        let achievement_data = borrow_global_mut<AchievementSBTData>(token_address);

        let achievements = &achievement_data.achievements;
        let len = vector::length(achievements);
        let i = 0;

        while (i < len) {
            let achievement = vector::borrow(achievements, i);
            assert!(
                achievement.achievement_id != achievement_id,
                error::already_exists(E_ACHIEVEMENT_ALREADY_UNLOCKED)
            );

            i = i + 1;
        };

        let new_achievement = Achievement {
            achievement_id,
            name: string::utf8(achievement_name),
            rarity,
            unlock_timestamp: current_time,
        };
        vector::push_back(&mut achievement_data.achievements, new_achievement);

        event::emit(AchievementUnlocked {
            user: user_addr,
            achievement_id,
            achievement_name: string::utf8(achievement_name),
            rarity,
            tiemstamp: current_time,
        });
    }

    public entry fun update_skill_level(
        user: &signer,
        skill_type: u8,
        new_level: u8,
        backend_signature: vector<u8>,
        timestamp: u64,
    ) acquires AchievementSBTData, UserAchievementMapping {
        let user_addr = signer::address_of(user);

        assert!(
            has_achievement_sbt(user_addr),
            error::not_found(E_ACHIEVEMENT_SBT_NOT_EXISTS)
        );

        assert!(
            is_valid_skill_type(skill_type),
            error::invalid_argument(E_INVALID_SKILL_TYPE)
        );

        verify_skill_signature(
            user_addr,
            skill_type,
            new_level,
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

        let token_address = get_achievement_token_address(user_addr);
        let achievement_data = borrow_global_mut<AchievementSBTData>(token_address);

        let old_level = get_skill_level(&achievement_data.skill_levels, skill_type);

        update_skill_level_internal(&mut achievement_data.skill_levels, skill_type, new_level);

        achievement_data.last_updated = current_time;

        event::emit(SkillLevelUpdated {
            user: user_addr,
            skill_type,
            old_level,
            new_level,
            timestamp: current_time,
        });
    }

    public fun has_achievement_sbt(user_addr: address): bool {
        exists<UserAchievementMapping>(user_addr)
    }

    public fun get_achievement_token_address(user_addr: address): address acquires UserAchievementMapping {
        let mapping = borrow_global<UserAchievementMapping>(user_addr);

        mapping.token_address
    }

    public fun get_skill_programming(): u8 { SKILL_PROGRAMMING }
    public fun get_skill_web3(): u8 { SKILL_WEB3_FUNDAMENTALS }
    public fun get_skill_apps(): u8 { SKILL_BLOCKCHAIN_APPS }

    public fun get_rarity_common(): u8 { RARITY_COMMON }
    public fun get_rarity_rare(): u8 { RARITY_RARE }
    public fun get_rarity_epic(): u8 { RARITY_EPIC }
    public fun get_rarity_legendary(): u8 { RARITY_LEGENDARY }

    fun update_skill_level_internal(skills: &mut SkillLevels, skill_type: u8, new_level: u8) {
        if (skill_type == SKILL_PROGRAMMING) {
            skills.programming_level = new_level;
        } else if (skill_type == SKILL_WEB3_FUNDAMENTALS) {
            skills.web3_fundamentals = new_level;
        } else if (skill_type == SKILL_BLOCKCHAIN_APPS) {
            skills.blockchain_apps = new_level;
        };
    }

    fun get_skill_level(skills: &SkillLevels, skill_type: u8): u8 {
        if (skill_type == SKILL_PROGRAMMING) {
            skills.programming_level
        } else if (skill_type == SKILL_WEB3_FUNDAMENTALS) {
            skills.web3_fundamentals
        } else if (skill_type == SKILL_BLOCKCHAIN_APPS) {
            skills.blockchain_apps
        } else {
            0
        }
    }

    fun verify_skill_signature(
        user_addr: address,
        skill_type: u8,
        new_level: u8,
        timestamp: u64,
        signature: vector<u8>
    ) {
        let message = construct_skill_message(user_addr, skill_type, new_level, timestamp);
        let public_key_bytes = admin::get_backend_public_key();
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(public_key_bytes);
        let signature_obj = ed25519::new_signature_from_bytes(signature);
        let is_valid = ed25519::signature_verify_strict(&signature_obj, &public_key, message);
        assert!(is_valid, error::invalid_argument(E_INVALID_SIGNATURE));
    }

    fun construct_skill_message(
        user_addr: address,
        skill_type: u8,
        new_level: u8,
        timestamp: u64
    ): vector<u8> {
        let message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&user_addr));
        vector::append(&mut message, bcs::to_bytes(&skill_type));
        vector::append(&mut message, bcs::to_bytes(&new_level));
        vector::append(&mut message, bcs::to_bytes(&timestamp));
        message
    }

    fun is_valid_skill_type(skill_type: u8): bool {
        skill_type == SKILL_PROGRAMMING ||
            skill_type == SKILL_WEB3_FUNDAMENTALS ||
            skill_type == SKILL_BLOCKCHAIN_APPS
    }

    fun verify_achievement_signature(
        user_addr: address,
        achievement_id: u64,
        achievement_name: vector<u8>,
        rarity: u8,
        timestamp: u64,
        signature: vector<u8>
    ) {
        let message = construct_achievement_message(user_addr, achievement_id, achievement_name, rarity, timestamp);
        let public_key_bytes = admin::get_backend_public_key();
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(public_key_bytes);
        let signature_obj = ed25519::new_signature_from_bytes(signature);
        let is_valid = ed25519::signature_verify_strict(&signature_obj, &public_key, message);
        assert!(is_valid, error::invalid_argument(E_INVALID_SIGNATURE));
    }

    fun construct_achievement_message(
        user_addr: address,
        achievement_id: u64,
        achievement_name: vector<u8>,
        rarity: u8,
        timestamp: u64
    ): vector<u8> {
        let message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&user_addr));
        vector::append(&mut message, bcs::to_bytes(&achievement_id));
        vector::append(&mut message, bcs::to_bytes(&achievement_name));
        vector::append(&mut message, bcs::to_bytes(&rarity));
        vector::append(&mut message, bcs::to_bytes(&timestamp));
        message
    }

    fun verify_level_signature(
        user_addr: address,
        level_id: u8,
        score: u64,
        experience: u64,
        timestamp: u64,
        signature: vector<u8>
    ) {
        let message = construct_level_message(user_addr, level_id, score, experience, timestamp);
        let public_key_bytes = admin::get_backend_public_key();
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(public_key_bytes);
        let signature_obj = ed25519::new_signature_from_bytes(signature);
        let is_valid = ed25519::signature_verify_strict(&signature_obj, &public_key, message);
        assert!(is_valid, error::invalid_argument(E_INVALID_SIGNATURE));
    }

    fun construct_level_message(
        user_addr: address,
        level_id: u8,
        score: u64,
        experience: u64,
        timestamp: u64
    ): vector<u8> {
        let message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&user_addr));
        vector::append(&mut message, bcs::to_bytes(&level_id));
        vector::append(&mut message, bcs::to_bytes(&score));
        vector::append(&mut message, bcs::to_bytes(&experience));
        vector::append(&mut message, bcs::to_bytes(&timestamp));
        message
    }

    fun verify_mint_signature(user_addr: address, timestamp: u64, signature: vector<u8>) {
        let message = construct_mint_message(user_addr, timestamp);
        let public_key_bytes = admin::get_backend_public_key();
        let public_key = ed25519::new_unvalidated_public_key_from_bytes(public_key_bytes);
        let signature_obj = ed25519::new_signature_from_bytes(signature);
        let is_valid = ed25519::signature_verify_strict(&signature_obj, &public_key, message);
        assert!(
            is_valid,
            error::invalid_argument(E_INVALID_SIGNATURE)
        );
    }

    fun construct_mint_message(user_addr: address, timestamp: u64): vector<u8> {
        let message = vector::empty<u8>();
        vector::append(&mut message, bcs::to_bytes(&user_addr));
        vector::append(&mut message, bcs::to_bytes(&timestamp));
        message
    }



    #[test_only]
    public fun initialize_for_test(deployer: &signer) {
        init_module(deployer);
    }

    #[test_only]
    public entry fun mint_achievement_sbt_for_test(user: &signer) {
        let user_addr = signer::address_of(user);

        assert!(
            !has_achievement_sbt(user_addr),
            error::already_exists(E_ACHIEVEMENT_SBT_EXISTS)
        );
        assert!(
            has_genesis_sbt(user_addr),
            error::not_found(E_NO_GENESIS_SBT)
        );

        let current_time = timestamp::now_seconds();

        let token_address = @0x0;

        move_to(user, UserAchievementMapping { token_address });

        event::emit(AchievementSBTMinted {
            user: user_addr,
            token_address,
            timestamp: current_time,
        });
    }
}