/// dach.t.sol -- test for dach.sol

// Copyright (C) 2019  Martin Lundfall

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "ds-test/test.sol";
import {Vat} from 'dss/vat.sol';
import {Pot} from 'dss/pot.sol';
import {Dai} from 'dss/dai.sol';
import {DaiJoin} from 'dss/join.sol';
import "../dach.sol";
import {ChaiSetup, UniswapSetup} from "./uniswap.t.sol";

contract FactoryLike {
  function initializeFactory(address) public {}
  function createExchange(address) public returns (address) {}
}

contract FrontRunner {
  Dach dach;
  constructor(Dach _dach) public {
    dach = Dach(_dach);
  }

  function frontRun(address sender, address receiver, uint amount, uint fee, uint nonce,
                    uint expiry, address relayer, uint8 v, bytes32 r, bytes32 s) public {
    dach.daiCheque(sender,receiver,amount,fee,nonce,expiry,relayer,v,r,s);
  }
}

contract Hevm {
    function warp(uint256) public;
}


contract DachTest is DSTest, ChaiSetup, UniswapSetup {

    Hevm hevm;
    FrontRunner frontRunner;
    uint preBalance;
    uint constant initialBalance = 100;

    //    Dai dai;
    //    Chai chai;
    Dach dach;
    uint constant chainId = 99;

    address payable ali = 0xc3455912Cf4bF115835A655c70bCeFC9cF4568eB; //I am the greatest, I said that even before I knew I was.
    address cal = 0x29C76e6aD8f28BB1004902578Fb108c507Be341b;
    address del = 0xdd2d5D3f7f1b35b7A0601D6A00DbB7D44Af58479; //the funky homosapien
    address acab = address(0xacab);


    function setUp() public {
      super.setUp();
      hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
      dach = new Dach();
      frontRunner = new FrontRunner(dach);
      daipermit_dach();
      chaipermit_dach();
      dai.transfer(ali, 100);             
      preBalance = 100 ether - 140;
      assertEq(dai.balanceOf(ali), 100);
      assertEq(dai.balanceOf(address(this)), preBalance);
      assertEq(ali.balance, 0);
      assertEq(dach.nonces(ali),0);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        // always rounds down
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        // always rounds down
        z = mul(x, RAY) / y;
    }
    uint constant RAY = 10 ** 27;

    function test_basic_sanity() public {
      assertTrue(true);
    }

    function test_dai_address() public {
        //The dai address generated by hevm
        //used for signature generation testing
        assertEq(address(dai), address(0x959DC1D68ba3a9f6959239135bcbc854b781eb9a));
        assertEq(address(dai), address(dach.dai()));
    }

    function test_dach_address() public {
        //The dai address generated by hevm
        //used for signature generation testing
        assertEq(address(dach), address(0xDa54dfB70A3a4d4fBc8865Bef49665934f789396));
    }


    function test_this_address() public {
      assertEq(address(this), address(0x47f5b4DDAFD69A6271f3E15518076e0305a2C722));
    }

    function test_domain_separator() public {
      assertEq(dach.DOMAIN_SEPARATOR(), keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(dach.name())), keccak256(bytes(dach.version())), chainId, address(dach))));
    }

    function daipermit_dach() public {
      bytes32 r = 0x48db45248db4cb5df659edc6d653389eb556c33a2de6a93f100632c201ab7870;
      bytes32 s = 0x2293b374b1565c9887dda38204b8f498388842620d355eb3c78a9bd18e72efe1;
      uint8 v = 27;
      dai.permit(ali, address(dach), 0, 0, true, v, r, s);
    }

    function chaipermit_dach() public {
      bytes32 r = 0x72e45f6b52efcdfceb115a90b9856bdc74d99dee4789c54c1b48f6e8f81cc79e;
      bytes32 s = 0x685de41a08e90cb482b497cf4b2657ea99f4a11f4e52b2b98c458a2b985b1f9c;
      uint8 v = 27;
      chai.permit(ali, address(dach), 0, 0, true, v, r, s);
    }

    
    function test_daicheque() public {
      bytes32 r = 0xf9fadf414a8024269f920a52b3c57b65430a6e01fd533556946c147e29e724fb;
      bytes32 s = 0x1c460d088c333dad51467e51a3859eed95742c9dba609b5dec54ba23f0144973;
      uint8 v = 27;
      dach.daiCheque(ali, del, 10, 1, 0, 0, address(this), v, r, s);
      assertEq(dach.nonces(ali),1);
      assertEq(dai.balanceOf(ali), 89);
      assertEq(dai.balanceOf(del), 10);
      assertEq(dai.balanceOf(address(this)), preBalance + 1);
    }

    function test_chaicheque() public {
      bytes32 r = 0x8b2d2b16b8dc9c7ec6bf53fba7feedc6dfc5f5453dea9f1387436fb27342f697;
      bytes32 s = 0x5e234c44efde7f59de9db26a2e49a346e5be5233b4f29267923e2d40d6986d38;
      uint8 v = 27;
      //Give ali some chai
      chai.join(ali, 100);
      assertEq(chai.balanceOf(ali), 100);
      dach.chaiCheque(ali, del, 10, 1, 0, 0, address(this), v, r, s);
      assertEq(dach.nonces(ali),1);
      assertEq(chai.balanceOf(ali), 89);
      assertEq(chai.balanceOf(del), 10);
      assertEq(chai.balanceOf(address(this)), 1);
    }

    
    function test_daicheque_frontrun() public {
      bytes32 r = 0xf9fadf414a8024269f920a52b3c57b65430a6e01fd533556946c147e29e724fb;
      bytes32 s = 0x1c460d088c333dad51467e51a3859eed95742c9dba609b5dec54ba23f0144973;
      uint8 v = 27;
      frontRunner.frontRun(ali, del, 10, 1, 0, 0, address(this), v, r, s);
      assertEq(dach.nonces(ali),1);
      assertEq(dai.balanceOf(ali), 89);
      assertEq(dai.balanceOf(del), 10);
      assertEq(dai.balanceOf(address(this)), preBalance + 1);      
    }

    function test_daiswap() public {
      bytes32 r = 0xecd673a5f33310f8cb99d139d21bf88f3704a0e94265d62f29f2e57b9d1898b9;
      bytes32 s = 0x70cd92d6b5e4bbed97e3bced2c5efb6d83c5842ce813dec20d858ed2de8ce818;
      uint8 v = 28;
      dach.daiSwap(ali, 10, 332665999, 1, 0, 0, address(this), v, r, s);
      assertEq(dach.nonces(ali),1);
      assertEq(dai.balanceOf(ali), 89);
      assertEq(ali.balance, 332665999);
      assertEq(dai.balanceOf(address(this)), preBalance + 1);
    }

    function test_chaiswap() public {
      //Give ali some chai
      chai.join(ali, 100);
      assertEq(chai.balanceOf(ali), 100);

      bytes32 r = 0xcb7968e56b0b62d8a2450aed91ff2f9978e2b23e9763ecb7cdb9f060b7f219f6;
      bytes32 s = 0x55aac860dd3fe18444c233a84ed5fde077979d54345dcdd14b7b5c27db393d8f;
      uint8 v = 28;
      dach.chaiSwap(ali, 10, 332665999, 1, 0, 0, address(this), v, r, s);
      assertEq(dach.nonces(ali),1);
      assertEq(chai.balanceOf(ali), 89);
      assertEq(ali.balance, 332665999);
      assertEq(chai.balanceOf(address(this)), 1);
    }

    function test_join() public {
      bytes32 r = 0x5a0ff01ea30511546401b33e4098b8cf0ec6e70e5951a55d46fb9a5c75f01457;
      bytes32 s = 0x4456abd2e82eb7965fa0a582be8cb825c4b50bfa8b0a3d89933de80167b7bb4e;
      uint8 v = 27;
      dach.joinChai(ali, ali, 50, 1, 0, 0, address(this), v, r, s);
      assertEq(chai.dai(ali), 50);
      assertEq(chai.balanceOf(ali), rmul(50, pot.chi()));
      assertEq(dai.balanceOf(address(this)), preBalance + 1);
      assertEq(dai.balanceOf(ali), 49);
    }

    function test_exit() public {
      pot.file("dsr", uint(1000000564701133626865910626));  // 5% / day
      test_join();
      assertEq(chai.dai(ali), 50);
      hevm.warp(now + 1 days);
      assertEq(chai.dai(ali), 52);
      assertEq(dach.nonces(ali), 1);
      bytes32 r = 0x3cc2eb47be6b44c8978fbfa73d5064778e6928a07468dcac31db5d48899f08c7;
      bytes32 s = 0x332064c122b0517fb1f974cf8f232bbf1c4d91417a0f495bd16a78bcee19b87f;
      uint8 v = 28;
      dach.exitChai(ali, ali, 49, 1, 1, 0, address(this), v, r, s);
      assertEq(chai.balanceOf(ali), 0);
      assertEq(dai.balanceOf(ali), 100);
      assertEq(chai.balanceOf(address(this)), 1);
    }

}
