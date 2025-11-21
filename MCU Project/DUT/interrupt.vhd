--------------- Interrupt Controller Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY INTERRUPT IS
	GENERIC(	DataBusSize	: integer := 32;
			AddrBusSize	: integer := 12;
			IRQ_SIZE	: integer := 7;
			RegSize		: integer := 8
			);
	PORT( 
			reset		: IN	STD_LOGIC;
			clock		: IN	STD_LOGIC;
			MemRead		: IN	STD_LOGIC;
			MemWrite	: IN	STD_LOGIC;
			AddressBus	: IN	STD_LOGIC_VECTOR(AddrBusSize-1 DOWNTO 0);
			DataBus		: INOUT	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
			IntrSrc		: IN	STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0); -- IRQ
			FIFOEMPTY, FIROUT :IN 	STD_LOGIC;
			INTR		: OUT	STD_LOGIC;
			INTA		: IN	STD_LOGIC;
			IRQ_OUT		: OUT   STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0);
			INTR_Active	: OUT	STD_LOGIC;
			GIE		: IN	STD_LOGIC
		);
END INTERRUPT;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF INTERRUPT IS
	SIGNAL IRQ		: STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0);
	SIGNAL CLR_IRQ		: STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0);
	SIGNAL IE		: STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0);
	SIGNAL IFG		: STD_LOGIC_VECTOR(IRQ_SIZE-1 DOWNTO 0);
	SIGNAL TypeReg		: STD_LOGIC_VECTOR(RegSize-1 DOWNTO 0);
	SIGNAL INTA_Delayed 	: STD_LOGIC;
	
	
	
BEGIN
--------------------------- IO MCU ---------------------------
-- OUTPUT TO MCU --  
DataBus <=	X"000000" 	& TypeReg 	WHEN ((AddressBus = X"842" AND MemRead = '1') OR (INTA = '0' AND MemRead = '0')) ELSE
		X"000000"&"0" 	& IE 		WHEN (AddressBus = X"840" AND MemRead = '1') ELSE
		X"000000"&"0" 	& IFG		WHEN (AddressBus = X"841" AND MemRead = '1') ELSE
		(OTHERS => 'Z');



--------IE ENABLE THE INTERRUPT
PROCESS(clock) 
BEGIN
	IF (falling_edge(clock)) THEN
		IF (AddressBus = X"840" AND MemWrite = '1') THEN
			IE <= DataBus(IRQ_SIZE-1 DOWNTO 0);
		END IF;		
	END IF;
END PROCESS;

IFG	<=	DataBus(IRQ_SIZE-1 DOWNTO 0) WHEN (AddressBus = X"841" AND MemWrite = '1') ELSE 	---WR DIRECTLY TO THIS ADDRES
		IRQ AND IE;										--IRQ HAS ALL THE INTERRUPT THAT WANT TO HAPPENDS, INTREN HAS ALL THE INTERRUPT THAT ENABLE- AND WILL MAKE SURE THAT WHEN BOTH 1 THE INTERRUPT WILL WORK
TypeReg	<=	DataBus(RegSize-1 DOWNTO 0) WHEN (AddressBus = X"842" AND MemWrite = '1') ELSE
		(OTHERS => 'Z');


-- IF ONE OF THE INTERRUPT ARE 1 THEN INTR = GIE
PROCESS (clock, IFG) BEGIN 
	IF (rising_edge(CLOCK)) THEN
		IF (IFG(0) = '1' OR IFG(1) = '1' OR IFG(2) = '1' OR
			IFG(3) = '1' OR IFG(4) = '1' OR IFG(5) = '1' OR IFG(6) = '1') THEN
			
			INTR <= GIE;
		ELSE 
			INTR <= '0';
		END IF;
	END IF;
END PROCESS;


---------------DEFINE THE IFG 
---------------------THE CHECK IS BY CHECKING RISING EDGE- PULSE............ ='1' IS FOR STADY SIGNALS 
------------ RX ---------------
PROCESS (clock, reset, CLR_IRQ(0), IntrSrc(0))
BEGIN
	IF (reset = '1') THEN
		IRQ(0) <= '0';
	ELSIF CLR_IRQ(0) = '0' THEN
		IRQ(0) <= '0';
	ELSIF rising_edge(IntrSrc(0)) THEN
		IRQ(0) <= '1';
	END IF;
END PROCESS;
------------ TX ---------------
PROCESS (clock, reset, CLR_IRQ(1), IntrSrc(1))
BEGIN
	IF (reset = '1') THEN
		IRQ(1) <= '0';
	ELSIF rising_edge(clock) THEN
		IF CLR_IRQ(1) = '0' THEN
			IRQ(1) <= '0';
		ELSIF IntrSrc(1) = '1'  THEN
			IRQ(1) <= '1';
		END IF;
	END IF;
END PROCESS;
------------ BTIMER ---------------
PROCESS (clock, reset, CLR_IRQ(2), IntrSrc(2))
BEGIN
	IF (reset = '1') THEN
			IRQ(2) <= '0';
	ELSIF falling_edge(clock) THEN
		IF CLR_IRQ(2) = '0' THEN
			IRQ(2) <= '0';
		ELSIF IntrSrc(2) = '1' THEN
			IRQ(2) <= '1';
		END IF;
	END IF;
END PROCESS;
------------ KEY1 ---------------
PROCESS (clock, reset, CLR_IRQ(3), IntrSrc(3))
BEGIN
	IF (reset = '1') THEN
		IRQ(3) <= '0';
	ELSIF rising_edge(clock) THEN
		IF CLR_IRQ(3) = '0' THEN
			IRQ(3) <= '0';
		ELSIF IntrSrc(3) = '1'  THEN
			IRQ(3) <= '1';
		END IF;
	END IF;
END PROCESS;
------------ KEY2 ---------------
PROCESS (clock, reset, CLR_IRQ(4), IntrSrc(4))
BEGIN
	IF (reset = '1') THEN
		IRQ(4) <= '0';
	ELSIF rising_edge(clock) THEN
		IF CLR_IRQ(4) = '0' THEN
			IRQ(4) <= '0';
		ELSIF IntrSrc(4) = '1'  THEN
			IRQ(4) <= '1';
		END IF;
	END IF;
END PROCESS;
------------ KEY3 ---------------
PROCESS (clock, reset, CLR_IRQ(5), IntrSrc(5))
BEGIN
	IF (reset = '1') THEN
		IRQ(5) <= '0';
	ELSIF rising_edge(clock) THEN
		IF CLR_IRQ(5) = '0' THEN
			IRQ(5) <= '0';
		ELSIF IntrSrc(5) = '1'  THEN
			IRQ(5) <= '1';
		END IF;
	END IF;
END PROCESS;
------------ FIREN ---------------
PROCESS (clock, reset, CLR_IRQ(6), IntrSrc(6))
BEGIN
	IF (reset = '1') THEN
		IRQ(6) <= '0';
	ELSIF rising_edge(clock) THEN
		IF CLR_IRQ(6) = '0' THEN
			IRQ(6) <= '0';
		ELSIF IntrSrc(6) = '1'  THEN
			IRQ(6) <= '1';
		END IF;
	END IF;
END PROCESS;
---------

PROCESS (clock) BEGIN
	IF (reset = '1') THEN
		INTA_Delayed <= '1';
	ELSIF (falling_edge(clock)) THEN
		INTA_Delayed <= INTA;
	END IF;
END PROCESS;

-- Clear IRQ When Interrupt Ack recv
CLR_IRQ(0) <= '0' WHEN (TypeReg = X"08" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(1) <= '0' WHEN (TypeReg = X"0C" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(2) <= '0' WHEN (TypeReg = X"10" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(3) <= '0' WHEN (TypeReg = X"14" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(4) <= '0' WHEN (TypeReg = X"18" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(5) <= '0' WHEN (TypeReg = X"1C" AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';
CLR_IRQ(6) <= '0' WHEN (((TypeReg = X"20") or (TypeReg = X"24")) AND INTA = '0' AND INTA_Delayed = '0') ELSE '1';


-- Interrupt Vectors
------------TYPE REG HAS ALL THE TYPE CONTENTS ACOORDING TO IFG STATUS
------------HAS THE ISR OF THE CURRENT IFG
TypeReg	<= 		X"00" WHEN reset  = '1' ELSE 
			--X"04" WHEN (IRQ_STATUS = '1' AND IntrEn(0) = '1') ELSE  -- Uart Status Error
			--X"08" WHEN IFG(0) = '1' ELSE  	-- Uart RX
			--X"0C" WHEN IFG(1) = '1' ELSE  	-- Uart TX
			X"10" WHEN (IFG(2) = '1' and INTA = '0') ELSE  	-- Basic timer
			X"14" WHEN (IFG(3) = '1' and INTA = '0')ELSE  	-- KEY1
			X"18" WHEN (IFG(4) = '1' and INTA = '0') ELSE	-- KEY2
			X"1C" WHEN (IFG(5) = '1' and INTA = '0') ELSE	-- KEY3
			--X"20" WHEN (IFG(6) = '1' AND FIFOEMPTY = '1') ELSE	-- FIFOEMPTY
			--X"24" WHEN (IFG(6) = '1' AND FIROUT ='1') ELSE	-- FIROUT
			(OTHERS => 'Z');

END structure;















