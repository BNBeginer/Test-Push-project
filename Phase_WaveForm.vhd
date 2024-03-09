----------------------------------------------------------------------------------
-- Company: HVKTQS
-- Engineer: Pham Duc Su
-- 
-- Create Date: 14:10:00 10/24/2020 
-- Design Name: 
-- Module Name: Tao_tinhieu - Behavioral 
-- Project Name: DDS-AD9854
-- Target Devices: Microzed Zc7020
-- Tool versions: Vivado 2107.4
-- Description: 
--
-- Dependencies: 
--
-- Revision: Phien ban nay dung clock noi 100Mhz; Bu lai do tre lenh bang dieu khien xung tao Ma
--
-- Additional Comments: Nap cac gia tri can thiet cho AD9854 de tao tin hieu mong muon
-- Su thay doi xay ra sau khi co xung UD_Clk: 30ns(nen phai tao XUNG_DIEUCHE va XUNG_PHAT hop ly); Tin hieu ra ADS9854 bi tre 300ns
-- Khoang cach 2 xung UD_Clk=Tx
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.Parameters_pkg.all; 

entity Phase_WaveForm is
    Port ( 
		Clk 		: in std_logic;--Clock 200Mhz
		Sync        : in std_logic;
		--Parameters into
		PhaseCode	: in   STD_LOGIC_VECTOR (7 downto 0);--1: Baker7; 2: Barker11; 3: Barker13
		Txc			: in   STD_LOGIC_VECTOR (15 downto 0);
	    --Signals out
		GenWin		: out std_logic;
        DataOut 	: out  STD_LOGIC_VECTOR (13 downto 0)
    );
end Phase_WaveForm;

architecture Behavioral of Phase_WaveForm is
--Signals
signal Phase_control: std_logic_vector(31 downto 0):= (others => '0');

signal DataOut_tmp: std_logic_vector(15 downto 0):= (others => '0');
signal Resetn_tmp: std_logic;
signal XungPhat_tmp: std_logic;
signal InnerPulse_tmp: std_logic;
---Inner Modules
COMPONENT PhaseModulation
	Port ( 	
		Clk 			: in  STD_LOGIC;--clk(=200Mhz)
		Sync	 		: in  STD_LOGIC;
			
		PhaseCode		: in  STD_LOGIC_VECTOR(7 DOWNTO 0);--1: Baker7; 2: Barker11; 3: Barker13
		Txc				: in  STD_LOGIC_VECTOR(15 DOWNTO 0);--Do rong xung con
		XungPhat 		: out  STD_LOGIC;--Muc cao trong suot thoi gian ton tai cua xung phat
		InnerPulse 		: out  STD_LOGIC--Muc logic cua xung dieu che
	);
END COMPONENT;

COMPONENT DDS_PhaseWave
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
begin
	PhaseWave : DDS_PhaseWave
      PORT MAP (
        aclk => Clk,
        aresetn => Resetn_tmp,
        s_axis_config_tvalid => '1',
        s_axis_config_tdata => Phase_control,
        m_axis_data_tdata => DataOut_tmp
      );
	DataOut <= DataOut_tmp(13 downto 0);  
	
	PhaseMod : PhaseModulation
      PORT MAP (
        Clk => Clk,
        Sync => Sync,
		PhaseCode => PhaseCode,
		Txc => Txc,
		XungPhat => XungPhat_tmp,
		InnerPulse => InnerPulse_tmp
      );
	 
	--Control Phase of DDS
	PhaseControler: process(Clk)
	begin
		if rising_edge(Clk) then
			if XungPhat_tmp = '1' then
				if InnerPulse_tmp = '1' then
					Phase_control <= Phase1;
				else
					Phase_control <= Phase0;
				end if;
			end if;
			Resetn_tmp <= XungPhat_tmp;--Delay 1 Clk to sync with Phase_control
		end if;	
	end process;
	GenWin <= XungPhat_tmp;
	
end Behavioral;

