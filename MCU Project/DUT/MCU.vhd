--------------- MCU System Architecture Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY MCU IS
	GENERIC(	MemWidth	: INTEGER := 10;
			--SIM 		: BOOLEAN := FALSE;
			SIM 		: BOOLEAN := true;
			CtrlBusSize	: integer := 8;
			AddrBusSize	: integer := 32;
			DataBusSize	: integer := 32;
			IrqSize		: integer := 7;
			RegSize		: integer := 8
			);
	PORT( 
			reset, clock		: IN	STD_LOGIC;
			HEX0, HEX1, HEX2	: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX3, HEX4, HEX5	: OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			LEDR			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			Switches		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			PWM_out			: OUT   STD_LOGIC;
			KEY1, KEY2, KEY3	: IN	STD_LOGIC
			--UART_RX			: IN 	STD_LOGIC := '1';
			--UART_TX			: OUT	STD_LOGIC := '1'
		);
END MCU;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF MCU IS
	SIGNAL resetSim		: STD_LOGIC;
	SIGNAL enaSim		: STD_LOGIC;
	SIGNAL clock_i	: 	STD_LOGIC;
	
	-- CHIP SELECT SIGNALS --
	SIGNAL CS1, CS4, CS5, CS6, CS7		: STD_LOGIC;
	
	
	-- GPIO SIGNALS -- 
	SIGNAL MemRead		: 	STD_LOGIC;
	SIGNAL MemWrite		:	STD_LOGIC;
	SIGNAL ControlBus	: 	STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0);
	SIGNAL AddressBus	: 	STD_LOGIC_VECTOR(AddrBusSize-1 DOWNTO 0);
	SIGNAL DataBus		: 	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	
	-- BASIC TIMER --
	SIGNAL BTCTL		:	STD_LOGIC_VECTOR(CtrlBusSize-1 DOWNTO 0);
	SIGNAL BTCNT		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	SIGNAL BTCCR0		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	SIGNAL BTCCR1		:	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
	SIGNAL BTIFG		:	STD_LOGIC;

  	-- FIR -- 	    
	SIGNAL FIRIFG		:	STD_LOGIC;
	SIGNAL FIRENA		:	STD_LOGIC;
	SIGNAL FIFOEMPTY	:	STD_LOGIC;
	Signal fir_clk		:	STD_LOGIC;
	SIGNAL PLL_LOCKED	:	STD_LOGIC;	 	
	SIGNAL PLL_LOCKED2	:	STD_LOGIC;
	
	-- INTERRUPT MODULE --
	SIGNAL IntrEn		:	STD_LOGIC_VECTOR(RegSize-1 DOWNTO 0);
	SIGNAL IFG		:	STD_LOGIC_VECTOR(RegSize-1 DOWNTO 0);
	SIGNAL TypeReg		:	STD_LOGIC_VECTOR(RegSize-1 DOWNTO 0);
	SIGNAL IntrSrc		:	STD_LOGIC_VECTOR(IrqSize-1 DOWNTO 0);
	SIGNAL IRQ_OUT		:	STD_LOGIC_VECTOR(IrqSize-1 DOWNTO 0);
	SIGNAL IntrTx		:	STD_LOGIC;
	SIGNAL IntrRx		:	STD_LOGIC;
	SIGNAL INTR		:	STD_LOGIC;
	SIGNAL INTA		:	STD_LOGIC;  
	SIGNAL GIE		:	STD_LOGIC;
	SIGNAL INTR_Active	:	STD_LOGIC;
	SIGNAL CLR_IRQ		:	STD_LOGIC_VECTOR(6 DOWNTO 0);
	
	
BEGIN	

	-------------------------- FPGA or ModelSim -----------------------
	resetSim 	<= reset WHEN NOT SIM ELSE not reset;


	
	CPU: MIPS
		GENERIC MAP(
					DATA_BUS_WIDTH	=> DataBusSize,
					WORD_GRANULARITY=> SIM)
		PORT MAP(
					rst_i		=> resetSim,
					clk_i		=> clock_i,
					ControlBus	=> ControlBus,
					mem_read_w	=> MemRead,
					mem_write_w	=> MemWrite,
					AddressBus	=> AddressBus,
					GIE		=> GIE,
					INTR		=> INTR,
					INTA		=> INTA,
					DataBus		=> DataBus
		);
		
	
	OAD : 	OptAddrDecoder
	PORT MAP(		reset		=> resetSim,
				AddressBusLOW	=> AddressBus(4 DOWNTO 2),
				AddressBusHigh	=> AddressBus(11),
				adres		=> AddressBus(10 DOWNTO 5),
				CS1		=> CS1,
				CS4		=> CS4,
				CS5		=> CS5,
				CS6		=> CS6,	
				CS7		=> CS7
				);
		
	
	IO_interface: GPIO
		PORT MAP(
			INTA		=> INTA,
			MemRead		=> MemRead,
			clock		=> clock_i,
			reset		=> resetSim,
			MemWrite	=> MemWrite,
			A0		=> AddressBus(0),
			DataBus		=> DataBus,
			HEX0		=> HEX0,
			HEX1		=> HEX1,
			HEX2		=> HEX2,
			HEX3		=> HEX3,
			HEX4		=> HEX4,
			HEX5		=> HEX5,
			LEDR		=> LEDR,
			Switches	=> Switches,
			CS1		=> CS1,
			CS4		=> CS4,
			CS5		=> CS5,
			CS6		=> CS6,	
			CS7		=> CS7
		);

	PROCESS(clock_i)
	BEGIN
		if (falling_edge(clock_i)) then
			if(AddressBus(11 DOWNTO 0) = X"81C" AND MemWrite = '1') then
				BTCTL <= ControlBus;
			END IF;
			if(AddressBus(11 DOWNTO 0) = X"824" AND MemWrite = '1') then
				BTCCR0 <= DataBus;
			END IF;
			if(AddressBus(11 DOWNTO 0) = X"828" AND MemWrite = '1') then
				BTCCR1 <= DataBus;
			END IF;
		END IF;
	END PROCESS;

	BTCNT	<= DataBus WHEN (AddressBus(11 DOWNTO 0) = X"820" and MemRead = '0' AND MemWrite = '1') ELSE (OTHERS => 'Z');  -- INPUT
	DataBus	<= BTCNT   WHEN (AddressBus(11 DOWNTO 0) = X"820" AND MemRead = '1' and MemWrite = '0') ELSE (OTHERS => 'Z');  -- OUTPUT
	---------------------------------------------------------------------------------------------------------------
	

	Basic_Timer: BTIMER
		PORT MAP(
			Addr	=> AddressBus(11 DOWNTO 0),
			BTRead	=> MemRead,
			BTWrite	=> MemWrite,
			MCLK	=> clock_i,
			BTCTL	=> BTCTL,
			BTCCR0	=> BTCCR0,
			BTCCR1	=> BTCCR1,
			BTCNT_io=> BTCNT,
			BTIFG	=> BTIFG,
			PWM_out	=> PWM_out
		);
	---------------------------------------------------------------------------------------------------------------
--
--	FIR: fir_filter
--		PORT MAP(
--			clk_i     	=> clock, 
--        		fir_clk_i     	=> fir_clk, 
--        		Address_i     	=> AddressBus(11 DOWNTO 0),
--        		MemRead     	=> MemRead,
--        		MemWrite 	=> MemWrite,  	
--        		databus_io	=> DataBus,	   	
--			ControlBus_i  	=> ControlBus,
--        		FIRIFG_o      	=> FIRIFG,
--			firena_intr	=> FIRENA,
--			empty_intr	=> FIFOEMPTY,
--			CLR_IRQ		=> CLR_IRQ(6)
--		);


	---------------------------------------------------------------------------------------------------------------
	PLL_ALL_CLK : PLL
	PORT MAP(
		inclk0 => clock,
		areset => '0',
		c0 => clock_i, 
		locked => PLL_LOCKED 
	);




---------------------------interrupt-----------------------------------------
	--IntrSrc	<= FIRIFG & (NOT KEY3) & (NOT KEY2) & (NOT KEY1) & BTIFG & '0' & '0';
	IntrSrc	<= '0' & (NOT KEY3) & (NOT KEY2) & (NOT KEY1) & BTIFG & '0' & '0';
	Intr_Controller: INTERRUPT
		GENERIC MAP(
			DataBusSize	=> DataBusSize,
			AddrBusSize	=> AddrBusSize,
			IRQ_SIZE	=> IrqSize,
			RegSize 	=> RegSize
		)
		PORT MAP(
		    reset		=> resetSim,
		    clock		=> clock_i,
		    MemRead		=> MemRead,
		    MemWrite		=> MemWrite,
		    AddressBus		=> AddressBus,
		    DataBus		=> DataBus,
		    IntrSrc		=> IntrSrc,
		    INTR		=> INTR,
		    INTA		=> INTA,
		    IRQ_OUT		=> IRQ_OUT,
		    GIE			=> GIE,
		    FIFOEMPTY		=> FIFOEMPTY,
		    FIROUT		=> FIRENA
		);
		
		
END structure;