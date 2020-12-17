pragma solidity ^0.5.0;

library MyLibrary{
	function encodeInputuint(uint32 _input1,uint32 _input2) internal pure returns (bytes32)
	{
		return keccak256(abi.encodePacked(_input1, _input2));
	}
	
	function encodeInputuintstring(uint32 _input1,string memory _input2) internal pure returns (bytes32)
	{
		return keccak256(abi.encodePacked(_input1, _input2));
	}
}
