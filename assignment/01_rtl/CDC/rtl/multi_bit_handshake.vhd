----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.09.2026 09:56:17
-- Design Name: 
-- Module Name: multi_bit_handshake - Behavioral
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

entity multi_bit_handshake is
 generic(data_width: integer:=8);
Port (sclk,dclk,reset_n,sready,dbusy:in std_logic;
      data_in:in std_logic_vector (data_width-1 downto 0);
      dvalid,sidle:out std_logic;
      data_out:out std_logic_vector (data_width-1 downto 0));
end multi_bit_handshake;



architecture Behavioral of multi_bit_handshake is
--state definition
TYPE s_state_type is(s_idle,s_wait_ack1,s_wait_ack0);
signal s_state,n_sstate:s_state_type;
TYPE d_state_type is(d_idle,d_wait_next);
signal d_state,n_dstate:d_state_type;
---internal signal definition
signal dreq,sack:std_logic:='0';
signal sreq,dack:std_logic:='0';
signal s_data:std_logic_vector (data_width-1 downto 0);--temp reg for storing data
begin
----request signal synchronizer----
STD_clock_syn : entity work.clock_synchronizer port map (clk=>dclk,reset_n=>reset_n,din=>sreq,syn_out=>dreq);
DTS_clock_syn : entity work.clock_synchronizer port map (clk=>sclk,reset_n=>reset_n,din=>dack,syn_out=>sack);


process(sclk,reset_n) 
   begin
     if(reset_n='0')then
        s_data<= (others=>'0');
        elsif rising_edge(sclk) then
              if(sready ='1')and(s_state=s_idle)then
               s_data<=data_in;
             end if;
              end if;  
        end process;
--next state logic for source side
process(sclk,reset_n) 
   begin
     if(reset_n='0')then
        s_state<= s_idle;
        elsif rising_edge(sclk) then
              s_state<=n_sstate;
             end if;
        end process;
-----source side FSM logic        
process(s_state, sready, sack) begin
       case s_state is
        when s_idle=>
        if(sready='1')then
          n_sstate<=s_wait_ack1;
           else
            n_sstate<=s_idle;
            end if;
        
        when s_wait_ack1=>
           if(sack='1')then
             n_sstate<=s_wait_ack0;
            else      
               n_sstate<=s_wait_ack1;
              end if;
              
        when s_wait_ack0=>
          if(sack='0')then
             n_sstate<= s_idle;
            else
             n_sstate<=s_wait_ack0;
             end if;
        when others=>
             n_sstate<=s_idle;     
             
             end case;
           end process;  

---source sreq signal management
process(sclk ,reset_n)
 begin 
  if reset_n='0' then 
   sreq<='0';
   elsif rising_edge(sclk)then
    case(n_sstate) is
     when s_wait_ack0=>
       sreq<='0';
       when s_wait_ack1=>
        sreq<='1';
       when others=>
         sreq<='0';
       end case;
       end if;
    end process;      
------sidle signal logic--------------
sidle<='1' when s_state=s_idle else '0';           

-----destination fsm ---------------d_idle,d_wait_next
process(d_state,dreq,dbusy)
begin
  case (d_state) is
        when d_idle =>
          if (dreq='1')and dbusy='0' then
          n_dstate<= d_wait_next;
          else
            n_dstate<=d_idle;
            end if;
            
          when d_wait_next=>
            if(dreq='0')then
             n_dstate<=d_idle;
             else 
              n_dstate<=d_wait_next;
              end if;
          when others=>
                n_dstate<=d_idle;
                end case;
       end process      ;
       
---destination next state management---- 
process(dclk,reset_n)
 begin 
  if (reset_n='0')then
      d_state<=d_idle;
      elsif rising_edge(dclk)then
       d_state<=n_dstate;
       end if;
end process;

-----dack signal management----
dack<='0' when d_state=d_idle else '1';


process(dclk,reset_n)
begin
  if(reset_n='0')then
   dvalid<='0';
   data_out<=(others=>'0');
   elsif rising_edge(dclk)then
        if(d_state=d_idle)and dreq='1' and dbusy='0'then
        dvalid<='1';
        data_out<=s_data;
        else
        dvalid<='0';
        end if;
        end if;
end process;
         
       
end Behavioral;