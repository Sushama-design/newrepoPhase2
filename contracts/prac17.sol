// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return memory variable
CONCEPT: Memory lifecycle
=========================================================

OBJECTIVE

- Learn how memory variables work in Solidity
- Understand memory lifecycle during execution
- Learn how memory variables are returned
- Understand difference between memory and storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory variables:
- are temporary
- exist only during function execution
- disappear after execution finishes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Memory is used for:
- temporary data
- function arguments
- return values
- dynamic data handling

---------------------------------------------------------
MEMORY VS STORAGE
---------------------------------------------------------

MEMORY:
- temporary
- cheaper than storage
- cleared after execution

STORAGE:
- permanent
- expensive
- persists on blockchain

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory commonly used for:

- strings
- arrays
- structs
- temporary calculations
- returned data

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is memory used correctly?
- Is storage accidentally modified?
- Are memory copies intentional?
- Are references handled safely?
- Is unnecessary storage avoided?

=========================================================
*/

contract MemoryLifecycleVul {

    string public storedName = "Blockchain";

    function createMemoryVariable()
        public
        pure
        returns (uint256)
    {

        /*
            MEMORY-LIKE TEMPORARY VARIABLE

            localValue exists only during execution.
        */
        uint256 localValue = 100;

        /*
            Returning temporary variable.

            After function finishes:
            localValue disappears.
        */
        return localValue;
    }

    function returnMemoryString()
        public
        pure
        returns (string memory)
    {

        /*
            MEMORY STRING

            Strings are dynamic types.

            Solidity requires explicit memory keyword.
        */
        string memory tempName = "Solidity";

        /*
            tempName returned from memory.
        */
        return tempName;
    }

    function copyStorageToMemory()
        public
        view
        returns (string memory)
    {

        /*
            STORAGE -> MEMORY COPY

            storedName lives in storage.

            localCopy becomes temporary memory copy.
        */
        string memory localCopy = storedName;

        /*
            Changes to localCopy would NOT
            affect storedName.
        */
        return localCopy;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createMemoryVariable()

EVM ACTIONS:

1. Function execution starts
2. localValue created temporarily
3. localValue stored in stack/memory
4. Value returned
5. localValue destroyed after execution

---------------------------------------------------------

IMPORTANT:
Nothing stored permanently.

---------------------------------------------------------

CALL:
returnMemoryString()

EVM ACTIONS:

1. tempName allocated in memory
2. String stored temporarily
3. Memory data returned
4. Memory cleared after execution

---------------------------------------------------------

CALL:
copyStorageToMemory()

EVM ACTIONS:

1. Read storedName from storage
2. Create temporary memory copy
3. Return memory copy
4. Memory destroyed after execution

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createMemoryVariable()

EXPECTED:
100

---------------------------------------------------------

STEP 3:
Call:
returnMemoryString()

EXPECTED:
"Solidity"

---------------------------------------------------------

STEP 4:
Call:
copyStorageToMemory()

EXPECTED:
"Blockchain"

---------------------------------------------------------

STEP 5:
Check:
storedName()

EXPECTED:
"Blockchain"

OBSERVE:
Storage unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Repeated function calls

EXPECTED:
Memory recreated every execution

---------------------------------------------------------

TEST:
Return empty string

Modify code:
string memory tempName = "";

EXPECTED:
Returns empty string successfully

---------------------------------------------------------

TEST:
Large strings

OBSERVE:
More memory allocation
= higher gas usage

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

MEMORY LIFECYCLE

1. Memory allocated during execution
2. Temporary data stored
3. Function returns data
4. Memory cleared after execution

---------------------------------------------------------

VERY IMPORTANT

Memory does NOT persist on blockchain.

---------------------------------------------------------

THIS IS TEMPORARY:

string memory tempName;

---------------------------------------------------------

THIS IS PERSISTENT:

string public storedName;

=========================================================
MEMORY COPY BEHAVIOR
=========================================================

EXAMPLE:

string memory localCopy = storedName;

---------------------------------------------------------

WHAT HAPPENS?

1. storedName read from storage
2. Data copied into memory
3. localCopy becomes independent copy

---------------------------------------------------------

IMPORTANT

Changing localCopy does NOT modify storage.

=========================================================
GAS OBSERVATION
=========================================================

MEMORY:
Cheaper than storage

---------------------------------------------------------

STORAGE:
Expensive because blockchain state changes

---------------------------------------------------------

Returning memory data still consumes:
- execution gas
- memory expansion cost

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Common Solidity bug source.

Developers may think:
memory changes affect storage.

They do NOT.

---------------------------------------------------------
2. ACCIDENTAL STORAGE COPIES
---------------------------------------------------------

Auditors inspect:
- reference behavior
- unintended mutations
- data copying logic

---------------------------------------------------------
3. LARGE MEMORY ALLOCATION
---------------------------------------------------------

Huge arrays/strings may:
- consume excessive gas
- create DOS vectors

---------------------------------------------------------
4. RETURN DATA RISKS
---------------------------------------------------------

Returning excessive data may:
- exceed gas limits
- increase execution costs

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker provides huge input arrays/strings.

Result:
- excessive memory allocation
- increased gas consumption
- possible DOS behavior

---------------------------------------------------------

ANOTHER RISK

Developer expects memory update
to persist permanently.

Logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create memory array
2. Store values inside it
3. Return array from function

BONUS:
Compare memory array vs storage array.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory variables are temporary
- Memory cleared after execution
- Storage persists permanently
- Dynamic types commonly use memory
- Returning memory data is common
- Storage-to-memory creates copy
- Memory updates do not affect storage
- Memory cheaper than storage
- Large memory usage increases gas
- Auditors inspect memory behavior carefully

=========================================================
*/


/*


======================== Audit Report ========================

Title: Missing Demonstration of Memory Isolation Validation

Severity: Informational

Reason: The contract is educational and does not contain a direct exploitable vulnerability, but it lacks explicit validation demonstrating that memory mutations do not affect storage state.

Location:

Contract: MemoryLifecycleVul
Function: copyStorageToMemory()

Vulnerability Description:

The contract correctly demonstrates temporary memory variable behavior and storage-to-memory copying.

However, the educational example does not explicitly demonstrate that modifying a memory copy does not mutate persistent storage.

This may create misunderstanding for junior developers regarding:

* memory isolation
* storage persistence
* reference semantics
* dynamic type copying behavior

In real-world protocols, confusion between `storage` and `memory` can introduce:

* unintended state mutations
* failed updates
* authorization bypass assumptions
* accounting inconsistencies

The current implementation only copies storage into memory and returns the value without demonstrating mutation isolation.

Impact:

No direct exploitable vulnerability exists.

However, misunderstanding memory vs storage behavior may later lead to:

* incorrect protocol logic
* unintended state changes
* gas inefficiencies
* broken upgradeable storage assumptions

This is especially important when handling:

* structs
* arrays
* mappings
* dynamic strings/bytes

Proof of Concept:

Current implementation:

string memory localCopy = storedName;

creates a temporary memory copy.

But no mutation is performed to prove:

localCopy != storedName

after modification.

Root Cause:

The educational example demonstrates copying but not isolation after mutation.

Recommendation:

Explicitly modify the memory copy and compare it with storage state to demonstrate separation between memory and storage.

Example:
localCopy = "Modified";

while verifying:
storedName

remains unchanged.

 //--------------------- PATCH CODE ---------------------------

*/
contract MemoryLifecycleFixed {

    string public storedName = "Blockchain";

    function createMemoryVariable() public pure returns (uint256)
    {
        /*
            LOCAL TEMPORARY VARIABLE

            Exists only during execution.
        */
        uint256 localValue = 100;

        return localValue;
    }

    function returnMemoryString() public pure returns (string memory)
    {
        /*
            MEMORY STRING

            Dynamic types require explicit memory allocation.
        */
        string memory tempName = "Solidity";

        return tempName;
    }

    function copyStorageToMemory() public view returns ( string memory memoryValue, string memory storageValue )
    {
        /*
            STORAGE -> MEMORY COPY

            localCopy becomes independent temporary copy.
        */
        string memory localCopy = storedName;

        // PATCH ADDED:
        // Modify memory copy only
        // Does NOT affect storage variable
        localCopy = "Modified";

        /*
            Return both values to demonstrate:
            - memory copy changed
            - storage remained unchanged
        */
        return ( localCopy, storedName );
    }
}

//==================== MINI CHALLENGE CODE ========================== 


contract MemoryLifecycleFixedMin {

    // BONUS PATCH:
    // Persistent storage array
    // Lives permanently on blockchain
    uint256[] public storedNumbers;

    function createMemoryArray() public pure returns (uint256[] memory) {
        /*
            MEMORY ARRAY

            Temporary array existing only
            during function execution.
        */
        uint256[] memory tempArray = new uint256[](3);

        // PATCH ADDED:
        // Store values inside memory array
        tempArray[0] = 10;
        tempArray[1] = 20;
        tempArray[2] = 30;
        /*
            Returning temporary memory array.

            After execution finishes,
            tempArray disappears from memory.
        */
        return tempArray;
    }

    // BONUS PATCH:
    // Demonstrates difference between
    // memory array and storage array
    function storeNumber(uint256 _number) public {

        /*
            STORAGE WRITE

            Permanently modifies blockchain state.
        */
        storedNumbers.push(_number);
    }

    function getStoredNumbers() public view returns (uint256[] memory) {
        /*
            STORAGE -> MEMORY COPY

            Returning storage array creates
            temporary memory copy for output.
        */
        return storedNumbers;
    }
}