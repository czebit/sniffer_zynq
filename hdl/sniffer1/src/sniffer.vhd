----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.05.2021 18:09:38
-- Design Name: 
-- Module Name: sniffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sniffer is
    Generic ( SEQ_LENGHT : NATURAL := 16;
              BUS_WIDTH : NATURAL := 64);
    Port ( CLK : in STD_LOGIC;
           RESETn : in STD_LOGIC;
           DATA_IN : in STD_LOGIC_VECTOR (BUS_WIDTH-1 downto 0);
           SEQ_IN : in STD_LOGIC_VECTOR (7 downto 0);
           MATCH : out STD_LOGIC_VECTOR(BUS_WIDTH/8-1 downto 0);
           MODE : in STD_LOGIC;
           START : in STD_LOGIC;
           READY : out STD_LOGIC);
end sniffer;

architecture Behavioral of sniffer is

subtype WORD is STD_LOGIC_VECTOR(7 downto 0);
type SHIFT_REG is array(SEQ_LENGHT-1 downto 0) of WORD;
type state_type is (START_S, TOP, BOT, CLOSE);

signal state : state_type;
signal match_seq_top : SHIFT_REG;
signal match_seq_bot : SHIFT_REG;
signal data_str : SHIFT_REG;
signal matching_result : STD_LOGIC_VECTOR(SEQ_LENGHT-1 downto 0);
signal cnt : natural range 0 to 10;
signal cntD : natural range 0 to 10;
signal input_reg : STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
signal ready_i : STD_LOGIC;
signal match_i : STD_LOGIC_VECTOR(7 downto 0);

begin

cntD_proc: process(CLK)
begin
    if rising_edge(CLK) then
    cntD <= cnt;
    end if;
end process;


input_register: process(CLK)
begin
    if rising_edge(CLK) then
        if RESETn = '0' then
            input_reg <= (others=>'0');
        else
            if MODE = '0' then
                if cnt = 0 then
                    input_reg <= DATA_IN;
                else
                    if cnt > 0 and cnt < 9 then
                    input_reg <= input_reg srl 8;
                    else
                    input_reg <= input_reg;
                    end if;
                end if;
            else
                input_reg <= input_reg;
            end if;
        end if;
    end if;
end process;

data_reg_process : process(CLK)
begin
    if rising_edge(CLK) then
        if MODE = '0' then
            if cnt > 0 and cnt < 9 then
            data_str(SEQ_LENGHT-1) <= input_reg(7 downto 0);
            data_str(SEQ_LENGHT-2 downto 0) <= data_str(SEQ_LENGHT-1 downto 1);
            end if;
        end if;
    end if;
end process;


parse_seq_process : process(CLK)
begin
    if rising_edge(CLK) then
        if RESETn = '0' then
            state <= START_S;
        else
            case state is
                when START_S =>
                    if MODE = '1' and SEQ_IN = x"5B" and START = '1' then /* when "[" read next character */
                        state <= BOT;
                    else
                        state <= START_S;
                    end if;
                when BOT =>
                    if MODE = '1' then
                        if START = '1' then
                            if SEQ_IN = x"5D" then /* "]" means match all characters */
                                match_seq_top(match_seq_top'LEFT) <= (others=>'1');
                                match_seq_top(match_seq_top'LEFT-1 downto 0) <= match_seq_top(match_seq_top'LEFT downto 1);
                                match_seq_bot(match_seq_bot'LEFT) <= (others=>'0');
                                match_seq_bot(match_seq_bot'LEFT-1 downto 0) <= match_seq_bot(match_seq_bot'LEFT downto 1);
                                state <= START_S;
                            else /* if not "[",  read lower limit of characters*/
                                match_seq_bot(match_seq_bot'LEFT) <= SEQ_IN;
                                match_seq_bot(match_seq_bot'LEFT-1 downto 0) <= match_seq_bot(match_seq_bot'LEFT downto 1);
                                state <= TOP;
                            end if;
                        else
                            state <= BOT;
                        end if;
                    else
                        state <= START_S;
                    end if;
                when TOP =>
                    if MODE = '1' then /* read upper limit of characters*/
                        if START = '1' then
                            match_seq_top(match_seq_top'LEFT) <= SEQ_IN;
                            match_seq_top(match_seq_top'LEFT-1 downto 0) <= match_seq_top(match_seq_top'LEFT downto 1);
                            state <= CLOSE;
                        else
                            state <= TOP;
                        end if;
                    else
                        state <= START_S;
                    end if;
                when CLOSE =>
                    if START = '1' then
                        state <= START_S;
                    else
                        state <= CLOSE;
                    end if;
            end case;
        end if;
    end if;
end process;


matching_process: process(CLK)
begin
    if rising_edge(CLK) then
        if RESETn = '0' then
            matching_result <= (others=>'0');
        else
            if MODE = '0' then
                for char in SEQ_LENGHT-1 downto 0 loop
                    if match_seq_top(char) >= data_str(char) and match_seq_bot(char) <= data_str(char) then
                        matching_result(char) <= '1';
                    else
                        matching_result(char) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end if;
end process;


cnt_process: process(CLK)
begin
    if rising_edge(CLK) then
        if RESETn = '0' then
            cnt <= 0;
        else
            if MODE = '0' then
                if START = '1' then
                    cnt <= 0;
                else
                    if cnt < 10 then
                        cnt <= cnt + 1;
                    else
                        cnt <= cnt;
                    end if;
                end if;
            else
                cnt <= cnt;
            end if;
        end if;
    end if;
end process;


match_register: process(CLK)
begin
    if rising_edge(CLK) then
        if RESETn = '0' then
            match_i <= (others=>'0');
        else
            if cnt > 1 and cnt < 9 then
                match_i(cnt-2) <= and matching_result;
            elsif cntD = 8 and cnt = 9 then
                match_i(7) <= and matching_result;
            elsif cnt = 9 then
                match_i(0) <= and matching_result;
                --MATCH(cnt-2) <= and matching_result;
            --elsif cnt = 9 then
               -- MATCH(7) <= and matching_result;
            end if;
        end if;
    end if;
end process;


ready_process: process(CLK)
begin
    if rising_edge(CLK) then
        if cnt = 10 and START = '0' then
            READY <= '1';
            MATCH <= match_i;
        else
            READY <= '0';
            MATCH <= (others=>'0');
        end if;
    end if;
end process;

end Behavioral;
