
--------------- Basic Timer Module 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.aux_package.ALL;
-------------- ENTITY --------------------
ENTITY BTIMER IS
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
END BTIMER;
------------ ARCHITECTURE ----------------
ARCHITECTURE structure OF BTIMER IS
	SIGNAL CLK, HEU0_sync_ff1, HEU0_sync_ff2, HEU0_sync	: STD_LOGIC;
	SIGNAL DIV, div_o	: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL BTCNT	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL BTCL0	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL BTCL1	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	
	SIGNAL PWM	: STD_LOGIC;
	SIGNAL HEU0	: STD_LOGIC;
	SIGNAL HEU0_SLOW: STD_LOGIC;
	SIGNAL HEU0_FAST: STD_LOGIC;
	SIGNAL out_1	: STD_LOGIC;
	SIGNAL out_0	: STD_LOGIC;
	SIGNAL round	: STD_LOGIC;
	SIGNAL Q32, Q32_i	: STD_LOGIC;
	SIGNAL Q28, Q28_i	: STD_LOGIC;
	SIGNAL Q24, Q24_i	: STD_LOGIC;

	signal CLK_toggle : std_logic := '0';
signal DIV_CNT : std_logic_vector(3 downto 0) := "0000";
signal MCLK_prev : std_logic := '0';


signal BTIPx_o  : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal BTSSEL_o : STD_LOGIC_VECTOR(1 DOWNTO 0); 
signal BTCLR_o, BTHOLD_o, BTOUTEN_o, BTOUTMD_o : STD_LOGIC;
signal BTCNT_prev : std_logic_vector(31 downto 0);


	ALIAS BTIPx	IS BTCTL(1 DOWNTO 0);
	ALIAS BTCLR 	IS BTCTL(2);
	ALIAS BTSSEL	IS BTCTL(4 DOWNTO 3);
	ALIAS BTHOLD	IS BTCTL(5);
	ALIAS BTOUTEN	IS BTCTL(6);
	ALIAS BTOUTMD	IS BTCTL(7);
	
BEGIN
	---------- Read Write Section ----------

BTIPx_o   <= BTIPx;
BTCLR_o   <= BTCLR;
BTSSEL_o  <= BTSSEL;	
BTHOLD_o  <= BTHOLD;	
BTOUTEN_o <= BTOUTEN;
BTOUTMD_o <= BTOUTMD;

	-- if BTCNT came as OUTPUT (Load Word)
	BTCNT_io <= BTCNT WHEN (Addr = X"820" AND BTRead = '1') ELSE (OTHERS => 'Z');	

	PROCESS (MCLK) BEGIN 
		IF BTCLR ='1' THEN
			BTCL0 <= X"00000000";
			BTCL1 <= X"00000000";
			
		elsif (falling_edge(MCLK) and BTCNT = X"00000000" and BTCLR = '0') THEN
				BTCL0 <= BTCCR0 ;
				if BTCCR1 /= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" then BTCL1 <= BTCCR1; 
				ELSE BTCL1 <= BTCL1;
				end if;
		END IF;
	END PROCESS;
	---------- Basic Timer Signal Generation Section ----------
process(MCLK)
	begin
		if (MCLK'event and MCLK='1') then

			if ((BTCNT < BTCL0) and (BTCNT >= BTCL1) and (BTOUTMD = '1')) then out_1 <='0';
			elsif (BTOUTMD = '1') then out_1 <='1';
			end if;

			if ((BTCNT < BTCL0) and (BTCNT >= BTCL1) and (BTOUTMD = '0')) then out_0 <= '1';
			elsif (BTOUTMD = '0') then out_0 <='0';
			end if;

			if (BTCNT >= BTCL0 -1) then HEU0_FAST <= '1';
			ELSE HEU0_FAST <= '0';
			end if;
		end if;
	end process;


	process(CLK)
	begin
		if (CLK'event and CLK='1') then
			if (BTCNT >= BTCL0 -1) then HEU0_SLOW <= '1';
			ELSE HEU0_SLOW <= '0';
			end if;
		end if;
	end process;
HEU0 <= HEU0_SLOW and HEU0_FAST;


	PWM_out <= 	PWM_out when BTOUTEN = '0' else
			out_1 when BTOUTMD= '1' else
		 	out_0 when BTOUTMD= '0' else
		 	PWM_out;



	
	---------- Basic Timer Interrupt Section ----------
	-- Select the devision in the clk in CLKCNT
		DIV	<=	"0001"WHEN  BTSSEL = "00" ELSE-- 1
				"0010"	WHEN  BTSSEL ="01"  ELSE-- 2
				"0100"	WHEN  BTSSEL ="10" ELSE-- 4
				"1000"	WHEN  BTSSEL ="11" ELSE-- 8
				"0001";
		


	PROCESS(MCLK, BTCLR)
	BEGIN
		IF BTCLR = '1' THEN
        		CLK <= '1';
        		DIV_CNT <= "0000";
		ELSIF (DIV = X"1") THEN
			CLK <= MCLK;
		ELSIF (RISING_EDGE(MCLK)) THEN 
			IF BTHOLD='0' THEN
				IF (DIV_CNT >= ('0' & DIV(3 DOWNTO 1))) THEN	
					round <= '1';
					DIV_CNT <= "0000";
					CLK <= NOT CLK;
				ELSE DIV_CNT <= DIV_CNT + 1;
						round <= '0';
				END IF;
			END IF;
		END IF;
END PROCESS;

PROCESS(CLK, BTCLR, Addr, HEU0)
BEGIN
    IF (BTCLR = '1' OR HEU0 = '1') THEN
        BTCNT <= X"00000000";
    ELSIF rising_edge(CLK) THEN
        IF (Addr = X"820" AND BTWrite = '1') THEN
            BTCNT <= BTCNT_io;
        ELSIF (BTHOLD = '0') THEN
            BTCNT <= BTCNT + 1;
        END IF;
    END IF;
END PROCESS;


PROCESS(CLK)
BEGIN
    IF rising_edge(CLK) THEN
        IF BTCLR = '1' THEN
				Q32_i <= '0';
            Q28_i <= '0';
            Q24_i <= '0';
            BTCNT_prev <= (others => '0');
        ELSE
            -- falling edge detection
            Q32_i <= BTCNT_prev(31) AND NOT BTCNT(31);
            Q28_i <= BTCNT_prev(27) AND NOT BTCNT(27);
            Q24_i <= BTCNT_prev(23) AND NOT BTCNT(23);

            BTCNT_prev <= BTCNT;
        END IF;
    END IF;
END PROCESS;

Q32 <= Q32_i and round and CLK;
Q28 <= Q28_i and round and CLK;
Q24 <= Q24_i and round and CLK;	
	-- Select the Basic Timer IFG from BTCNT
	WITH BTIPx SELECT BTIFG <= 
		Q32	WHEN	"11",
		Q28 	WHEN	"10",
		Q24 	WHEN	"01",
		HEU0	WHEN	"00",
		'0'	WHEN	OTHERS;

END structure;