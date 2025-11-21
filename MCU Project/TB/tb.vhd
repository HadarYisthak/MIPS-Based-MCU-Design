---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY MCU_tb IS
    GENERIC(
            WORD_GRANULARITY      : BOOLEAN := G_WORD_GRANULARITY;     -- True = word‐addressable PC, False = byte‐addressable PC
            MODELSIM              : INTEGER := G_MODELSIM;             -- Flag for ModelSim simulation mode enable
            ITCM_ADDR_WIDTH       : INTEGER := G_ADDRWIDTH;            -- Width of instruction memory address bus (bits)
            DTCM_ADDR_WIDTH       : INTEGER := G_ADDRWIDTH;            -- Width of data memory address bus (bits)
            DATA_WORDS_NUM        : INTEGER := G_DATA_WORDS_NUM;       -- Depth (# words) of data memory
            DATA_BUS_WIDTH        : INTEGER := 32;                     -- Width of data/instruction buses (bits)
            CLK_CNT_WIDTH         : INTEGER := 16;                     -- Width of master‐clock cycle counter (bits)
            INST_CNT_WIDTH         : INTEGER := 16;                     -- Width of instruction‐at‐same‐PC counter (bits)
            CONTROL_REG_WIDTH     : INTEGER := 14;                     -- the number of control signals bits in our CPU design  
            ADDR_BUS_WIDTH        : INTEGER := 12;                     -- Width of the address bus
            PC_WIDTH              : INTEGER := 10;                     -- Width of program‐counter register (bits)
            NEXT_PC_WIDTH         : INTEGER := 8;                      -- NEXT_PC_WIDTH = PC_WIDTH-2  -- Width of next-PC bus (drops low 2 bits for word alignment)
            BT_CONTROL_WIDTH      : INTEGER := 8;                      -- Width of Basic Timer control bus
            IRQ_WIDTH             : INTEGER := 8;                      -- Number of interrupt lines supported
            SWITCHES_SIZE         : INTEGER := 8;                      -- switches array input size
            CTL_BUS_WIDTH         : INTEGER := 8;                      -- Width of the control bus signals
            RegSize               : INTEGER := 8;                      -- Width of control/status registers
            OPC_WIDTH             : INTEGER := 6;                      -- Opcode field in the instruction size, as in MIPS convention  
            FUNCT_WIDTH           : INTEGER := 6;                      -- Width of R‐type funct field (bits)	
            REG_ADRESS_WIDTH      : INTEGER := 5;                      -- Width Addresses in the Register File, as in MIPS convention  
            SEG_WIDTH             : INTEGER := 7;                      -- Width of 7-segment display
            DIV_CLK_WIDTH         : INTEGER := 4);                      -- width of DIV clock counter which determin frequency reduction.				
END MCU_tb;


ARCHITECTURE struct OF MCU_tb IS
   -- Internal signal declarations
   SIGNAL rst_tb_i           	: STD_LOGIC;
   SIGNAL clk_tb_i           	: STD_LOGIC;  
   SIGNAL Switches_w,LEDR_w  			:STD_LOGIC_VECTOR(SWITCHES_SIZE-1 DOWNTO 0);
   SIGNAL HEX0_W,HEX1_W,HEX2_W,HEX3_W,HEX4_W,HEX5_W :STD_LOGIC_VECTOR(SEG_WIDTH-1 DOWNTO 0); 
   SIGNAL KEY1, KEY2, KEY3	: STD_LOGIC :='1';
BEGIN
	MICRO_CONTROL : MCU
	GENERIC MAP(		SIM => TRUE)
				--WORD_GRANULARITY   =>	WORD_GRANULARITY, 
				--MODELSIM		   	=> MODELSIM,
				--ITCM_ADDR_WIDTH    	  =>        ITCM_ADDR_WIDTH,					
				--DTCM_ADDR_WIDTH    	    =>     DTCM_ADDR_WIDTH,					
				--DATA_WORDS_NUM     	    =>			DATA_WORDS_NUM,		
				--DATA_BUS_WIDTH     	      =>   		DATA_BUS_WIDTH,			
				--BT_COUNTER_WIDTH            =>             
				--CLK_CNT_WIDTH      	=>    CLK_CNT_WIDTH,
			    --INST_CNT_WIDTH 		=>		INST_CNT_WIDTH,	
				--CONTROL_REG_WIDTH	  =>    CONTROL_REG_WIDTH,             					
				--AddrBusSize		        =>        ADDR_BUS_WIDTH,                        
				--PC_WIDTH                  =>       PC_WIDTH,  					
				--NEXT_PC_WIDTH        		=>	NEXT_PC_WIDTH,						
				--CtrlBusSize			  		=>	CTL_BUS_WIDTH,							
				--SWITCHES_SIZE				=>	SWITCHES_SIZE,							
				--BT_CONTROL_WIDTH              => BT_CONTROL_WIDTH,                     	
				--DLATCH_WIDTH					=>						
				--RegSize							=>	RegSize,				
				--IRQ_WIDTH						=>	IRQ_WIDTH,						
				--SEG_WIDTH			      		=>	SEG_WIDTH,					
				--OPC_WIDTH    	   				=>	OPC_WIDTH,					
				--FUNCT_WIDTH        	              =>  FUNCT_WIDTH						
				--REG_ADRESS_WIDTH	: 		INTEGER := 5;                     					-- Width Addresses in the Register File,  as in MIPS convention  
           		--DIV_CLK_WIDTH       : 		INTEGER := 4                                   	-- width of DIV clock counter which determin frequency reduction.	
		--		)
		PORT MAP(		reset		=>	rst_tb_i,
					clock		=>	clk_tb_i,	 												
					Switches	=>  Switches_w,
					HEX0		=>	HEX0_W,
					HEX1		=>	HEX1_W,
					HEX2		=>	HEX2_W,
					HEX3		=>	HEX3_W,
					HEX4		=>	HEX4_W,
					HEX5		=>	HEX5_W,
					LEDR		=>	LEDR_w,
					KEY1		=>	KEY1,
					KEY2		=>	KEY2,
					KEY3		=>	KEY3
				); 		
--------------------------------------------------------------------	
Switches_w <= "00000001"; -- change from 0000000001 (up counter) to 0000000010 (down counter) for test1 (or (OTHERS => '1') for general purpose)


key_press:
process
        begin
		wait for 5000 ns;
		KEY3 <= '0';
		wait for 200 ns;
		KEY3 <= '1';
		wait;
    end process;


	gen_clk : 
	process
        begin
		  clk_tb_i <= '1';
		  wait for 50 ns;
		  clk_tb_i <= not clk_tb_i;
		  wait for 50 ns;
    end process;
	
	gen_rst : 
	process
        begin
		  rst_tb_i <='0','1' after 70 ns;
		  wait;
    end process;
--------------------------------------------------------------------		
END struct;