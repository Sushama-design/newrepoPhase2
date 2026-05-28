// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete array item
CONCEPT: Sparse array behavior
=========================================================

OBJECTIVE

- Learn how delete works on arrays
- Understand sparse array creation
- Learn why delete does not shrink arrays
- Understand risks caused by empty slots

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Using:

delete array[index];

DOES NOT:
- remove index
- shift elements
- reduce array length

It ONLY resets value to default.

---------------------------------------------------------
EXAMPLE
---------------------------------------------------------

Before delete:

[5, 10, 15]

After:
delete numbers[1];

Result:

[5, 0, 15]

Length still = 3

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

uint256 => 0
bool => false
address => address(0)

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can sparse arrays break logic?
- Are deleted entries handled safely?
- Does protocol incorrectly count empty slots?
- Can attackers abuse gaps?
- Is array cleanup implemented correctly?

=========================================================
*/

contract SparseArrayBehaviorVul {

    uint256[] public numbers;

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    function deleteItem(uint256 _index) public {
        delete numbers[_index];
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
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

---------------------------------------------------------

CALL:
addNumber(5)
addNumber(10)
addNumber(15)

ARRAY:

[5,10,15]

length = 3

---------------------------------------------------------

CALL:
deleteItem(1)

EVM ACTIONS:

1. EVM locates numbers[1]
2. Storage slot reset to default value
3. numbers[1] becomes 0

---------------------------------------------------------

FINAL ARRAY

[5,0,15]

IMPORTANT:
Length remains 3

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
addNumber(5)

---------------------------------------------------------

STEP 3:
Call:
addNumber(10)

---------------------------------------------------------

STEP 4:
Call:
addNumber(15)

---------------------------------------------------------

STEP 5:
Call:
getArray()

EXPECTED:
[5,10,15]

---------------------------------------------------------

STEP 6:
Call:
deleteItem(1)

---------------------------------------------------------

STEP 7:
Call:
getArray()

EXPECTED:
[5,0,15]

---------------------------------------------------------

STEP 8:
Call:
getLength()

EXPECTED:
3

OBSERVE:
Array size did not shrink.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Delete first element

deleteItem(0)

EXPECTED:
First value becomes 0

---------------------------------------------------------

TEST:
Delete last element

deleteItem(2)

EXPECTED:
Last value becomes 0

---------------------------------------------------------

TEST:
Delete invalid index

deleteItem(999)

EXPECTED:
Transaction reverts

Reason:
Index out of bounds

---------------------------------------------------------

TEST:
Delete same index twice

EXPECTED:
No error

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

ARRAY STORAGE

Arrays store values sequentially.

Example:

slot0 => array length
slot1 => numbers[0]
slot2 => numbers[1]
slot3 => numbers[2]

---------------------------------------------------------

DELETE OPERATION

delete numbers[1];

ONLY resets value.

Storage layout remains same.

---------------------------------------------------------

IMPORTANT

delete does NOT:
- remove slot
- shift values
- reduce length

=========================================================
DELETE VS POP
=========================================================

---------------------------------------------------------
DELETE
---------------------------------------------------------

delete numbers[1];

Result:
[5,0,15]

length = 3

---------------------------------------------------------
POP
---------------------------------------------------------

numbers.pop();

Result:
[5,10]

length = 2

---------------------------------------------------------

pop() only removes LAST element.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. SPARSE ARRAY BUGS
---------------------------------------------------------

Sparse arrays may break:
- reward systems
- counting logic
- voting mechanisms
- iteration assumptions

---------------------------------------------------------
2. LOOP RISKS
---------------------------------------------------------

Loops may incorrectly process:
0 values as valid entries.

---------------------------------------------------------
3. STORAGE FRAGMENTATION
---------------------------------------------------------

Repeated delete operations create:
- fragmented storage
- inefficient arrays
- wasted gas

---------------------------------------------------------
4. BUSINESS LOGIC FAILURES
---------------------------------------------------------

If 0 is meaningful,
deleted entries may bypass validations.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose array stores active stakers.

Attacker deletes entries repeatedly.

Result:
- empty gaps created
- reward logic breaks
- participant counting fails

---------------------------------------------------------

REAL-WORLD ISSUE

Sparse arrays have caused:
- governance bugs
- staking calculation errors
- incorrect payout distribution

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Item is removed completely
2. Elements shift left
3. Array length decreases

Example:

Before:
[5,10,15]

Remove index 1

After:
[5,15]

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- delete resets value to default
- delete does NOT remove array index
- delete does NOT reduce length
- Sparse arrays contain gaps
- Arrays remain sequential in storage
- pop() differs from delete
- Sparse arrays may break protocol logic
- Invalid indexes revert
- Auditors inspect cleanup logic carefully
- Storage fragmentation affects efficiency

=========================================================
*/

/*
======================== Audit Report ========================

Audit Report

Title: Sparse Array Creation Through Improper delete Usage

Severity: Medium

Reason: The contract uses delete on array elements, which resets values to default but does not reduce array length. This creates sparse arrays containing empty gaps.

Location:

Contract: SparseArrayBehavior
Function: deleteItem()

Vulnerability Description:
The deleteItem() function uses:

delete numbers[_index];

on a dynamic array element.

In Solidity, using delete on an array index:

* resets the value to default (`0`)
* DOES NOT remove the element
* DOES NOT decrease array length

This creates sparse arrays with empty slots.

Example:

Before delete:

[10, 20, 30]

After:
delete numbers[1]

Result:
[10, 0, 30]

Array length remains:
3

instead of shrinking to 2.

Impact:
Sparse arrays may cause:

* incorrect iteration logic
* unexpected zero values
* accounting inconsistencies
* frontend/UI confusion
* inefficient storage management

If this array controlled:

* user balances
* active positions
* staking entries
* whitelist indexes

then deleted gaps could break protocol assumptions and create logic bugs.

Proof of Concept:

Deploy the contract.

Call:

addNumber(10)
addNumber(20)
addNumber(30)

Array becomes:

[10,20,30]


Call:

deleteItem(1)


Array becomes:

[10,0,30]


Length remains:

solidity id="jlwm10"
3


The element was reset but not removed.

Root Cause:
The contract incorrectly assumes delete removes array elements completely.

However:

delete numbers[_index];

only resets the value to default and keeps the slot allocated.

No array compaction or length reduction logic exists.

Recommendation:
Use swap-and-pop pattern to properly remove array elements.

Recommended flow:

1. Move last element into target index
2. Remove last element using pop()

Also validate index bounds before deletion.

Example:

numbers[_index] = numbers[numbers.length - 1];
numbers.pop();


 --------------------- PATCH CODE ---------------------------
 
 */
 contract SparseArrayBehavior {

    uint256[] public numbers;

    function addNumber(uint256 _number) public {

        // Adds new number to dynamic array
        numbers.push(_number);
    }

    function deleteItem(uint256 _index) public {

        // PATCH ADDED:
        // Prevent invalid index access
        require(
            _index < numbers.length,
            "Invalid index"
        );

        // PATCH ADDED:
        // Move last element into deleted slot
        // This avoids empty gaps in array
        numbers[_index] =
            numbers[numbers.length - 1];

        // PATCH ADDED:
        // Removes last element
        // Properly decreases array length
        numbers.pop();
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }

    function getLength()
        public
        view
        returns (uint256)
    {
        return numbers.length;
    }
}

/*

/*
==================== MINI CHALLENGE CODE ========================== 
*/


contract SparseArrayBehaviorMin {

    uint256[] public numbers;

    function addNumber(uint256 _number) public {

        // Adds new element to array
        numbers.push(_number);
    }

    function deleteItem(uint256 _index) public {

        // Prevent invalid index access
        require(_index < numbers.length, "Invalid index" );

        // SHIFT LEFT LOGIC
        // Move every element one step left
        // starting from the deleted index
        for ( uint256 i = _index; i < numbers.length - 1; i++ ) {

            // Replace current element
            // with next element
            numbers[i] = numbers[i + 1];
        }

        // Remove duplicate last element
        // and reduce array length
        numbers.pop();
    }

    function getArray() public view returns (uint256[] memory)
    {
        return numbers;
    }

    function getLength() public view returns (uint256)
    {
        return numbers.length;
    }
}