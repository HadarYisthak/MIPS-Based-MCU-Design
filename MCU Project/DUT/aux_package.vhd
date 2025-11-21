---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_comilation_package.all;

package aux_package is

COMPONENT MCU IS
	GENERIC(	MemWidth	: INTEGER := 10;
			SIM 		: BOOLEAN := TRUE;
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
END COMPONENT;
---------------------------------------------------------
	component MIPS is
			generic( 
			WORD_GRANULARITY : boolean 	:= G_WORD_GRANULARITY;
	        	MODELSIM : integer 		:= G_MODELSIM;
			DATA_BUS_WIDTH : integer 	:= 32;
			ITCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			PC_WIDTH : integer 		:= 10;
			FUNCT_WIDTH : integer 		:= 6;
			DATA_WORDS_NUM : integer 	:= G_DATA_WORDS_NUM;
			CLK_CNT_WIDTH : integer 	:= 16;
			INST_CNT_WIDTH : integer 	:= 16
	);
	PORT(		rst_i		 	:IN	STD_LOGIC;
			clk_i			:IN	STD_LOGIC;
			INTR			:IN	STD_LOGIC;
			INTA			:OUT	STD_LOGIC;
			GIE			:OUT 	STD_LOGIC;
			mem_write_w		:OUT	STD_LOGIC;
			mem_read_w		:OUT	STD_LOGIC;
			ControlBus		:OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			AddressBus		:OUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
			DataBus			:INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0)			 
	);		
	end component;
---------------------------------------------------------  
	component control is
		PORT( 	
		opcode_i 		: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
		Funct_i			: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		RegDst_ctrl_o 		: OUT 	STD_LOGIC;
		ALUSrc_ctrl_o 		: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;
		jal_o			: OUT 	STD_LOGIC;
		Branch_ctrl_o 		: OUT 	STD_LOGIC_VECTOR(1 downto 0);
		Jump_ctrl_o 		: OUT 	STD_LOGIC_VECTOR(1 downto 0);
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
	end component;
---------------------------------------------------------	
	component dmemory is
		generic(
		DATA_BUS_WIDTH : integer := 32;
		DTCM_ADDR_WIDTH : integer := 8;
		WORDS_NUM : integer := 256
	);
	PORT(		clk_i,rst_i			: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			AddressBus			: IN STD_LOGIC
	);
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
		DATA_BUS_WIDTH : integer := 32;
		FUNCT_WIDTH : integer := 6;
		PC_WIDTH : integer := 10
	);
	PORT(		read_data1_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			funct_i 	: IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);
			ALUOp_ctrl_i 	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUSrc_ctrl_i 	: IN 	STD_LOGIC;
			pc_plus4_i 	: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			Opcode_i	: IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);
			zero_o 		: OUT	STD_LOGIC;
			alu_res_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_res_o 	: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			shamt		: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0)
	);
	end component;
---------------------------------------------------------		
	component Idecode is
		generic(
		DATA_BUS_WIDTH : integer := 32
	);
	PORT(		clk_i,rst_i	: IN 	STD_LOGIC;
			instruction_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			alu_result_i	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegWrite_ctrl_i : IN 	STD_LOGIC;
			MemtoReg_ctrl_i : IN 	STD_LOGIC;
			RegDst_ctrl_i 	: IN 	STD_LOGIC;
			jal_i		: IN	STD_LOGIC;
			pc_plus4_i	: IN	STD_LOGIC_VECTOR(9 DOWNTO 0);
			pc_intr		: IN 	STD_LOGIC_VECTOR(9 DOWNTO 0);
			Read_ISR_PC	: IN 	STD_LOGIC;
			INTR		: IN 	STD_LOGIC;
			JUMP		: IN 	STD_LOGIC;
			GIE		: OUT	STD_LOGIC;
			read_data1_o	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_o 	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			shamt		: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0)		 
	);
	end component;
---------------------------------------------------------		
	component Ifetch is
		generic(
		WORD_GRANULARITY : boolean 	:= TRUE;
		DATA_BUS_WIDTH : integer 	:= 32;
		PC_WIDTH : integer 		:= 10;
		NEXT_PC_WIDTH : integer 	:= 8; -- NEXT_PC_WIDTH = PC_WIDTH-2
		ITCM_ADDR_WIDTH : integer 	:= 8;
		WORDS_NUM : integer 		:= 256;
		INST_CNT_WIDTH : integer 	:= 16
	);
	PORT(	
		clk_i, rst_i 		: IN 	STD_LOGIC;
		add_result_i 		: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
        	Branch_ctrl_i 		: IN 	STD_LOGIC_VECTOR(1 downto 0);
		Jump_ctrl_i 		: IN 	STD_LOGIC_VECTOR(1 downto 0);
        	zero_i 			: IN 	STD_LOGIC;	
		Jump_reg		: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		Read_ISR_PC		: IN 	STD_LOGIC;
		PC_HOLD			: IN 	STD_LOGIC;
		ISRAddr			: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
		pc_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_o 		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		inst_cnt_o 		: OUT	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
		pc_intr			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0)
		
	);
	end component;
---------------------------------------------------------
	COMPONENT PLL port(
	    areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0     		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC );
    END COMPONENT;
---------------------------------------------------------	
COMPONENT  ALU_CONTROL IS
	PORT(	ALUOp 	: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		Funct 	: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		Opcode 	: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		ALU_ctl : OUT   STD_LOGIC_VECTOR( 3 DOWNTO 0 ));
END COMPONENT;
---------------------------------------------------------
COMPONENT Shifter IS
  GENERIC (
    n : INTEGER := 32;     -- data width
    k : INTEGER := 5       -- size of shamt
  );
  PORT (
    y          : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    x	       : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);     -- x contains shift amount in bits [k-1:0], y is data
    dir        : IN  STD_LOGIC;       			 -- direction: "000" = left, "001" = right
    res        : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
  );
END COMPONENT;
---------------------------------------------------------
COMPONENT  ALU IS
	PORT(		a_input_w 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			b_input_w 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			ALU_ctl		 		: IN 	STD_LOGIC_VECTOR( 3 DOWNTO 0 );
			zero_o 				: OUT	STD_LOGIC;
			alu_res_o			: OUT   STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			shamt				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0)
			);
END COMPONENT;
---------------------------------------------------------
COMPONENT GPIO IS
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
END COMPONENT;
---------------------------------------------------------
COMPONENT SevenSegDecoder IS
  GENERIC (SegmentSize	: integer := 7);
  PORT (data		: in STD_LOGIC_VECTOR (3 DOWNTO 0);
		seg   	: out STD_LOGIC_VECTOR (SegmentSize-1 downto 0));
END COMPONENT;
---------------------------------------------------------
COMPONENT OptAddrDecoder IS
	PORT( 
		reset 				: IN	STD_LOGIC;
		AddressBusLow			: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		AddressBusHigh			: IN	STD_LOGIC;
		adres				: IN	STD_LOGIC_VECTOR(10 DOWNTO 5);
		CS1, CS4, CS5, CS6, CS7		: OUT 	STD_LOGIC
		);
END COMPONENT;
---------------------------------------------------------
COMPONENT InputPeripheral IS
	GENERIC(DataBusSize	: integer := 32);
	PORT( 
		MemRead		: IN	STD_LOGIC;
		ChipSelect	: IN 	STD_LOGIC;
		INTA		: IN	STD_LOGIC;
		Data		: OUT	STD_LOGIC_VECTOR(DataBusSize-1 DOWNTO 0);
		GPInput		: IN	STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
END COMPONENT;
---------------------------------------------------------
COMPONENT OutputPeripheral IS
	GENERIC (SevenSeg	: BOOLEAN := TRUE;
		 IOSize		: INTEGER := 7); -- 7 WHEN HEX, 8 WHEN LEDs
	PORT( 
		MemRead		: IN	STD_LOGIC;
		clock		: IN 	STD_LOGIC;
		reset		: IN 	STD_LOGIC;
		MemWrite	: IN	STD_LOGIC;
		ChipSelect	: IN 	STD_LOGIC;
		Data		: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		GPOutput	: OUT	STD_LOGIC_VECTOR(IOSize-1 DOWNTO 0)
		);
END COMPONENT;

---------------------------------------------------------
COMPONENT BTIMER IS
	GENERIC(DataBusSize	: integer := 32);
	PORT( 
		Addr	: IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
		BTRead	: IN	STD_LOGIC;
		BTWrite	: IN	STD_LOGIC;
		MCLK	: IN 	STD_LOGIC;
		BTCTL	: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
		BTCCR0	: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTCCR1	: IN	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTCNT_io: INOUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
		BTIFG	: OUT 	STD_LOGIC;
		PWM_out	: OUT	STD_LOGIC
		);
END COMPONENT;
---------------------------------------------------------
COMPONENT SYNC is
    port(
        firclk   : in  std_logic;   -- 	FIR CLOCK SLOW
        fifoclk  : in  std_logic;   -- FIFO CLOCK FAST
        rst      : in  std_logic;  
        FIRENA   : in  std_logic;   
        FIFOREN  : out std_logic    -- SYNC
    );
end COMPONENT;
---------------------------------------------------------
COMPONENT fir_filter IS
    PORT (
        clk_i     	: IN    STD_LOGIC; 
        fir_clk_i     	: IN    STD_LOGIC;  
        Address_i     : IN    STD_LOGIC_VECTOR(11 DOWNTO 0);
        MemRead       : IN    STD_LOGIC;
        MemWrite      : IN    STD_LOGIC;
        databus_io    : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	ControlBus_i  : IN    STD_LOGIC_VECTOR(7 DOWNTO 0);
	CLR_IRQ	      : IN    STD_LOGIC; 
        FIRIFG_o      : OUT   	STD_LOGIC;
	empty_intr    : OUT	STD_LOGIC;
	firena_intr   :	OUT	STD_LOGIC
    );
END COMPONENT;
---------------------------------------------------------
COMPONENT PLL2 IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END COMPONENT;
---------------------------------------------------------
COMPONENT INTERRUPT IS
	GENERIC(DataBusSize	: integer := 32;
			AddrBusSize	: integer := 12;
			IRQ_SIZE	    : integer := 7;
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
END COMPONENT;
---------------------------------------------------------
---------------------------------------------------------
end aux_package;

