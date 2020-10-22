library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
--*****************************************************************************
--*
--* Name:  Timer
--* Designer: Kaleb Key
--*
--* I designed a VHDL component that provides
--* basic stop watch functionality. The design will start at 20 and end the
--* count down at the right-most 7 seg display. When the center button is
--* pressed it will cause the count to start and stop. The down button will
--* reset the counter to 20. If the count reaches 00, the segs of the two-
--* left most 7 segs will create a victory pattern.
--*
--*****************************************************************************
entity CountDown is
port(
btnD: in std_logic := '0';
btnC: in std_logic := '0';

seg: out std_logic_vector (6 downto 0);
led: out std_logic_vector (3 downto 0);
an: out std_logic_vector (3 downto 0);
clk: in std_logic := '0'
);
end CountDown;
architecture CountDown_ARCH of CountDown is
----general definitions----------------------------------CONSTANTS
constant ACTIVE: std_logic := '1';
constant PASSIVE: std_logic := '0';
constant DISABLE_RESET: std_logic := '0';
constant DISABLE_DIGIT: std_logic := '1';
constant ENABLE_DIGIT: std_logic := '0';
----normal seven segment display-------------------------------------CONSTANTS



constant ZERO_7SEG: std_logic_vector(3 downto 0) := "0000";
constant ONE_7SEG: std_logic_vector(3 downto 0) := "0001";
constant TWO_7SEG: std_logic_vector(3 downto 0) := "0010";
constant THREE_7SEG: std_logic_vector(3 downto 0) := "0011";
constant FOUR_7SEG: std_logic_vector(3 downto 0) := "0100";
constant FIVE_7SEG: std_logic_vector(3 downto 0) := "0101";
constant SIX_7SEG: std_logic_vector(3 downto 0) := "0110";
constant SEVEN_7SEG: std_logic_vector(3 downto 0) := "0111";
constant EIGHT_7SEG: std_logic_vector(3 downto 0) := "1000";
constant NINE_7SEG: std_logic_vector(3 downto 0) := "1001";
constant A_7SEG: std_logic_vector(3 downto 0) := "1010";
constant B_7SEG: std_logic_vector(3 downto 0) := "1011";
constant C_7SEG: std_logic_vector(3 downto 0) := "1100";
constant D_7SEG: std_logic_vector(3 downto 0) := "1101";
constant E_7SEG: std_logic_vector(3 downto 0) := "1110";
constant F_7SEG: std_logic_vector(3 downto 0) := "1111";
----leds-----------------------------------------------------------CONSTANTS
constant ZERO_LED: std_logic_vector(3 downto 0) := "0000";
constant ONE_LED: std_logic_vector(3 downto 0) := "0001";
constant TWO_LED: std_logic_vector(3 downto 0) := "0010";
constant THREE_LED: std_logic_vector(3 downto 0) := "0011";
constant FOUR_LED: std_logic_vector(3 downto 0) := "0100";
constant FIVE_LED: std_logic_vector(3 downto 0) := "0101";
constant SIX_LED: std_logic_vector(3 downto 0) := "0110";
constant SEVEN_LED: std_logic_vector(3 downto 0) := "0111";
constant EIGHT_LED: std_logic_vector(3 downto 0) := "1000";
constant NINE_LED: std_logic_vector(3 downto 0) := "1001";
----internal connections-----------------------------------SIGNALS
signal digit3_value: std_logic_vector(3 downto 0);
signal digit2_value: std_logic_vector(3 downto 0);
signal digit1_value: std_logic_vector(3 downto 0);
signal digit0_value: std_logic_vector(3 downto 0);
signal digit3_blank: std_logic;
signal digit2_blank: std_logic;
signal digit1_blank: std_logic;
signal digit0_blank: std_logic;
signal ButtonSync: std_logic;
signal Button: std_logic;
signal countActive: std_logic := '0';
signal OneSec_Count: std_logic;
signal reset: std_logic := '0';



signal Decode: integer range 20 downto 0;
signal victory: integer range 20 downto 0;
signal victoryInit: std_logic := '0';
signal victoryLap: std_logic;
----state-machine-declarations----------------------------CONSTANTS
type states is (STOP_PRESSED,STOP_RELEASED, START_PRESSED,
START_RELEASED);
signal CurrentState: states;
signal NextState: states;
----imported SevenSegmentDriver----------------------------------
component SevenSegmentDriver
port(
reset: in std_logic;
clock: in std_logic;
digit0: in std_logic_vector(3 downto 0);
digit1: in std_logic_vector(3 downto 0);
digit2: in std_logic_vector(3 downto 0);
digit3: in std_logic_vector(3 downto 0);
blank0: in std_logic;
blank1: in std_logic;
blank2: in std_logic;
blank3: in std_logic;
sevenSegs: out std_logic_vector(6 downto 0);
anodes: out std_logic_vector(3 downto 0)
);
end component;
begin
----Name change for easier reading------
Button <= btnC;
reset <= btnD;
----Imported Driver------------------
MY_SEGMENTS: SevenSegmentDriver port map(
reset => DISABLE_RESET,
clock => clk,
digit3 => digit3_value,
digit2 => digit2_value,



digit1 => digit1_value,
digit0 => digit0_value,
blank3 => digit3_blank,
blank2 => digit2_blank,
blank1 => digit1_blank,
blank0 => digit0_blank,
SevenSegs => seg,
anodes => an
);
-------------------------------------------------------------------
--state-machine-register------------------------------------PROCESS
-------------------------------------------------------------------
STATE_REGISTER: process(reset, clk)
begin
if (reset = ACTIVE) then
CurrentState <= STOP_PRESSED;
elsif (rising_edge(clk)) then
CurrentState <= NextState;
end if;
end process;
-------------------------------------------------------------------
--state-machine-transition----------------------------------PROCESS
-------------------------------------------------------------------
STATE_TRANSITION: process(CurrentState)
begin
case(CurrentState) is
when STOP_PRESSED =>
countActive <= not ACTIVE;
if(ButtonSync = not ACTIVE) then
NextState <= STOP_RELEASED;
else
NextState <= STOP_PRESSED;
end if;
when STOP_RELEASED =>
countActive <= not ACTIVE;
if(ButtonSync = ACTIVE) then
NextState <= START_PRESSED;
else
NextState <= STOP_RELEASED;
end if;
when START_PRESSED =>
countActive <= ACTIVE;
if(ButtonSync = not ACTIVE)then



NextState <= START_RELEASED;
else
NextState <= START_PRESSED;
end if;
when others =>
countActive <= ACTIVE;
if(ButtonSync = ACTIVE) then
NextState <= STOP_PRESSED;
else
NextState <= START_RELEASED;
end if;
end case;
end process;
-------------------------------------------------------------------
--counter from outside resources----------------------------PROCESS
-------------------------------------------------------------------
ONE_SECOND: process(clk,reset)
variable count: integer range 0 to 100000000;
begin
OneSec_Count <= '0';
if(reset = ACTIVE) then
count := 0;
elsif(rising_edge(clk)) then
if(countActive = ACTIVE) then
if(count = 100000000) then
OneSec_Count <= not OneSec_Count;
count :=0;
else
count := count + 1;
end if;
else
OneSec_Count <= OneSec_Count;
end if;
end if;
end process;
-------------------------------------------------------------------
--syncing buttons to the board----------------------------PROCESS
-------------------------------------------------------------------
SYNC_BUTTON: process(clk,reset)
begin
if(reset = ACTIVE) then
ButtonSync <= not ACTIVE;
elsif(rising_edge(clk)) then
ButtonSync <= Button;



end if;
end process;
-------------------------------------------------------------------
--victory laps----------------------------PROCESS
-------------------------------------------------------------------
SHORT_COUNTER: process(clk,reset)
variable count: integer range 0 to 10000000;
begin
VictoryLap <= '0';
if(reset = ACTIVE) then
count := 0;
elsif(rising_edge(clk)) then
if(VictoryInit = ACTIVE) then
if(count = 10000000) then
VictoryLap <= not VictoryLap;
count := 0;
else
count := count + 1;
end if;
else
VictoryLap <= VictoryLap;
end if;
end if;
end process;
-----------------------------------------------------------------------
--initialize the victory to not show unless the timer is 0
-----------------------------------------------------------------------
VictoryInit <= PASSIVE when (decode /=0) else
ACTIVE when (decode = 0);
-------------------------------------------------------------------
--timer run by seconds timer---------------------------PROCESS
-------------------------------------------------------------------
COUNT: process(clk,reset)
variable CountDown: integer range 20 downto 0;
begin
if(reset = ACTIVE) then
CountDown := 20;
elsif(rising_edge(clk)) then
if(CountDown > 0) then
if(OneSec_Count = ACTIVE) then
CountDown := CountDown -1;
decode <= CountDown;
else



decode <= CountDown;
end if;
end if;
end if;
end process;
-------------------------------------------------------------------
--victory pattern/timing----------------------------PROCESS
-------------------------------------------------------------------
VICTORY_COUNT: process(clk,reset)
variable CountDown: integer range 9 downto 0;
begin
if(reset = ACTIVE) then
CountDown := 9;
elsif(rising_edge(clk)) then
if(CountDown > 0) then
if(VictoryLap = ACTIVE) then
CountDown := CountDown -1;
victory <= CountDown;
else
victory <= CountDown;
end if;
else
CountDown := 9;
end if;
end if;
end process;
-------------------------------------------------------------------
--DECODER---------------------------------------------------PROCESS
-------------------------------------------------------------------
DECODER: process(decode,victory)
variable digitValue: integer range 9 downto 0;
begin
digitValue := 0;
digit3_blank <= DISABLE_DIGIT;
digit2_blank <= DISABLE_DIGIT;
digit0_blank <= ENABLE_DIGIT;
if(decode > 9) then
if(decode = 20) then
digit0_value <= ZERO_7SEG;
digit1_blank <= ENABLE_DIGIT;
digit1_value <= TWO_7SEG;
else
digit1_blank <= ENABLE_DIGIT;
digit1_value <= ONE_7SEG;



digitValue := decode
-10;

end if;
else
digit1_blank <= DISABLE_DIGIT;
digitValue := decode;
end if;
case(digitValue) is
when 0 =>
digit0_value <= ZERO_7SEG;
led <= ZERO_LED;
when 1 =>
digit0_value <= ONE_7SEG;
led <= ONE_LED;
when 2 =>
digit0_value <= TWO_7SEG;
led <= TWO_LED;
when 3 =>
digit0_value <= THREE_7SEG;
led <= THREE_LED;
when 4 =>
digit0_value <= FOUR_7SEG;
led <= FOUR_LED;
when 5 =>
digit0_value <= FIVE_7SEG;
led <= FIVE_LED;
when 6 =>
digit0_value <= SIX_7SEG;
led <= SIX_LED;
when 7 =>
digit0_value <= SEVEN_7SEG;
led <= SEVEN_LED;
when 8 =>
digit0_value <= EIGHT_7SEG;
led <= EIGHT_LED;
when others =>
digit0_value <= NINE_7SEG;
led <= NINE_LED;
end case;
case(victory) is
when 9 =>
digit3_blank <= DISABLE_DIGIT;
digit2_blank <= DISABLE_DIGIT;
when 8 =>
digit3_blank <= ENABLE_DIGIT;



digit3_value <= A_7SEG;
when 7 =>
digit2_blank <= ENABLE_DIGIT;
digit2_value <= A_7SEG;
when 6 =>
digit2_blank <= ENABLE_DIGIT;
digit2_value <= B_7SEG;
when 5 =>
digit2_blank <= ENABLE_DIGIT;
digit2_value <= C_7SEG;
when 4 =>
digit2_blank <= ENABLE_DIGIT;
digit2_value <= D_7SEG;
when 3 =>
digit3_blank <= ENABLE_DIGIT;
digit3_value <= D_7SEG;
when 2 =>
digit3_blank <= ENABLE_DIGIT;
digit3_value <= E_7SEG;
when 1 =>
digit3_blank <= ENABLE_DIGIT;
digit3_value <= F_7SEG;
when others =>
digit3_blank <= DISABLE_DIGIT;
digit2_blank <= DISABLE_DIGIT;
digit1_blank <= DISABLE_DIGIT;
digit0_blank <= DISABLE_DIGIT;
end case;
end process;
end CountDown_ARCH;