--------------- Optimized Address Decoder Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY OptAddrDecoder IS
	PORT( 
		reset 				: IN	STD_LOGIC;
		AddressBusLow			: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		AddressBusHigh			: IN	STD_LOGIC;
		adres				: IN	STD_LOGIC_VECTOR(10 DOWNTO 5);
		CS1, CS4, CS5, CS6, CS7		: OUT 	STD_LOGIC
		);
END OptAddrDecoder;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF OptAddrDecoder IS

BEGIN

	CS1	<=	'0' WHEN reset = '1' ELSE '1' WHEN (AddressBusLOW = "000" and AddressBusHigh ='1' and adres = "000000") ELSE '0';
	CS4	<=	'0' WHEN reset = '1' ELSE '1' WHEN (AddressBusLOW = "011" and AddressBusHigh ='1' and adres = "000000") ELSE '0';
	CS5	<=	'0' WHEN reset = '1' ELSE '1' WHEN (AddressBusLOW = "010" and AddressBusHigh ='1' and adres = "000000") ELSE '0';
	CS6	<=	'0' WHEN reset = '1' ELSE '1' WHEN (AddressBusLOW = "001" and AddressBusHigh ='1' and adres = "000000") ELSE '0';
	CS7	<=	'0' WHEN reset = '1' ELSE '1' WHEN (AddressBusLOW = "100" and AddressBusHigh ='1' and adres = "000000") ELSE '0';

END structure;
