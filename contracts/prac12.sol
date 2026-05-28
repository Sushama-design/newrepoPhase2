// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare storage before/after tx
CONCEPT: State persistence
=========================================================

OBJECTIVE

- Learn how blockchain state changes after transactions
- Understand persistence of storage variables
- Compare state BEFORE and AFTER execution
- Learn why transactions permanently modify storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Before transaction:
Storage contains OLD state

After transaction:
Storage contains UPDATED state

Blockchain permanently stores
latest contract state.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Transactions:
- modify blockchain state
- consume gas
- persist changes permanently

view functions:
- only read state
- do NOT modify storage

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

State persistence is critical in:

- token balances
- staking systems
- ownership tracking
- DeFi protocols
- NFT ownership
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Was state updated correctly?
- Did transaction modify intended storage?
- Can state become corrupted?
- Is old state unexpectedly overwritten?
- Are updates atomic and safe?

=========================================================
*/

contract StatePersistenceVul {

    uint256 public counter;

    function increment() public {

        counter = counter + 1;
    }

    function setCounter(uint256 _value) public {

        counter = _value;
    }

    function getCounter() public view returns (uint256) {

        return counter;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

counter = 0

Stored permanently in blockchain storage.

---------------------------------------------------------

CALL:
increment()

BEFORE TX:
counter = 0

EVM ACTIONS:

1. Transaction reaches contract
2. Current storage value loaded
3. counter + 1 calculated
4. Storage slot updated
5. New value persisted

AFTER TX:
counter = 1

---------------------------------------------------------

CALL:
increment()

BEFORE TX:
counter = 1

AFTER TX:
counter = 2

---------------------------------------------------------

CALL:
setCounter(100)

BEFORE TX:
counter = 2

AFTER TX:
counter = 100

---------------------------------------------------------

IMPORTANT OBSERVATION

State persists BETWEEN transactions.

Every new transaction sees
latest stored value.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

EXPECTED:
counter() => 0

---------------------------------------------------------

STEP 2:
Call:
increment()

EXPECTED:
counter() => 1

---------------------------------------------------------

STEP 3:
Call:
increment()

EXPECTED:
counter() => 2

---------------------------------------------------------

STEP 4:
Call:
setCounter(999)

EXPECTED:
counter() => 999

---------------------------------------------------------

STEP 5:
Refresh Remix UI

EXPECTED:
counter still equals 999

OBSERVE:
Storage persists permanently.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Set counter to 0

EXPECTED:
Storage resets to 0

---------------------------------------------------------

TEST:
Repeated transactions

increment()
increment()
increment()

EXPECTED:
Counter increases sequentially

---------------------------------------------------------

TEST:
Large uint256 values

EXPECTED:
Works correctly in Solidity ^0.8.x

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

STATE BEFORE TX

Storage contains previous blockchain state.

---------------------------------------------------------

STATE AFTER TX

Updated values become new permanent state.

---------------------------------------------------------

VERY IMPORTANT

Each transaction:
- reads current storage
- modifies storage
- commits updated state

---------------------------------------------------------

BLOCKCHAIN PERSISTENCE

Storage survives:
- new transactions
- page refreshes
- node restarts

=========================================================
EVM INTERNAL FLOW
=========================================================

increment()

1. Read counter from storage
2. Load into EVM stack
3. Perform addition
4. Write updated value back to storage
5. Persist state to blockchain

---------------------------------------------------------

counter variable lives in STORAGE.

Temporary computation happens in:
- stack
- memory

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. STATE CONSISTENCY
---------------------------------------------------------

Auditors verify:
- storage updated correctly
- no partial updates
- no unexpected overwrites

---------------------------------------------------------
2. RACE CONDITIONS
---------------------------------------------------------

Multiple users may update same state.

Auditors inspect:
- ordering issues
- stale reads
- transaction assumptions

---------------------------------------------------------
3. ACCESS CONTROL
---------------------------------------------------------

Current issue:
ANYONE can modify counter.

Danger if counter controls:
- protocol settings
- rewards
- treasury logic

---------------------------------------------------------
4. PERSISTENT STATE RISKS
---------------------------------------------------------

Bad state changes persist permanently.

Incorrect updates may:
- corrupt protocol
- lock funds
- break logic forever

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose counter tracks:
- reward multiplier
- treasury percentage
- governance threshold

Attacker calls:

setCounter(999999)

Impact:
Protocol behavior manipulated.

---------------------------------------------------------

ANOTHER RISK

Unexpected state persistence may:
- preserve malicious values
- maintain broken configuration
- cause long-term protocol damage

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Store previousCounter
2. Before every update:
   save old value

BONUS:
Emit event showing:
old value -> new value

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage persists across transactions
- Transactions permanently modify state
- view functions only read storage
- State before tx differs from after tx
- EVM reads then writes storage
- Storage updates consume gas
- Blockchain maintains latest state
- Incorrect state updates are dangerous
- Access control protects persistent state
- Auditors inspect state transitions carefully

=========================================================
*/



/* 

======================== Audit Report ========================



Title: Missing Access Control on Critical State Modification Functions

Severity: Medium

Reason: Any external user can arbitrarily modify the `counter` state variable through unrestricted public functions.

Location:

Contract: StatePersistence
Functions:

* increment()
* setCounter()

Vulnerability Description:
The contract exposes two public functions that directly modify protocol state:

function increment() public {
    counter = counter + 1;
}

and

function setCounter(uint256 _value) public {
    counter = _value;
}

No authorization checks exist before updating storage.

As a result:

* any user can increment the counter
* any user can overwrite the counter with arbitrary values

The state variable:
uint256 public counter;

is globally mutable by all external callers.

Impact:
Attackers can manipulate contract state without restriction.

Example attacks:

* force unexpected counter increments
* overwrite counter with arbitrary values
* disrupt protocol assumptions

If this variable controlled:

* protocol configuration
* treasury accounting
* governance state
* voting rounds
* reward distribution

then unauthorized users could manipulate protocol behavior.

Proof of Concept:

Deploy the contract.

Initial value:
counter = 0

Attacker calls:
increment()

Counter becomes:
1

Attacker then calls:
setCounter(999999)

Counter becomes:

999999

Unauthorized state modification succeeds.

Root Cause:
The contract declares state-modifying functions as public without implementing access control.

Missing protection:

require(msg.sender == owner);

No ownership or authorization mechanism restricts state updates.

Recommendation:
Restrict state-modifying functions to authorized users only.

Recommended protections:

* add owner variable
* initialize owner in constructor
* validate caller before modifying storage

Example:

require(msg.sender == owner, "Not owner");
*/
/*

 --------------------- PATCH CODE ---------------------------

*/


contract StatePersistence {

    // Stores persistent counter value
    uint256 public counter;

    // PATCH ADDED:
    // Stores contract owner address
    address public owner;

    // PATCH ADDED:
    // Sets deployer as owner
    constructor() {
        owner = msg.sender;
    }

    function increment() public {

        // PATCH ADDED:
        // Restricts access to owner only
        require( msg.sender == owner, "Not owner" );

        // Increases counter by 1
        counter = counter + 1;
    }

    function setCounter(uint256 _value) public {

        // PATCH ADDED:
        // Restricts arbitrary counter updates
        require( msg.sender == owner, "Not owner" );

        // Updates counter value
        counter = _value;
    }

    function getCounter() public view returns (uint256) {
        // Returns current counter
        return counter;
    }
}

/*
==================== MINI CHALLENGE CODE ========================== 
*/



contract StatePersistenceMin {

    // Stores current counter value
    uint256 public counter;

    // MINI CHALLENGE ADDED:
    // Stores previous counter value
    uint256 public previousCounter;

    // BONUS ADDED:
    // Event logs old value and new value
    event CounterUpdated( uint256 oldValue, uint256 newValue );

    function increment() public {

        // Save old counter value
        // BEFORE updating state
        previousCounter = counter;

        // Increment counter
        counter = counter + 1;

        // Emit state transition event
        emit CounterUpdated( previousCounter, counter );
    }

    function setCounter(uint256 _value) public {

        // Save old counter value
        // BEFORE overwriting counter
        previousCounter = counter;

        // Update counter
        counter = _value;

        // Emit update event
        emit CounterUpdated( previousCounter, counter );
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}
