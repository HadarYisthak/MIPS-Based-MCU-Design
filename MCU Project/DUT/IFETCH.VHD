---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


ENTITY Ifetch IS
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
		clk_i, rst_i		: IN 	STD_LOGIC;
		add_result_i		: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
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
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_r 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w ,  address 			: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w_b  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w_j  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w_temp  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	SIGNAL jump_reg_w  			: STD_LOGIC_VECTOR(NEXT_PC_WIDTH-1 DOWNTO 0);
	SIGNAL rst_i_q				: STD_LOGIC :='1';
	SIGNAL inst_cnt_q 			: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL pc_prev_q			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL J_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_q 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
BEGIN

--ROM for Instruction Memory
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode => "ROM",
		width_a => DATA_BUS_WIDTH,
		widthad_a => ITCM_ADDR_WIDTH,
		numwords_a => WORDS_NUM,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "C:\Users\User\Desktop\lab6test4\final_project\FILES\ITCM.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		clock0     => clk_i,
		address_a  => address,
		q_a 	   => instruction_q 
	);
	
address <= itcm_addr_w when rst_i_q= '0' else "00000000"; 

	-- Instructions always start on word address - not byte
	pc_q(1 DOWNTO 0) 	<= "00";
	
	-- send address to inst. memory address register
	G1: 
	if (WORD_GRANULARITY = True) generate 		-- i.e. each WORD has unike address
		itcm_addr_w <= next_pc_w;
	elsif (WORD_GRANULARITY = False) generate 	-- i.e. each BYTE has unike address
		itcm_addr_w <= next_pc_w & "00";
	end generate;
		
	-- Adder to increment PC by 4
	pc_plus4_r( 1 DOWNTO 0 )  		<= "00";
    	pc_plus4_r(PC_WIDTH-1 DOWNTO 2)  	<= pc_q(PC_WIDTH-1 DOWNTO 2) + 1;

	-- sign extantion to jump
    	next_pc_w_j(7 DOWNTO 0)  	<= instruction_q(7 DOWNTO 0);
	--next_pc_w_j(7 DOWNTO 0) 	<= pc_plus4_r(9 DOWNTO 2);		---- be aware maybe wrong ----

	-- slicing of jump register
	jump_reg_w 	<= Jump_reg(PC_WIDTH-1 DOWNTO 2);

											
	-- Mux to select Branch Address or PC + 4        
	------------------------------------------------------------------------------------				
	next_pc_w_b  <= 	(others => '0') WHEN rst_i_q = '1' ELSE
				add_result_i  	WHEN ((Branch_ctrl_i(0) = '1') AND (zero_i = '1'))or((Branch_ctrl_i(1) = '1') AND (zero_i = '0')) ELSE
				pc_plus4_r(PC_WIDTH-1 DOWNTO 2);	
			
	-- Mux to select JUMP Address or PC + 4        
	------------------------------------------------------------------------------------				
	next_pc_w_temp  <= 	(others => '0') WHEN rst_i_q = '1' ELSE
				next_pc_w_j 	WHEN Jump_ctrl_i(0)='1' ELSE
				jump_reg_w    	WHEN Jump_ctrl_i(1 downto 0)="10" ELSE
				next_pc_w_b;
		
	next_pc_w <= ISRAddr(9 DOWNTO 2)	WHEN Read_ISR_PC = '1'	ELSE --INTERRUPT THE PC NEEDS  THE ISR PC
		     next_pc_w_temp;
	------------------------------------------------------------------------------------
	process (clk_i)
	BEGIN
  		if rising_edge(clk_i) then
    			rst_i_q <= rst_i;
  		end if;
	end process;
	-------------------------------------------------------------------------------------
	PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= (OTHERS => '0') ; 
		ELSIF(clk_i'EVENT  AND clk_i='1') AND (PC_HOLD = '0') THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= next_pc_w;	
		ELSIF(clk_i'EVENT  AND clk_i='1') AND (PC_HOLD = '0') THEN
			pc_q(PC_WIDTH-1 DOWNTO 2) <= next_pc_w;	
		END IF;
	END PROCESS;


---------------------------------------------------------------------------------------
pc_intr <= next_pc_w_temp & "00";
---------------------------------------------------------------------------------------
	-- copy output signals - allows read inside module
	pc_o 				<= 	pc_q;
	pc_plus4_o 			<= 	pc_plus4_r;
	inst_cnt_o			<=	inst_cnt_q;
	instruction_o			<= 	instruction_q;
END behavior;

