// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Push multiple values into array
CONCEPT: Dynamic storage growth
=========================================================

OBJECTIVE

- Learn how arrays grow dynamically
- Understand repeated push() operations
- Learn how storage expands on-chain
- Understand gas implications of growing arrays

---------------------------------------------------------
CORE CONCEPT
---------------------------------------------------------

Dynamic arrays automatically increase in size
when new elements are pushed.

Each new value:
- gets new storage slot
- increases array length
- consumes additional gas

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Dynamic arrays are used for:

- transaction history
- staking participants
- NFT ownership records
- governance proposals
- vote tracking
- reward lists

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Blockchain storage is PERMANENT.

Every pushed value increases:
- storage usage
- blockchain state size
- future execution cost

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unlimited array growth
- storage abuse possibilities
- loop DOS vulnerabilities
- gas scalability problems
- attacker-controlled storage expansion

=========================================================
*/


contract DynamicArrayGrowthVul {

    uint256[] public numbers;

    function addMultipleValues(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) public {

        numbers.push(_value1);

        numbers.push(_value2);

        numbers.push(_value3);
    }

    function getNumber(uint256 _index)
        public
        view
        returns (uint256)
    {
        return numbers[_index];
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

numbers = []

length = 0

---------------------------------------------------------

CALL:
addMultipleValues(10, 20, 30)

EVM ACTIONS:

1. Function parameters arrive via calldata
2. First push() executes
3. Array length increases
4. Value stored in new slot

---------------------------------------------------------

FIRST PUSH

numbers[0] = 10

length = 1

---------------------------------------------------------

SECOND PUSH

numbers[1] = 20

length = 2

---------------------------------------------------------

THIRD PUSH

numbers[2] = 30

length = 3

---------------------------------------------------------

FINAL ARRAY

[10, 20, 30]

---------------------------------------------------------

CALL:
getNumber(1)

EXPECTED:
20

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
getLength()

EXPECTED:
0

---------------------------------------------------------

STEP 3:
Call:
addMultipleValues(10,20,30)

---------------------------------------------------------

STEP 4:
Call:
getLength()

EXPECTED:
3

---------------------------------------------------------

STEP 5:
Call:
getNumber(0)

EXPECTED:
10

---------------------------------------------------------

STEP 6:
Call:
getNumber(1)

EXPECTED:
20

---------------------------------------------------------

STEP 7:
Call:
getNumber(2)

EXPECTED:
30

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Push zeros

addMultipleValues(0,0,0)

EXPECTED:
Values stored successfully

---------------------------------------------------------

TEST:
Push very large values

EXPECTED:
Stored correctly

---------------------------------------------------------

TEST:
Call function repeatedly

Example:
addMultipleValues(1,2,3)
addMultipleValues(4,5,6)

EXPECTED ARRAY:

[1,2,3,4,5,6]

OBSERVE:
Array keeps growing dynamically.

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

DYNAMIC STORAGE GROWTH

Each push():
- allocates new storage slot
- increases permanent blockchain state

---------------------------------------------------------

STORAGE EXAMPLE

After first call:

slotA     => array length = 3
slotHash0 => 10
slotHash1 => 20
slotHash2 => 30

---------------------------------------------------------

AFTER SECOND CALL

length = 6

New values appended sequentially.

=========================================================
GAS OBSERVATION
=========================================================

MORE PUSH OPERATIONS
= MORE STORAGE WRITES
= HIGHER GAS COST

---------------------------------------------------------

Storage writes are among the MOST expensive
operations in Solidity.

Large arrays can become costly over time.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNBOUNDED STORAGE GROWTH
---------------------------------------------------------

Current contract has no limit.

Attackers can continuously grow array.

Risk:
- storage bloat
- higher execution costs
- protocol scalability issues

---------------------------------------------------------
2. LOOP DOS RISK
---------------------------------------------------------

Future loops over huge arrays may fail.

Example dangerous pattern:

for(uint i=0; i<numbers.length; i++)

Large arrays may exceed gas limit.

---------------------------------------------------------
3. ATTACKER-CONTROLLED STORAGE
---------------------------------------------------------

Users directly control storage expansion.

Auditors check:
- limits
- rate controls
- pruning mechanisms

---------------------------------------------------------
4. PERMANENT STATE EXPANSION
---------------------------------------------------------

Blockchain storage is expensive forever.

Poor storage design creates:
- protocol inefficiency
- long-term scaling issues

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker repeatedly calls:

addMultipleValues(...)

thousands of times.

RESULT:
- massive storage growth
- protocol becomes expensive
- loops become unusable

---------------------------------------------------------

REAL-WORLD ISSUE

Several smart contracts suffered DOS problems
because arrays became too large to process.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Maximum array length is 10
2. Further push attempts should fail

HINT:

Use:
require(numbers.length < 10)



=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Dynamic arrays grow automatically
- push() appends new elements
- Each push increases storage usage
- Storage growth increases gas cost
- Arrays persist permanently on-chain
- Repeated pushes create scalability concerns
- Large arrays can cause DOS vulnerabilities
- Unbounded storage is dangerous
- Auditors inspect storage growth carefully
- Gas efficiency matters in array design

=========================================================
*/



/*

======================== Audit Report ========================



Title: Unbounded Dynamic Array Growth Leading to Storage Bloat and Gas Exhaustion

Severity: Medium

Reason: Any external user can continuously increase on-chain storage, causing unnecessary protocol state growth and long-term gas inefficiency.

Location:

Contract: DynamicArrayGrowthVul
Function: addMultipleValues()

Vulnerability Description:

The addMultipleValues() function allows unrestricted array growth by permitting any external caller to continuously push values into the numbers array.

Since dynamic storage writes are permanent and expensive, attackers can repeatedly call this function to inflate contract storage indefinitely.

There are no:

* array size limits
* access controls
* rate limits
* cleanup mechanisms

This creates a storage-bloat vulnerability.

Impact:

An attacker can:

* massively increase contract storage usage
* increase long-term protocol operational costs
* make future interactions more gas expensive
* create denial-of-service conditions in functions that may later iterate over the array
* force state growth permanently on-chain

If future protocol upgrades introduce loops over numbers, the issue can escalate into a severe gas-based DoS vulnerability.

Proof of Concept:

1. Deploy the contract.

2. Repeatedly call:
addMultipleValues(1,2,3);

3. Observe:
getLength()

The array size continuously increases without restriction.

An attacker can automate this through scripting and create excessive storage growth.

Root Cause:

The contract allows unrestricted writes to a dynamic storage array.

No validation exists for:

* maximum array size
* authorized callers
* storage growth limits

Recommendation:

Implement protections such as:

* maximum array size restrictions
* access control
* pagination architecture
* storage cleanup mechanisms
* event-based off-chain tracking instead of permanent storage where possible

Example:
require(numbers.length + 3 <= MAX_SIZE, "Array limit reached");
*/
/*
 --------------------- PATCH CODE ---------------------------
*/
contract DynamicArrayGrowth {

    uint256[] public numbers;

    address public owner;

    // PATCH ADDED:
    // Define maximum storage growth limit
    // Prevents unlimited state expansion
    uint256 public constant MAX_SIZE = 100;

    constructor() {
        owner = msg.sender;
    }

    function addMultipleValues( uint256 _value1, uint256 _value2, uint256 _value3 ) public {

        // PATCH ADDED:
        // Restrict unauthorized state growth
        // Prevent arbitrary users from bloating storage
        require(msg.sender == owner, "Not owner");

        // PATCH ADDED:
        // Prevent unbounded array growth
        // Stops storage-bloat attacks
        require( numbers.length + 3 <= MAX_SIZE, "Array limit reached" );

        numbers.push(_value1);

        numbers.push(_value2);

        numbers.push(_value3);
    }

    function getNumber(uint256 _index) public view returns (uint256)
    {

        // PATCH ADDED:
        // Prevent invalid array access
        // Avoid out-of-bounds revert confusion
        require(_index < numbers.length, "Invalid index");

        return numbers[_index];
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}
/*
==================== MINI CHALLENGE CODE ========================== 
*/


contract DynamicArrayGrowthFixedMin {

    uint256[] public numbers;

    function addMultipleValues(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) public {

        // PATCH ADDED:
        // Prevent array from exceeding maximum size
        // Stops unlimited storage growth
        require(
            numbers.length + 3 <= 10,
            "Maximum array length reached"
        );

        numbers.push(_value1);

        numbers.push(_value2);

        numbers.push(_value3);
    }

    function getNumber(uint256 _index)
        public
        view
        returns (uint256)
    {

        // PATCH ADDED:
        // Prevent invalid index access
        require(_index < numbers.length, "Invalid index");

        return numbers[_index];
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}
