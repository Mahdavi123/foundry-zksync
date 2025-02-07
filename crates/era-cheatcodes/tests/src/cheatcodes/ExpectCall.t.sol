// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2 as console} from "../../lib/forge-std/src/Test.sol";
import {Constants} from "./Constants.sol";

contract Contract {
    function numberA() public pure returns (uint256) {
        return 1;
    }

    function numberB() public pure returns (uint256) {
        return 2;
    }

    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function pay(uint256 a) public payable returns (uint256) {
        return a;
    }
}

contract NestedContract {
    Contract private inner;

    constructor(Contract _inner) {
        inner = _inner;
    }

    function sum() public view returns (uint256) {
        return inner.numberA() + inner.numberB();
    }

    function forwardPay() public payable returns (uint256) {
        return inner.pay{gas: 50_000, value: 1}(1);
    }

    function addHardGasLimit() public view returns (uint256) {
        return inner.add{gas: 50_000}(1, 1);
    }

    function hello() public pure returns (string memory) {
        return "hi";
    }

    function sumInPlace(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b + 42;
    }
}

contract ExpectCallTest is Test {
    function exposed_callTargetNTimes(
        Contract target,
        uint256 a,
        uint256 b,
        uint256 times
    ) public pure {
        for (uint256 i = 0; i < times; i++) {
            target.add(a, b);
        }
    }

    function exposed_expectCallWithValue(
        Contract target,
        uint256 value,
        uint256 amount
    ) public {
        target.pay{value: value}(amount);
    }

    function testExpectCallWithData() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");

        this.exposed_callTargetNTimes(target, 1, 2, 1);
    }

    function testExpectMultipleCallsWithData() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");

        // Even though we expect one call, we're using additive behavior, so getting more than one call is okay.
        this.exposed_callTargetNTimes(target, 1, 2, 2);
    }

    function testExpectMultipleCallsWithDataAdditive() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");

        this.exposed_callTargetNTimes(target, 1, 2, 2);
    }

    function testExpectMultipleCallsWithDataAdditiveLowerBound() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");

        this.exposed_callTargetNTimes(target, 1, 2, 3);
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectMultipleCallsWithDataAdditive() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector, 1, 2)
    //         )
    //     );
    //     require(success, "expectCall failed");
    //     (success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector, 1, 2)
    //         )
    //     );
    //     require(success, "expectCall failed");
    //     (success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector, 1, 2)
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     // Not enough calls to satisfy the additive expectCall, which expects 3 calls.
    //     this.exposed_callTargetNTimes(target, 1, 2, 2);
    // }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCallWithData() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes,uint64)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector, 1, 2),
    //             1
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     this.exposed_callTargetNTimes(target, 3, 3, 1);
    // }

    function testExpectInnerCall() public {
        Contract inner = new Contract();
        NestedContract target = new NestedContract(inner);

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(inner),
                abi.encodeWithSelector(inner.numberB.selector)
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectInnerCall(target);
    }

    function exposed_expectInnerCall(NestedContract target) public view {
        target.sum();
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectInnerCall() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes)",
    //             address(inner),
    //             abi.encodeWithSelector(inner.numberB.selector)
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     this.exposed_failExpectInnerCall(target);
    // }

    function exposed_failExpectInnerCall(NestedContract target) public pure {
        // this function does not call inner
        target.hello();
    }

    // We should be able to match whichever function is called inside of the next call.
    // Even multiple functions.
    function testExpectCallMultipleFunctions() public {
        Contract inner = new Contract();
        NestedContract target = new NestedContract(inner);

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.forwardPay.selector)
            )
        );
        require(success, "expectCall failed");
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(inner),
                abi.encodeWithSelector(inner.pay.selector)
            )
        );
        require(success, "expectCall failed");

        this.exposed_forwardPay(target);
    }

    // We should also be able to match multiple functions that happen one after another,
    // but inside the next call.
    function testExpectCallMultipleFunctionsFlattened() public {
        Contract inner = new Contract();
        NestedContract target = new NestedContract(inner);

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.sumInPlace.selector)
            )
        );
        require(success, "expectCall failed");
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(inner),
                abi.encodeWithSelector(inner.add.selector)
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCallMultipleFunctionsFlattened(target, inner);
    }

    function exposed_expectCallMultipleFunctionsFlattened(
        NestedContract target,
        Contract inner
    ) public pure {
        target.sumInPlace(1, 1);
        inner.add(1, 1);
    }

    function testExpectSelectorCall() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector)
            )
        );
        require(success, "expectCall failed");

        this.exposed_callTargetNTimes(target, 5, 5, 1);
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectSelectorCall() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector)
    //         )
    //     );
    //     require(success, "expectCall failed");
    // }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCallWithMoreParameters() public {
    //     Contract target = new Contract();

    //         (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //             abi.encodeWithSignature(
    //                 "expectCall(address,bytes)",
    //                 address(target),
    //                 abi.encodeWithSelector(target.add.selector, 3, 3, 3)
    //             )
    //         );
    //         require(success, "expectCall failed");

    //     target.add(3, 3);
    //     this.exposed_callTargetNTimes(target, 3, 3, 1);
    // }

    function testExpectCallWithValue() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,uint256,bytes)",
                address(target),
                1,
                abi.encodeWithSelector(target.pay.selector, 2)
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCallWithValue(target, 1, 2);
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCallValue() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,uint256,bytes)",
    //             address(target),
    //             1,
    //             abi.encodeWithSelector(target.pay.selector, 2)
    //         )
    //     );
    //     require(success, "expectCall failed");
    // }

    function testExpectCallWithValueWithoutParameters() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,uint256,bytes)",
                address(target),
                3,
                abi.encodeWithSelector(target.pay.selector)
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCallWithValue(target, 3, 100);
    }

    // function testExpectCallWithValueAndGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCall(address(inner), 1, 50_000, abi.encodeWithSelector(inner.pay.selector, 1));
    //     this.exposed_forwardPay(target);
    // }

    function exposed_forwardPay(NestedContract target) public {
        target.forwardPay{value: 1}();
    }

    // function testExpectCallWithNoValueAndGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCall(address(inner), 0, 50_000, abi.encodeWithSelector(inner.add.selector, 1, 1));
    //     this.exposed_addHardGasLimit(target);
    // }

    // function exposed_addHardGasLimit(NestedContract target) public {
    //     target.addHardGasLimit();
    // }

    // function testFailExpectCallWithNoValueAndWrongGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCall(address(inner), 0, 25_000, abi.encodeWithSelector(inner.add.selector, 1, 1));
    //     this.exposed_addHardGasLimit(target);
    // }

    // function testExpectCallWithValueAndMinGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCallMinGas(address(inner), 1, 50_000, abi.encodeWithSelector(inner.pay.selector, 1));
    //     this.exposed_forwardPay(target);
    // }

    // function testExpectCallWithNoValueAndMinGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCallMinGas(address(inner), 0, 25_000, abi.encodeWithSelector(inner.add.selector, 1, 1));
    //     this.exposed_addHardGasLimit(target);
    // }

    // function testFailExpectCallWithNoValueAndWrongMinGas() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);
    //     vm.expectCallMinGas(address(inner), 0, 50_001, abi.encodeWithSelector(inner.add.selector, 1, 1));
    //     this.exposed_addHardGasLimit(target);
    // }

    // /// Ensure that you cannot use expectCall with an expectRevert.
    // function testFailExpectCallWithRevertDisallowed() public {
    //     Contract target = new Contract();
    //     vm.expectRevert();
    //     vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector));
    //     this.exposed_callTargetNTimes(target, 5, 5, 1);
    // }
}

contract ExpectCallCountTest is Test {
    function testExpectCallCountWithData() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2),
                3
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCallCountWithData(target);
    }

    function exposed_expectCallCountWithData(Contract target) public pure {
        target.add(1, 2);
        target.add(1, 2);
        target.add(1, 2);
    }

    function testExpectZeroCallCountAssert() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2),
                0
            )
        );
        require(success, "expectCall failed");
        target.add(3, 3);
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCallCountWithWrongCount() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes,uint64)",
    //             address(target),
    //             abi.encodeWithSelector(target.add.selector, 1, 2),
    //             2
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     target.add(1, 2);
    // }

    function testExpectCountInnerCall() public {
        Contract inner = new Contract();
        NestedContract target = new NestedContract(inner);

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(inner),
                abi.encodeWithSelector(inner.numberB.selector),
                1
            )
        );
        require(success, "expectCall failed");

        target.sum();
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCountInnerCall() public {
    //     Contract inner = new Contract();
    //     NestedContract target = new NestedContract(inner);

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,bytes,uint64)",
    //             address(inner),
    //             abi.encodeWithSelector(inner.numberB.selector),
    //             1
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     // this function does not call inner
    //     target.hello();
    // }

    function testExpectCountInnerAndOuterCalls() public {
        Contract inner = new Contract();
        NestedContract target = new NestedContract(inner);

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(inner),
                abi.encodeWithSelector(inner.numberB.selector),
                2
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCountInnerAndOuterCalls(inner, target);
    }

    function exposed_expectCountInnerAndOuterCalls(
        Contract inner,
        NestedContract target
    ) public view {
        inner.numberB();
        target.sum();
    }

    function exposed_pay(
        Contract target,
        uint256 value,
        uint256 amount
    ) public payable {
        target.pay{value: value}(amount);
    }

    function testExpectCallCountWithValue() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,uint256,bytes,uint64)",
                address(target),
                1,
                abi.encodeWithSelector(target.pay.selector, 2),
                1
            )
        );
        require(success, "expectCall failed");

        this.exposed_pay{value: 1}(target, 1, 2);
    }

    function testExpectZeroCallCountValue() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,uint256,bytes,uint64)",
                address(target),
                1,
                abi.encodeWithSelector(target.pay.selector, 2),
                0
            )
        );
        require(success, "expectCall failed");

        this.exposed_pay{value: 2}(target, 2, 2);
    }

    // TODO: uncomment once we have working reverts
    // function testFailExpectCallCountValue() public {
    //     Contract target = new Contract();

    //     (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
    //         abi.encodeWithSignature(
    //             "expectCall(address,uint256,bytes,uint64)",
    //             address(target),
    //             1,
    //             abi.encodeWithSelector(target.pay.selector, 2),
    //             1
    //         )
    //     );
    //     require(success, "expectCall failed");

    //     this.exposed_pay{value: 2}(target, 2, 2);
    // }

    function testExpectCallCountWithValueWithoutParameters() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,uint256,bytes,uint64)",
                address(target),
                3,
                abi.encodeWithSelector(target.pay.selector),
                3
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectCallCountWithValueWithoutParameters(target);
    }

    function exposed_expectCallCountWithValueWithoutParameters(
        Contract target
    ) public {
        target.pay{value: 3}(100);
        target.pay{value: 3}(100);
        target.pay{value: 3}(100);
    }

    //     function testExpectCallCountWithValueAndGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCall(address(inner), 1, 50_000, abi.encodeWithSelector(inner.pay.selector, 1), 2);
    //         this.exposed_expectCallCountWithValueAndGas(target);
    //     }

    //     function exposed_expectCallCountWithValueAndGas(NestedContract target) public {
    //         target.forwardPay{value: 1}();
    //         target.forwardPay{value: 1}();
    //     }

    //     function exposed_addHardGasLimit(NestedContract target, uint256 times) public {
    //         for (uint256 i = 0; i < times; i++) {
    //             target.addHardGasLimit();
    //         }
    //     }

    //     function testExpectCallCountWithNoValueAndGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCall(address(inner), 0, 50_000, abi.encodeWithSelector(inner.add.selector, 1, 1), 1);
    //         this.exposed_addHardGasLimit(target, 1);
    //     }

    //     function testExpectZeroCallCountWithNoValueAndWrongGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCall(address(inner), 0, 25_000, abi.encodeWithSelector(inner.add.selector, 1, 1), 0);
    //         this.exposed_addHardGasLimit(target, 1);
    //     }

    //     function testFailExpectCallCountWithNoValueAndWrongGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCall(address(inner), 0, 25_000, abi.encodeWithSelector(inner.add.selector, 1, 1), 2);
    //         this.exposed_addHardGasLimit(target, 2);
    //     }

    //     function testExpectCallCountWithValueAndMinGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCallMinGas(address(inner), 1, 50_000, abi.encodeWithSelector(inner.pay.selector, 1), 1);
    //         this.exposed_forwardPay(target);
    //     }

    //     function exposed_forwardPay(NestedContract target) public {
    //         target.forwardPay{value: 1}();
    //     }

    //     function testExpectCallCountWithNoValueAndMinGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCallMinGas(address(inner), 0, 25_000, abi.encodeWithSelector(inner.add.selector, 1, 1), 2);
    //         this.exposed_addHardGasLimit(target, 2);
    //     }

    //     function testExpectCallZeroCountWithNoValueAndWrongMinGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCallMinGas(address(inner), 0, 50_001, abi.encodeWithSelector(inner.add.selector, 1, 1), 0);
    //         this.exposed_addHardGasLimit(target, 1);
    //     }

    //     function testFailExpectCallCountWithNoValueAndWrongMinGas() public {
    //         Contract inner = new Contract();
    //         NestedContract target = new NestedContract(inner);
    //         vm.expectCallMinGas(address(inner), 0, 50_001, abi.encodeWithSelector(inner.add.selector, 1, 1), 1);
    //         this.exposed_addHardGasLimit(target, 1);
    //     }
}

contract ExpectCallMixedTest is Test {
    function exposed_callTargetNTimes(
        Contract target,
        uint256 a,
        uint256 b,
        uint256 times
    ) public pure {
        for (uint256 i = 0; i < times; i++) {
            target.add(a, b);
        }
    }

    //     function testFailOverrideNoCountWithCount() public {
    //         Contract target = new Contract();
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2));
    //         // You should not be able to overwrite a expectCall that had no count with some count.
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2), 2);
    //         this.exposed_callTargetNTimes(target, 1, 2, 2);
    //     }

    //     function testFailOverrideCountWithCount() public {
    //         Contract target = new Contract();
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2), 2);
    //         // You should not be able to overwrite a expectCall that had a count with some count.
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2), 1);
    //         target.add(1, 2);
    //         target.add(1, 2);
    //     }

    //     function testFailOverrideCountWithNoCount() public {
    //         Contract target = new Contract();
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2), 2);
    //         // You should not be able to overwrite a expectCall that had a count with no count.
    //         vm.expectCall(address(target), abi.encodeWithSelector(target.add.selector, 1, 2));
    //         target.add(1, 2);
    //         target.add(1, 2);
    //     }

    function testExpectMatchPartialAndFull() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(target),
                abi.encodeWithSelector(target.add.selector),
                2
            )
        );
        require(success, "expectCall failed");

        // Even if a partial match is specified, you should still be able to look for full matches
        // as one does not override the other.
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2)
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectMatchPartialAndFull(target);
    }

    function exposed_expectMatchPartialAndFull(Contract target) public pure {
        target.add(1, 2);
        target.add(1, 2);
    }

    function testExpectMatchPartialAndFullFlipped() public {
        Contract target = new Contract();

        (bool success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes)",
                address(target),
                abi.encodeWithSelector(target.add.selector)
            )
        );
        require(success, "expectCall failed");

        // Even if a partial match is specified, you should still be able to look for full matches
        // as one does not override the other.
        (success, ) = Constants.CHEATCODE_ADDRESS.call(
            abi.encodeWithSignature(
                "expectCall(address,bytes,uint64)",
                address(target),
                abi.encodeWithSelector(target.add.selector, 1, 2),
                2
            )
        );
        require(success, "expectCall failed");

        this.exposed_expectMatchPartialAndFullFlipped(target);
    }

    function exposed_expectMatchPartialAndFullFlipped(
        Contract target
    ) public pure {
        target.add(1, 2);
        target.add(1, 2);
    }
}
