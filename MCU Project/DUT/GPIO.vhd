
--------------- Input Peripheral Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY GPIO IS
	GENERIC(CtrlBusSize	: integer := 8;
		AddrBusSize	: integer := 32;
		DataBusSize	: integer := 32
		);
	PORT( 
		INTA						: IN	STD_LOGIC;
		clock						: IN 	STD_LOGIC;
		reset						: IN 	STD_LOGIC;
		MemRead						: IN 	STD_LOGIC;
		MemWrite					: IN 	STD_LOGIC;
		A0						: IN	STD_LOGIC;
		DataBus						: INOUT	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
		HEX0, HEX1					: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2, HEX3					: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4, HEX5					: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		LEDR						: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		Switches					: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
		CS1, CS4, CS5, CS6, CS7				: IN 	STD_LOGIC
		);
END GPIO;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF GPIO IS

	SIGNAL CS_HEX0, CS_HEX1, CS_HEX2, CS_HEX3, CS_HEX4, CS_HEX5 : STD_LOGIC;
	
BEGIN	
	
	CS_HEX0 <= '1' WHEN (CS6 ='1' and A0 ='0') else '0';
	CS_HEX1 <= '1' WHEN (CS6 ='1' and A0 ='1') else '0';
	CS_HEX2 <= '1' WHEN (CS5 ='1' and A0 ='0') else '0';
	CS_HEX3 <= '1' WHEN (CS5 ='1' and A0 ='1') else '0';
	CS_HEX4 <= '1' WHEN (CS4 ='1' and A0 ='0') else '0';
	CS_HEX5 <= '1' WHEN (CS4 ='1' and A0 ='1') else '0';



	LED:	OutputPeripheral
	GENERIC MAP(	SevenSeg => FALSE,
			IOSize	 => 8)
	PORT MAP(	MemRead		=> MemRead,
			clock 		=> clock,
			reset		=> reset,
			MemWrite	=> MemWrite,
			ChipSelect	=> CS1,
			Data		=> DataBus(7 DOWNTO 0),
			GPOutput	=> LEDR
			);
	
	
	HEX0_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,	
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX0,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX0
			);
			
	HEX1_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX1,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX1
			);
	
	HEX2_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX2,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX2
			);
	
	HEX3_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX3,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX3
			);
			
	HEX4_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX4,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX4
			);
			
	HEX5_7SEG:	OutputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				clock 		=> clock,
				reset		=> reset,
				MemWrite	=> MemWrite,
				ChipSelect	=> CS_HEX5,
				Data		=> DataBus(7 DOWNTO 0),
				GPOutput	=> HEX5
			);
	
	SW:			InputPeripheral
	PORT MAP(		MemRead		=> MemRead,
				ChipSelect	=> CS7,
				INTA		=> INTA,
				Data		=> DataBus,
				GPInput		=> Switches
			);
		
	
END structure;