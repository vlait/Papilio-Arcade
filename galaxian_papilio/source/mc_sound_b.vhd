--------------------------------------------------------------------------------
--- Galaxian synthesized sounds
---
--- By Grant Searle 2014
--------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity MC_SOUND_B is
	port(
		I_CLK    : in  std_logic;   --   6MHz
		I_RSTn    : in  std_logic;
		I_NOISE    : in  std_logic;
		I_BG_SOUND : in  std_logic_vector( 3 downto 0);
		I_FS1    : in  std_logic;
		I_FS2    : in  std_logic;
		I_FS3    : in  std_logic;
		I_HIT    : in  std_logic;
		I_FIRE    : in  std_logic;
		O_SDAT    : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of MC_SOUND_B is

signal fireDecayCount  : std_logic_vector(15 downto 0) := (others => '0');
signal fireVol  : std_logic_vector(7 downto 0) := (others => '0');
signal fireSig  : std_logic_vector(7 downto 0) := (others => '0');

signal hitDecayCount  : std_logic_vector(15 downto 0) := (others => '0');
signal hitVol  : std_logic_vector(7 downto 0) := (others => '0');
signal hitSig  : std_logic_vector(7 downto 0) := (others => '0');

signal rampPrescale : std_logic_vector(13 downto 0) := (others => '0');
signal prescaleQ : std_logic :='0';
signal rampPrescale2 : std_logic_vector(4 downto 0) := (others => '0');
signal bgSoundPrescale : std_logic_vector(4 downto 0) := (others => '0');
signal bgRamp : std_logic_vector(3 downto 0) := (others => '0');

signal fs1Clk : std_logic_vector(8 downto 0) := (others => '0');
signal fs2Clk : std_logic_vector(8 downto 0) := (others => '0');
signal fs3Clk : std_logic_vector(8 downto 0) := (others => '0');
signal fs1Q : std_logic :='0';
signal fs2Q : std_logic :='0';
signal fs3Q : std_logic :='0';
signal fs1Sig : std_logic_vector(7 downto 0) := (others => '0');
signal fs2Sig : std_logic_vector(7 downto 0) := (others => '0');
signal fs3Sig : std_logic_vector(7 downto 0) := (others => '0');

signal lpSig : std_logic_vector(7 downto 0) := (others => '0');
signal lpSigSum : std_logic_vector(10 downto 0) := (others => '0');

signal countLPF : std_logic_vector(10 downto 0) := (others => '0');

signal counter7s : std_logic_vector(15 downto 0) := (others => '0');
signal countFirePitchBend : std_logic_vector(18 downto 0) := (others => '0');
signal firePitchBend : std_logic_vector(4 downto 0) := (others => '0');


begin

	process (I_CLK, I_FIRE)
	begin
		if I_FIRE = '1' then
			fireVol <= "01000000";
			fireDecayCount <= (others => '0');
		elsif rising_edge(I_CLK) then
			if fireDecayCount /= "1111111111111111" then
				fireDecayCount <= fireDecayCount+1;
			else
				fireDecayCount <= (others => '0');
				if fireVol /= "00000000" then
					fireVol <= fireVol-1;
				end if;
			end if;
		end if;
	end process;
	fireSig <= fireVol when counter7S(15)='1' else (others => '0');


	process (I_CLK, I_HIT)
	begin
		if I_HIT = '1' then
			hitVol <= "01000000";
			hitDecayCount <= (others => '0');
		elsif rising_edge(I_CLK) then
			if hitDecayCount /= "1111111111111111" then
				hitDecayCount <= hitDecayCount+1;
			else
				hitDecayCount <= (others => '0');
				if hitVol /= "00000000" then
					hitVol <= hitVol-1;
				end if;
			end if;
		end if;
	end process;
	hitSig <= hitVol when I_NOISE='1' else (others => '0');
	
	O_SDAT <= fireSig + lpSig; -- + hitSig +fs1Sig + fs2Sig + fs3Sig;

	process(I_CLK)
	begin
		if rising_edge(I_CLK) then
			if countLPF < 100 then
				countLPF <= countLPF+1;
			elsif countLPF = 100 then
				countLPF <= countLPF+1;
				lpSigSum <= ("000"&lpSig) + ("000"&lpSig) + ("000"&lpSig) + ("000"&lpSig) + ("000"&lpSig) + ("000"&lpSig) + ("000"&lpSig)
				+ ("000"&hitSig) + ("000"&fs1Sig) + ("000"&fs2Sig) + ("000"&fs3Sig);
			else
				countLPF <= (others => '0');
				lpSig <= lpSigSum(10 downto 3);
			end if;
		end if;
	end process;
	
	process(I_CLK)
	begin
		if rising_edge(I_CLK) then
			if countFirePitchBend < 149999 then
				countFirePitchBend <= countFirePitchBend+1;
			else
				countFirePitchBend <= (others => '0');
				if I_FIRE = '1' then
					if firePitchBend<13 then
						firePitchBend <= firePitchBend+1;
					end if;
				else
					if firePitchBend>0 then
						firePitchBend <= firePitchBend-1;
					end if;
				end if;
			end if;
		end if;
	end process;

	process (I_CLK)
   begin
		if rising_edge(I_CLK) then
			if I_NOISE = '1' then
				counter7S <= counter7S + 28 + ("00000000000" & firePitchBend);
			else
				counter7S <= counter7S + 35 + ("00000000000" & firePitchBend);
			end if;
		end if;
	end process;

	fs1Sig <= "00001111" when I_FS1='1' and fs1Q = '1'  else (others => '0');
	fs2Sig <= "00001111" when I_FS2='1' and fs2Q = '1'  else (others => '0');
	fs3Sig <= "00001111" when I_FS3='1' and fs3Q = '1'  else (others => '0');
	
	process (I_CLK)
	begin
		if rising_edge(I_CLK) then
			if rampPrescale <10499 then
				rampPrescale <= rampPrescale+1;
				prescaleQ <= '0';
			else
				rampPrescale <= (others => '0');
				prescaleQ <= '1';
			end if;
		end if;
	end process;

	process (prescaleQ)
	begin
		if rising_edge(prescaleQ) then
			if rampPrescale2 <= (7+('0'&I_BG_SOUND)) then
				rampPrescale2 <= rampPrescale2+1;
			else
				rampPrescale2 <= (others => '0');
				bgRamp <= bgRamp+1;
			end if;
		end if;
	end process;
	
	process (I_CLK)
	begin
		if rising_edge(I_CLK) then
			if bgSoundPrescale <= (11+('0'&bgRamp)) then
				bgSoundPrescale <= bgSoundPrescale+1;
			else
				bgSoundPrescale <= (others => '0');
				if fs1Clk <416 then
					fs1Clk <= fs1Clk+1;
				else
					fs1Q <= not fs1Q;
					fs1Clk <= (others => '0');
				end if;
				if fs2Clk <311 then
					fs2Clk <= fs2Clk+1;
				else
					fs2Q <= not fs2Q;
					fs2Clk <= (others => '0');
				end if;
				if fs3Clk <212 then
					fs3Clk <= fs3Clk+1;
				else
					fs3Q <= not fs3Q;
					fs3Clk <= (others => '0');
				end if;
			end if;
		end if;
	end process;
  
end RTL;
