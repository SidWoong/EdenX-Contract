# **EdenX Dual SBT System**

A complete solution for **on-chain identity + learning achievements**

------

## **System Overview**

EdenX uses a **dual SBT (Soulbound Token) architecture** to separate the management of user identity and learning data:

``````
Genesis SBT (Genesis Badge)         Achievement SBT (Achievement Badge)
      ↓                                  ↓
   Identity Layer                        Data Layer
   Immutable                             Updatable
   One-time                              Dynamic
``````

------

## **Architecture Design**

### **Dual SBT Layered Architecture**

``````
┌─────────────────────────────────────────────────────────┐
│                    User Account                          │
├─────────────────────┬───────────────────────────────────┤
│  Genesis SBT        │  Achievement SBT                  │
│  (Identity Layer)   │  (Data Layer)                     │
├─────────────────────┼───────────────────────────────────┤
│ • Career Type       │ • Current Level                   │
│ • Token ID          │ • Completed Tasks                 │
│ • Join Timestamp    │ • Achievements Earned             │
│ • Immutable         │ • Learning Duration               │
│                     │ • Answer Accuracy                 │
│                     │ • Dynamically Updatable           │
└─────────────────────┴───────────────────────────────────┘
``````

### **Why Dual SBTs?**

**Separation of Responsibilities**:

| **Dimension** | **Genesis SBT** | **Achievement SBT** |
| ------------- | --------------- | ------------------- |
| **Purpose**   | “Who you are”   | “What you learned”  |
| **Content**   | Identity marker | Learning record     |
| **Notes**     | Permanent ID    | Dynamic transcript  |

------

## **Genesis SBT Design**

### **1. Core Function**

**Identity Marker** – A unique credential for users in the EdenX ecosystem:

``````move
struct GenesisSBTData has key {
    career_type: u8,        // Career type
    owner: address,         // Owner
    mint_timestamp: u64,    // Join timestamp
    token_id: u64,          // Identity ID (user number)
}
``````

### **2. Career System**

``````move
const CAREER_HUNTER: u8 = 1;    // Hunter - Explore the on-chain world
const CAREER_BUILDER: u8 = 2;   // Builder - Build DApps
const CAREER_EXPLORER: u8 = 3;  // Explorer - Learn new knowledge
``````

**Design Considerations**:

- Career determines initial skill tree
- Influences Achievement SBT achievement paths
- Different careers have distinct visual representations

### **3. Soulbound Mechanism**

``````move
// Permanently disable transfers
let transfer_ref = object::generate_transfer_ref(&constructor_ref);
object::disable_ungated_transfer(&transfer_ref);
``````

**Guarantees**:

- Non-transferable at the type system level
- Cannot be traded by any means
- Permanently bound to user address

### **4. Minting Control**

**Backend Signature Verification**:

``````
// Construct message (BCS serialized)
message = BCS(user_addr) || BCS(career_type) || BCS(timestamp)

// Ed25519 signature verification
verify_signature(backend_signature, backend_public_key, message)

// Timestamp validation (5-minute validity)
assert!(current_time - timestamp <= 300);
``````

**Protection Mechanisms**:

- Prevent unauthorized minting
- Prevent replay attacks
- Each user can only mint once

------

## **📌 Note**

- **This is an ongoing project; new features are being added rapidly.**

- **Stay tuned for updates!**



