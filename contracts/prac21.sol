// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Modify copied memory array
CONCEPT: Storage unaffected
=========================================================

OBJECTIVE

- Learn how copied memory arrays behave
- Understand storage remains unchanged
- Learn independent copy behavior
- Understand memory isolation from storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When storage array is copied into memory:

uint256[] memory temp = numbers;

A COMPLETELY SEPARATE copy is created.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

After copying:
- modifying memory affects ONLY memory
- original storage remains unchanged
- memory and storage become independent

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many Solidity bugs happen because developers:
- expect storage mutation
- but only modify memory copy

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory copies useful for:

- temporary calculations
- filtering
- sorting
- safe transformations
- read-only processing

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Did developer intend memory copy?
- Is storage expected to change?
- Are mutations happening safely?
- Can copying large arrays create DOS?
- Is memory/storage confusion present?

=========================================================
*/

contract ModifyCopiedMemoryArrayVul {

    uint256[] public numbers;

    function addValues() public {

        /*
            STORE VALUES PERMANENTLY
            inside storage array
        */
        numbers.push(100);

        numbers.push(200);

        numbers.push(300);
    }

    function modifyMemoryCopy()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory
        )
    {

        /*
            STORAGE -> MEMORY COPY

            tempArray becomes independent copy.
        */
        uint256[] memory tempArray = numbers;

        /*
            MODIFY MEMORY COPY ONLY
        */
        tempArray[0] = 999;

        /*
            RETURN:
            1. Modified memory copy
            2. Original storage array
        */
        return (tempArray, numbers);
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

[100,200,300]

---------------------------------------------------------

CALL:
modifyMemoryCopy()

EVM ACTIONS:

1. Storage array loaded
2. Full memory copy created
3. tempArray becomes independent
4. tempArray[0] modified
5. Memory copy changes only
6. Original storage untouched

---------------------------------------------------------

MEMORY ARRAY:

[999,200,300]

---------------------------------------------------------

ORIGINAL STORAGE ARRAY:

[100,200,300]

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
[100,200,300]

---------------------------------------------------------

STEP 4:
Call:
modifyMemoryCopy()

EXPECTED RETURN:

Modified Memory:
[999,200,300]

Original Storage:
[100,200,300]

---------------------------------------------------------

STEP 5:
Call:
getStorageArray()

EXPECTED:
[100,200,300]

OBSERVE:
Storage unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Copy empty storage array

EXPECTED:
Empty arrays returned

---------------------------------------------------------

TEST:
Modify multiple memory indexes

EXPECTED:
Only memory copy changes

---------------------------------------------------------

TEST:
Repeated function calls

OBSERVE:
Fresh memory copy created every execution

=========================================================
IMPORTANT COPY UNDERSTANDING
=========================================================

THIS LINE:

uint256[] memory tempArray = numbers;

---------------------------------------------------------

CREATES:
Independent memory copy.

---------------------------------------------------------

DOES NOT CREATE:
Storage reference.

=========================================================
MEMORY ISOLATION
=========================================================

BEFORE MODIFICATION

Storage:
[100,200,300]

Memory:
[100,200,300]

---------------------------------------------------------

AFTER MEMORY MODIFICATION

Storage:
[100,200,300]

Memory:
[999,200,300]

---------------------------------------------------------

IMPORTANT:
Storage remains unaffected.

=========================================================
MEMORY VS STORAGE REFERENCE
=========================================================

---------------------------------------------------------
MEMORY COPY
---------------------------------------------------------

uint256[] memory temp = numbers;

Independent copy.

---------------------------------------------------------
STORAGE REFERENCE
---------------------------------------------------------

uint256[] storage temp = numbers;

Direct pointer to storage.

Changes affect original array.

=========================================================
GAS OBSERVATION
=========================================================

COPYING ARRAYS:
Consumes gas

---------------------------------------------------------

Reason:
Every storage element copied into memory.

---------------------------------------------------------

VERY LARGE ARRAYS:
May become expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Extremely common Solidity issue.

Developers may expect:
storage updates

but only modify memory copy.

---------------------------------------------------------
2. SILENT LOGIC FAILURES
---------------------------------------------------------

Protocol logic may silently fail
because state never updates.

---------------------------------------------------------
3. DOS RISK
---------------------------------------------------------

Huge arrays copied into memory
may consume excessive gas.

---------------------------------------------------------
4. REFERENCE VALIDATION
---------------------------------------------------------

Auditors carefully inspect:
- copy semantics
- reference behavior
- mutation expectations

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker inflates storage array size.

Function copying arrays:
becomes too expensive.

Result:
DOS via gas exhaustion.

---------------------------------------------------------

ANOTHER RISK

Critical protocol update expected
to modify storage.

Developer accidentally modifies memory copy only.

Security logic silently breaks.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create STORAGE reference instead
2. Modify referenced array
3. Observe storage changes permanently

BONUS:
Compare:
memory copy vs storage reference behavior

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage-to-memory creates independent copy
- Memory modifications do not affect storage
- Memory arrays are temporary
- Storage persists permanently
- Memory and storage become isolated
- Copying arrays consumes gas
- Large copies may create DOS risks
- Storage references behave differently
- Memory/storage confusion causes bugs
- Auditors inspect reference semantics carefully

=========================================================
*/

/*

======================== Audit Report ========================


Title: Missing Array Length Validation Before Memory Modification

Severity: Low

Reason: The function modifies index 0 of a copied memory array without verifying that the array contains elements.

Location:

Contract: ModifyCopiedMemoryArray
Function: modifyMemoryCopy()

Vulnerability Description:

The modifyMemoryCopy() function copies the storage array into memory and immediately modifies:

tempArray[0] = 999;

However, no validation ensures the array contains at least one element.

If numbers is empty, the copied memory array will also be empty, causing an out-of-bounds access and transaction revert.

Although this contract is educational, unchecked array indexing is considered unsafe programming practice
and may introduce denial-of-service conditions in larger systems.

Impact:

Calling modifyMemoryCopy() before addValues() causes transaction failure.

In production protocols, similar unchecked array access may lead to:

* unexpected transaction reverts
* broken execution flows
* denial-of-service scenarios
* protocol instability

Proof of Concept:

1. Deploy the contract.

2. Without calling:
addValues()

3. Call:
modifyMemoryCopy()

4. Transaction reverts because:
tempArray[0]

does not exist.

Root Cause:

The function assumes the copied array contains at least one element before modifying index 0.

No bounds validation exists.

Recommendation:

Validate array length before modifying indexed elements.

Example:
require(tempArray.length > 0, "Empty array");


 --------------------- PATCH CODE ---------------------------

*/
contract ModifyCopiedMemoryArray {

    uint256[] public numbers;

    address public owner;

    constructor() {

        // PATCH ADDED:
        // Store authorized owner
        owner = msg.sender;
    }

    function addValues() public {

        // PATCH ADDED:
        // Restrict storage writes
        require(msg.sender == owner, "Not owner");

        /*
            STORE VALUES PERMANENTLY
            inside storage array
        */
        numbers.push(100);

        numbers.push(200);

        numbers.push(300);
    }

    function modifyMemoryCopy() public view returns ( uint256[] memory, uint256[] memory ) {
        /*
            STORAGE -> MEMORY COPY

            tempArray becomes independent copy.
        */
        uint256[] memory tempArray = numbers;

        // PATCH ADDED:
        // Prevent out-of-bounds access
        require( tempArray.length > 0, "Empty array" );
        /*
            MODIFY MEMORY COPY ONLY
        */
        tempArray[0] = 999;

        /*
            RETURN:
            1. Modified memory copy
            2. Original storage array
        */
        return (tempArray, numbers);
    }

    function getStorageArray() public view returns (uint256[] memory)
    {
        return numbers;
    }
}


//==================== MINI CHALLENGE CODE ========================== 


contract ModifyCopiedMemoryArrayMin {

    uint256[] public numbers;

    function addValues() public {

        /*
            STORE VALUES PERMANENTLY
            inside storage array
        */
        numbers.push(100);

        numbers.push(200);

        numbers.push(300);
    }

    // PATCH ADDED:
    // Demonstrates STORAGE reference behavior
    // Changes persist permanently
    function modifyStorageReference()public returns ( uint256[] memory ) {
        // PATCH ADDED:
        // Prevent invalid index access
        require(numbers.length > 0, "Empty array");

        /*
            STORAGE REFERENCE

            tempArray is NOT copy.

            It directly references:
            numbers
        */
        uint256[] storage tempArray = numbers;

        /*
            MODIFY STORAGE REFERENCE

            This permanently changes blockchain state.
        */
        tempArray[0] = 999;

        /*
            Storage array now becomes:
            [999,200,300]
        */
        return numbers;
    }

    // BONUS PATCH:
    // Compare MEMORY copy vs STORAGE reference
    function compareMemoryVsStorage() public view returns ( uint256 memoryValue, uint256 storageValue ) {

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
        return ( memoryArray[0], numbers[0] );
    }

    function getStorageArray() public view returns (uint256[] memory) {
        return numbers;
    }
}
