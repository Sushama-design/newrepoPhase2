// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Copy storage array to memory
CONCEPT: Data copying behavior
=========================================================

OBJECTIVE

- Learn how storage arrays are copied into memory
- Understand copy behavior in Solidity
- Learn difference between storage reference and memory copy
- Understand why memory modifications do NOT affect storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When storage array is assigned to memory:

uint256[] memory temp = numbers;

A FULL COPY is created.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

After copying:

- temp becomes independent memory array
- original storage remains unchanged
- modifying temp does NOT affect storage

---------------------------------------------------------
STORAGE -> MEMORY COPY
---------------------------------------------------------

STORAGE:
Permanent blockchain data

MEMORY:
Temporary execution copy

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Storage-to-memory copying used in:

- batch processing
- temporary calculations
- sorting
- filtering
- returning data safely

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is copy intentional?
- Is developer expecting reference?
- Are mutations safe?
- Is excessive copying expensive?
- Can large arrays create DOS?

=========================================================
*/

contract StorageToMemoryCopyVul {

    uint256[] public numbers;

    function addValues() public {

        /*
            STORE VALUES IN STORAGE ARRAY
        */
        numbers.push(10);

        numbers.push(20);

        numbers.push(30);
    }

    function copyArrayToMemory()
        public
        view
        returns (uint256[] memory)
    {

        /*
            STORAGE -> MEMORY COPY

            Entire storage array copied
            into temporary memory array.
        */
        uint256[] memory tempArray = numbers;

        /*
            Returning temporary copy
        */
        return tempArray;
    }

    function modifyMemoryCopy()
        public
        view
        returns (uint256[] memory)
    {

        /*
            Create memory copy
        */
        uint256[] memory tempArray = numbers;

        /*
            Modify MEMORY copy only
        */
        tempArray[0] = 999;

        /*
            Original storage remains unchanged
        */
        return tempArray;
    }

    function getStorageArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
addValues()

STORAGE ARRAY:

[10,20,30]

---------------------------------------------------------

CALL:
copyArrayToMemory()

EVM ACTIONS:

1. Storage array loaded
2. Full copy created in memory
3. tempArray becomes independent copy
4. Memory array returned
5. Memory cleared after execution

---------------------------------------------------------

CALL:
modifyMemoryCopy()

MEMORY COPY BEFORE:
[10,20,30]

AFTER MODIFICATION:
[999,20,30]

---------------------------------------------------------

IMPORTANT

ORIGINAL STORAGE STILL:

[10,20,30]

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
addValues()

---------------------------------------------------------

STEP 3:
Call:
getStorageArray()

EXPECTED:
[10,20,30]

---------------------------------------------------------

STEP 4:
Call:
copyArrayToMemory()

EXPECTED:
[10,20,30]

---------------------------------------------------------

STEP 5:
Call:
modifyMemoryCopy()

EXPECTED:
[999,20,30]

---------------------------------------------------------

STEP 6:
Call:
getStorageArray()

EXPECTED:
[10,20,30]

OBSERVE:
Storage unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Copy empty storage array

EXPECTED:
Returns empty memory array

---------------------------------------------------------

TEST:
Large arrays

OBSERVE:
Higher gas usage due to copying

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Fresh memory copy created each execution

=========================================================
IMPORTANT COPY UNDERSTANDING
=========================================================

THIS LINE:

uint256[] memory tempArray = numbers;

---------------------------------------------------------

DOES:
Create FULL COPY.

---------------------------------------------------------

DOES NOT:
Create storage reference.

=========================================================
MEMORY COPY BEHAVIOR
=========================================================

AFTER COPYING:

Storage Array:
[10,20,30]

Memory Array:
[10,20,30]

---------------------------------------------------------

AFTER MODIFYING MEMORY:

Storage:
[10,20,30]

Memory:
[999,20,30]

---------------------------------------------------------

IMPORTANT

Arrays become independent after copy.

=========================================================
STORAGE VS MEMORY REFERENCE
=========================================================

---------------------------------------------------------
MEMORY COPY
---------------------------------------------------------

uint256[] memory temp = numbers;

Creates independent copy.

---------------------------------------------------------
STORAGE REFERENCE
---------------------------------------------------------

uint256[] storage temp = numbers;

Creates direct pointer/reference.

Changes affect original storage.

=========================================================
GAS OBSERVATION
=========================================================

COPYING LARGE ARRAYS:
Expensive

---------------------------------------------------------

Reason:
Every element copied individually
from storage into memory.

---------------------------------------------------------

VERY LARGE ARRAYS:
May become DOS risk.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Common Solidity bug source.

Developers may incorrectly assume:
memory copy affects storage.

---------------------------------------------------------
2. DOS RISK
---------------------------------------------------------

Huge arrays may:
- consume excessive gas
- exceed block gas limits

---------------------------------------------------------
3. COPYING COST
---------------------------------------------------------

Large storage-to-memory copies
can become very expensive.

---------------------------------------------------------
4. REFERENCE ASSUMPTIONS
---------------------------------------------------------

Auditors verify:
whether developer intended:
- copy
OR
- direct storage reference

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker inflates storage array size.

Function copying array:
becomes too expensive.

Result:
Function becomes unusable.

---------------------------------------------------------

REAL-WORLD ISSUE

Large storage copying has caused:
- DOS vulnerabilities
- gas exhaustion
- scalability failures

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create storage reference variable
2. Modify referenced array
3. Observe storage changes directly

BONUS:
Compare:
memory copy vs storage reference

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage-to-memory creates full copy
- Memory copies are independent
- Memory changes do not affect storage
- Storage references behave differently
- Large array copying increases gas
- Memory cleared after execution
- Storage persists permanently
- Copying dynamic arrays is expensive
- Memory/storage confusion causes bugs
- Auditors inspect copy behavior carefully

=========================================================
*/

/*

======================== Audit Report ========================


Title: Missing Bounds Validation Before Memory Array Modification

Severity: Low

Reason: modifyMemoryCopy() assumes the storage array contains at least one element before modifying index 0.

Location:

Contract: StorageToMemoryCopy
Function: modifyMemoryCopy()

Vulnerability Description:

The modifyMemoryCopy() function creates a memory copy of the storage array and immediately modifies:

tempArray[0] = 999;

However, the function does not validate whether the original storage array contains any elements.

If numbers is empty, the memory array will also be empty, 
causing an out-of-bounds array access and transaction revert.

Although this does not create direct fund risk, missing bounds validation is considered 
unsafe array handling and can introduce denial-of-service conditions in more complex systems.

Impact:

If modifyMemoryCopy() is called before addValues(), the transaction reverts.

In larger protocols, similar unchecked array access patterns may cause:

* unexpected transaction failures
* denial-of-service conditions
* broken execution flows
* protocol instability

Proof of Concept:

1. Deploy the contract.

2. Call:
modifyMemoryCopy()

before calling:
addValues()

3. Transaction reverts because:
tempArray[0]

does not exist.

Root Cause:

The function assumes the array contains at least one element before accessing index 0.

No bounds validation exists before modifying the memory array.

Recommendation:

Validate array length before accessing array indexes.

Example:
require(tempArray.length > 0, "Empty array");
*/

 //--------------------- PATCH CODE ---------------------------


contract StorageToMemoryCopy {

    uint256[] public numbers;

    address public owner;

    constructor() {

        // PATCH ADDED:
        // Store contract owner
        owner = msg.sender;
    }

    function addValues() public {

        // PATCH ADDED:
        // Restrict storage mutation to owner
        require(msg.sender == owner, "Not owner");

        /*
            STORE VALUES IN STORAGE ARRAY
        */
        numbers.push(10);

        numbers.push(20);

        numbers.push(30);
    }

    function copyArrayToMemory()
        public
        view
        returns (uint256[] memory)
    {

        /*
            STORAGE -> MEMORY COPY

            Entire storage array copied
            into temporary memory array.
        */
        uint256[] memory tempArray = numbers;

        return tempArray;
    }

    function modifyMemoryCopy()
        public
        view
        returns (uint256[] memory)
    {

        /*
            Create memory copy
        */
        uint256[] memory tempArray = numbers;

        // PATCH ADDED:
        // Prevent out-of-bounds access
        require(
            tempArray.length > 0,
            "Empty array"
        );

        /*
            Modify MEMORY copy only
        */
        tempArray[0] = 999;

        /*
            Original storage remains unchanged
        */
        return tempArray;
    }

    function getStorageArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

//==================== MINI CHALLENGE CODE ========================== 


contract StorageToMemoryCopyMin {

    uint256[] public numbers;

    function addValues() public {

        numbers.push(10);

        numbers.push(20);

        numbers.push(30);
    }

    // PATCH ADDED:
    // Demonstrates STORAGE reference behavior
    // Changes directly affect blockchain storage
    function modifyStorageReference() public {

        /*
            STORAGE REFERENCE

            tempArray is NOT a copy.

            It directly references:
            numbers
        */
        uint256[] storage tempArray = numbers;

        // PATCH ADDED:
        // Directly modifies storage array
        tempArray[0] = 999;
    }

    // BONUS PATCH:
    // Compare MEMORY copy vs STORAGE reference
    function compareMemoryAndStorage()
        public
        view
        returns (
            uint256 memoryValue,
            uint256 storageValue
        )
    {

        require(numbers.length > 0, "Empty array");

        /*
            MEMORY COPY

            Independent temporary copy.
        */
        uint256[] memory memoryArray = numbers;

        /*
            Modify MEMORY copy only
        */
        memoryArray[0] = 555;

        /*
            STORAGE remains unchanged.

            memoryArray[0] -> 555
            numbers[0]     -> actual storage value
        */
        return (
            memoryArray[0],
            numbers[0]
        );
    }

    function getStorageArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

