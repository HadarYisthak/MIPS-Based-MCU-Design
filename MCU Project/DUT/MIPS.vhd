---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY MIPS IS
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
END MIPS;
-------------------------------------------------------------------------------------
ARCHITECTURE structure OF MIPS IS
	-- declare signals used to connect VHDL components
	--SIGNAL rst_i		 	:	STD_LOGIC;
	SIGNAL pc_o			:	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL alu_result_o 		:	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_o 		:	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o 		:	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_o		:	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_top_o	:	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL Branch_ctrl_o		: 	STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL Jump_ctrl_o		: 	STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL Zero_o			: 	STD_LOGIC; 
	SIGNAL MemWrite_ctrl_o		: 	STD_LOGIC;
	SIGNAL RegWrite_ctrl_o		: 	STD_LOGIC;
	SIGNAL mclk_cnt_o		:	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL inst_cnt_o 		:	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL sign_extend_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL addr_res_w 		: STD_LOGIC_VECTOR(7 DOWNTO 0 );
	SIGNAL alu_result_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_src_w 		: STD_LOGIC;
	SIGNAL branch_ctrl_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL jump_ctrl_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL reg_dst_w 		: STD_LOGIC;
	SIGNAL reg_write_w 		: STD_LOGIC;
	SIGNAL zero_w 			: STD_LOGIC;
	SIGNAL MemtoReg_w 		: STD_LOGIC;
	SIGNAL jal_w, mem_write_w_s 	 		: STD_LOGIC;
	SIGNAL Jump_reg, mem_read_w_s			: STD_LOGIC;
	SIGNAL alu_op_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MCLK_w 			: STD_LOGIC;
	SIGNAL mclk_cnt_q		: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL inst_cnt_w		: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL DataInputBus		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL shamt			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL INTA_sig			: STD_LOGIC;
	SIGNAL Read_ISR_PC,AddressBus_control		: STD_LOGIC;
	SIGNAL PC_HOLD			: STD_LOGIC;
	SIGNAL ISRAddr			: STD_LOGIC_vector(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MemAddr			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL pc_intr			: STD_LOGIC_VECTOR(9 DOWNTO 0);
	

BEGIN

------ MCU ------
	ControlBus	<= read_data2_w(7 DOWNTO 0) 		WHEN alu_result_w(11 DOWNTO 0) = X"81C" ELSE X"00";	 --BTCTL
	AddressBus	<= X"00000" & alu_result_w(11 DOWNTO 0) WHEN (mem_read_w = '1' OR mem_write_w = '1') ELSE (OTHERS => '0');
	DataInputBus	<= DataBus 				WHEN (alu_result_w(11) = '1' AND mem_read_w = '1') ELSE dtcm_data_rd_w; 	-- GPIO INPUT
	DataBus		<= read_data2_w 			WHEN (alu_result_w(11) = '1' AND mem_write_w = '1' and mem_read_w = '0' ) ELSE (OTHERS => 'Z');	-- GPIO OUTPUT
	MemAddr 	<= DataBus(9 DOWNTO 2) 			WHEN (INTA_sig = '0') ELSE
			   alu_result_w((DTCM_ADDR_WIDTH+2)-1 DOWNTO 2); -- when there is an interrupt the addres that we need is from the databus (ISR)


--connect the 5 MIPS components   
	IFE : Ifetch
	generic map(
		WORD_GRANULARITY	=> 	WORD_GRANULARITY,
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		PC_WIDTH		=>	PC_WIDTH,
		ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
		WORDS_NUM		=>	DATA_WORDS_NUM,
		INST_CNT_WIDTH		=>	INST_CNT_WIDTH
	)
	PORT MAP (	
		clk_i 			=> clk_i,  
		rst_i 			=> rst_i,
		add_result_i 		=> addr_res_w,
		Branch_ctrl_i 		=> branch_ctrl_w,
		zero_i 			=> zero_w,
		Jump_reg		=> read_data1_w,
		pc_o 			=> pc_o,
		instruction_o 		=> instruction_w,
    		pc_plus4_o	 	=> pc_plus4_w,
		inst_cnt_o		=> inst_cnt_w,
		Jump_ctrl_i		=> jump_ctrl_w,
		Read_ISR_PC		=> Read_ISR_PC,
		PC_HOLD			=> PC_HOLD,
		ISRAddr			=> ISRAddr,
		pc_intr			=> pc_intr
	);

	ID : Idecode
   	generic map(
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
			clk_i 			=> clk_i,  
			rst_i 			=> rst_i,
        		instruction_i 		=> instruction_w,
        		dtcm_data_rd_i 		=> DataInputBus,
			alu_result_i 		=> alu_result_w,
			RegWrite_ctrl_i 	=> reg_write_w,
			MemtoReg_ctrl_i 	=> MemtoReg_w,
			RegDst_ctrl_i 		=> reg_dst_w,
			read_data1_o 		=> read_data1_w,
        		read_data2_o 		=> read_data2_w,
			sign_extend_o 		=> sign_extend_w,
			pc_plus4_i		=> pc_plus4_w,
			jal_i			=> jal_w,
			shamt			=> shamt,
			Read_ISR_PC		=> Read_ISR_PC,
			INTR			=> INTR,
			GIE			=> GIE,
			JUMP			=> (jump_ctrl_w(0) or jump_ctrl_w(1)),
			pc_intr			=> pc_intr
		);

	CTL:   control
	PORT MAP ( 	
			opcode_i 		=> instruction_w(DATA_BUS_WIDTH-1 DOWNTO 26),
			funct_i			=> instruction_w(5 DOWNTO 0),
			RegDst_ctrl_o 		=> reg_dst_w,
			ALUSrc_ctrl_o 		=> alu_src_w,
			MemtoReg_ctrl_o 	=> MemtoReg_w,
			RegWrite_ctrl_o 	=> reg_write_w,
			MemRead_ctrl_o 		=> mem_read_w,
			MemWrite_ctrl_o 	=> mem_write_w,
			jal_o			=> jal_w,
			Branch_ctrl_o 		=> branch_ctrl_w,
			Jump_ctrl_o		=> jump_ctrl_w,
			ALUOp_ctrl_o 		=> alu_op_w
		);

	EXE:  Execute
   	generic map(
		DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
		FUNCT_WIDTH 		=>	FUNCT_WIDTH,
		PC_WIDTH 		=>	PC_WIDTH
	)
	PORT MAP (	
		pc_plus4_i		=> pc_plus4_w,
		read_data1_i 		=> read_data1_w,
        	read_data2_i 		=> read_data2_w,
		sign_extend_i 		=> sign_extend_w,
        	funct_i			=> instruction_w(5 DOWNTO 0),
		Opcode_i		=> instruction_w(31 DOWNTO 26),
		ALUOp_ctrl_i 		=> alu_op_w,
		ALUSrc_ctrl_i 		=> alu_src_w,
		zero_o 			=> zero_w,
        	alu_res_o		=> alu_result_w,
		addr_res_o 		=> addr_res_w,
		shamt			=> shamt			
	);

mem_read_w_s <= mem_read_w;
mem_write_w_s <= mem_write_w;	


AddressBus_control <=AddressBus(11);	
	
	G1: 
	if (WORD_GRANULARITY = True) generate -- i.e. each WORD has a unike address
		MEM:  dmemory
			generic map(
				DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
				DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
				WORDS_NUM		=>	DATA_WORDS_NUM
			)
			PORT MAP (	
				clk_i 			=> clk_i,  
				rst_i 			=> rst_i,
				dtcm_addr_i 		=> MemAddr,
				dtcm_data_wr_i 		=> read_data2_w,
				MemRead_ctrl_i 		=> mem_read_w_s, 
				MemWrite_ctrl_i 	=> mem_write_w_s,
				dtcm_data_rd_o 		=> dtcm_data_rd_w,
				AddressBus		=> AddressBus_control
			);	
	elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address	
		MEM:  dmemory
			generic map(
				DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
				DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
				WORDS_NUM		=>	DATA_WORDS_NUM
			)
			PORT MAP (	
				clk_i 			=> clk_i,  
				rst_i 			=> rst_i,
				--dtcm_addr_i 		=> alu_result_w(DTCM_ADDR_WIDTH-1 DOWNTO 2)&"00",
				dtcm_addr_i 		=> MemAddr,
				dtcm_data_wr_i 		=> read_data2_w,
				MemRead_ctrl_i 		=> mem_read_w_s, 
				MemWrite_ctrl_i 	=> mem_write_w_s,
				dtcm_data_rd_o 		=> dtcm_data_rd_w,
				AddressBus		=> AddressBus_control
			);
	end generate;


---------- INTERRUPT ----------
	------ INTA and ISR Addr ------FSM: 00 STATE - NO INTERRUPT, 01 INTRA=1 THERE IS INTERURUPT, 10 HOLD CURRENT PC AND PC<- ISR PC
	INTA	<= INTA_sig;
	ISRAddr		<= dtcm_data_rd_w;

	PROCESS (clk_i, INTR, rst_i)
		VARIABLE INTR_STATE 	: STD_LOGIC_VECTOR(1 DOWNTO 0);

	BEGIN
		IF rst_i = '1' THEN
			INTR_STATE 	:= "00";
			INTA_sig 	<= '1';
			Read_ISR_PC	<= '0';
			PC_HOLD		<= '0';
		
		ELSIF (falling_edge(clk_i)) THEN
			IF (INTR_STATE = "00") THEN
				IF (INTR = '1') THEN
					INTA_sig	<= '0';
					INTR_STATE	:= "01";
					PC_HOLD		<= '1';
				END IF;
				Read_ISR_PC	<= '0';
			
				
			ELSIF (INTR_STATE = "01") THEN		
				INTA_sig	<= '0';
				INTR_STATE 	:= "10";
				Read_ISR_PC	<= '1';
				PC_HOLD		<= '0';
				
			ELSIF (INTR_STATE = "10") THEN		
				INTA_sig	<= '1';
				INTR_STATE 	:= "00";
				Read_ISR_PC	<= '0';
				PC_HOLD		<= '0';
			END IF;
		END IF;
	END PROCESS;
	
	





END structure;

