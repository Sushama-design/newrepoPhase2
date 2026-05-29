// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use storage reference variable
CONCEPT: Direct storage pointer
=========================================================

OBJECTIVE

- Learn how storage reference variables work
- Understand direct pointers to storage
- Learn difference between storage and memory
- Understand how modifying storage references
  directly changes blockchain state

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

A storage reference variable points directly
to an existing storage location.

Example:

User storage user = users[id];

This does NOT create copy.

Instead:
user becomes POINTER to storage.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Modifying storage reference:

user.age = 50;

directly updates blockchain storage.

---------------------------------------------------------
STORAGE VS MEMORY
---------------------------------------------------------

STORAGE:
- permanent
- expensive
- modifies blockchain state
- acts like pointer/reference

MEMORY:
- temporary copy
- disappears after execution
- modifying memory does NOT update storage

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Storage references are heavily used in:

- DeFi protocols
- staking systems
- NFT marketplaces
- governance contracts
- user profile systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Are storage references intentional?
- Is accidental mutation possible?
- Are references pointing correctly?
- Is storage corruption possible?
- Is memory/storage confusion present?

=========================================================
*/

contract StorageReferenceVul {

    struct User {

        uint256 age;

        bool active;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {

        users[msg.sender] = User(_age, true);
    }

    function updateAge(uint256 _newAge) public {

        /*
            STORAGE REFERENCE VARIABLE

            This creates POINTER to actual storage.

            user is NOT copy.

            user directly references:
            users[msg.sender]
        */
        User storage user = users[msg.sender];

        /*
            DIRECT STORAGE MUTATION

            Since user points to storage,
            this updates blockchain state directly.
        */
        user.age = _newAge;
    }

    function deactivateUser() public {

        /*
            Another storage reference example
        */
        User storage user = users[msg.sender];

        user.active = false;
    }

    function getMyData()
        public
        view
        returns (uint256, bool)
    {
        User storage user = users[msg.sender];

        return (user.age, user.active);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

users[msg.sender]:

age = 0
active = false

---------------------------------------------------------

CALL:
createUser(25)

RESULT:

users[msg.sender]:
age = 25
active = true

---------------------------------------------------------

CALL:
updateAge(40)

EVM ACTIONS:

1. Mapping storage slot located
2. Storage reference created
3. user points directly to storage
4. user.age updated
5. Blockchain state mutated

---------------------------------------------------------

FINAL STATE

users[msg.sender]:
age = 40
active = true

---------------------------------------------------------

IMPORTANT

No copy created.

Storage reference directly modifies storage.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createUser(25)

---------------------------------------------------------

STEP 3:
Call:
getMyData()

EXPECTED:
25, true

---------------------------------------------------------

STEP 4:
Call:
updateAge(99)

---------------------------------------------------------

STEP 5:
Call:
getMyData()

EXPECTED:
99, true

OBSERVE:
Storage updated permanently.

---------------------------------------------------------

STEP 6:
Call:
deactivateUser()

EXPECTED:
99, false

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Update before createUser()

EXPECTED:
Works on default struct values

---------------------------------------------------------

TEST:
Repeated updates

EXPECTED:
Latest storage state persists

---------------------------------------------------------

TEST:
Different Remix accounts

EXPECTED:
Each address has isolated struct storage

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

THIS LINE:

User storage user = users[msg.sender];

creates STORAGE POINTER.

---------------------------------------------------------

VERY IMPORTANT

This is NOT copy:

User memory user = users[msg.sender];

would create temporary copy instead.

---------------------------------------------------------

STORAGE REFERENCE

Changes affect blockchain storage immediately.

---------------------------------------------------------

MEMORY COPY

Changes affect temporary copy only.

=========================================================
STORAGE VS MEMORY EXAMPLE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

User storage user = users[msg.sender];

user.age = 50;

RESULT:
Blockchain storage updated.

---------------------------------------------------------
MEMORY
---------------------------------------------------------

User memory user = users[msg.sender];

user.age = 50;

RESULT:
Only temporary copy changes.

Original storage unchanged.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. ACCIDENTAL STORAGE MUTATION
---------------------------------------------------------

Developers may accidentally modify
real storage when expecting copy.

This causes unintended state changes.

---------------------------------------------------------
2. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Very common Solidity bug source.

Auditors carefully inspect:
- reference types
- assignment behavior
- mutation side effects

---------------------------------------------------------
3. UNEXPECTED SIDE EFFECTS
---------------------------------------------------------

Changing storage references may:
- alter protocol state unexpectedly
- corrupt accounting
- bypass assumptions

---------------------------------------------------------
4. GAS CONSIDERATIONS
---------------------------------------------------------

Storage writes are expensive.

Unnecessary mutations waste gas.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Improper storage references may allow:
- accidental balance updates
- corrupted staking records
- unintended ownership changes

---------------------------------------------------------

REAL-WORLD RISK

Many Solidity bugs happen because:
developers expect copy
but receive storage reference instead.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add function using MEMORY copy
2. Change memory values
3. Observe storage remains unchanged

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- storage creates direct reference/pointer
- Storage references mutate blockchain state
- memory creates temporary copy
- Storage persists permanently
- Storage writes consume gas
- Reference types behave differently
- Memory/storage confusion causes bugs
- Structs inside mappings commonly use storage refs
- Storage references can create side effects
- Auditors inspect pointer behavior carefully

=========================================================
*/

/*

======================== Audit Report ========================


Title: Missing User Existence Validation Before Storage Mutation

Severity: Low

Reason: Functions mutate storage references without verifying whether a valid user profile exists.

Location:

Contract: StorageReference
Function: updateAge()
Function: deactivateUser()

Vulnerability Description:

The contract uses storage reference variables correctly, but state-mutating functions do not validate whether a user has been initialized before modifying storage.

Functions such as:

* updateAge()
* deactivateUser()

directly create storage references to:

users[msg.sender]

If the user was never created through createUser(), Solidity automatically initializes default values in storage:

* age = 0
* active = false

This allows unintended state mutation on uninitialized user records.

Although not critical in this simple example, this pattern becomes dangerous in production systems where user existence determines:

* access rights
* staking eligibility
* KYC status
* governance participation
* reward accounting

Impact:

An attacker or unintended user can:

* mutate uninitialized storage entries
* create partially initialized user states
* bypass expected workflow assumptions

This may lead to inconsistent protocol state and logic errors in larger systems.

Proof of Concept:

1. Deploy the contract.

2. Without calling:
createUser(...)

3. Directly call:
updateAge(99);

4. Observe:
getMyData()

The mapping entry becomes partially initialized even though no user creation occurred.

Root Cause:

The contract assumes users already exist before mutating storage references.

No validation checks whether:
users[msg.sender]

contains initialized user data.

Recommendation:

Track user initialization state before allowing mutations.

Example:

require(user.active == true, "User does not exist");

Alternatively, add a dedicated initialized flag.
*/

 //--------------------- PATCH CODE ---------------------------


contract StorageReference {

    struct User {

        uint256 age;

        bool active;

        // PATCH ADDED:
        // Track whether user was initialized properly
        bool exists;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {

        // PATCH ADDED:
        // Prevent duplicate user creation
        require(!users[msg.sender].exists, "User already exists");

        users[msg.sender] = User({
            age: _age,
            active: true,
            exists: true
        });
    }

    function updateAge(uint256 _newAge) public {

        User storage user = users[msg.sender];

        // PATCH ADDED:
        // Ensure valid initialized user exists
        require(user.exists, "User does not exist");

        user.age = _newAge;
    }

    function deactivateUser() public {

        User storage user = users[msg.sender];

        // PATCH ADDED:
        // Prevent mutation of uninitialized records
        require(user.exists, "User does not exist");

        user.active = false;
    }

    function getMyData()
        public
        view
        returns (uint256, bool)
    {
        User storage user = users[msg.sender];

        return (user.age, user.active);
    }
}

//==================== MINI CHALLENGE CODE ========================== 

contract StorageReferenceMin {

    struct User {

        uint256 age;

        bool active;

        // PATCH ADDED:
        // Track whether user was initialized
        // Prevents interacting with default empty struct
        bool exists;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {

        // PATCH ADDED:
        // Prevent duplicate user creation
        require(
            !users[msg.sender].exists,
            "User already exists"
        );

        users[msg.sender] = User({
            age: _age,
            active: true,
            exists: true
        });
    }

    // PATCH ADDED:
    // Demonstrates MEMORY copy behavior
    // Changes here do NOT affect blockchain storage
    function testMemoryCopy()
        public
        view
        returns ( uint256 memoryAge, uint256 storageAge )
    {

        // PATCH ADDED:
        // Ensure valid initialized user exists
        require( users[msg.sender].exists, "User does not exist" );

        /*
            MEMORY COPY

            Creates temporary copy of storage data.

            memoryUser is independent from:
            users[msg.sender]

            Changes to memoryUser
            will NOT modify storage.
        */
        User memory memoryUser = users[msg.sender];

        // PATCH ADDED:
        // Modify MEMORY copy only
        memoryUser.age = 999;

        /*
            Return both values:

            memoryAge  -> modified temporary value
            storageAge -> original persistent value

            Demonstrates storage remains unchanged.
        */
        return ( memoryUser.age, users[msg.sender].age );
    }
}