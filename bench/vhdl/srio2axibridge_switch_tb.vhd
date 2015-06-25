----------------------------------------------------------------------------------
-- __/\\\\\\\\\\\\\\\_        ____/\\\\\\\\\_____        __/\\\\\\\\\\\\\\\_        
--  _\///////\\\/////__        __/\\\///////\\\___        _\///////\\\/////__       
--   _______\/\\\_______        _\/\\\_____\/\\\___        _______\/\\\_______      
--    _______\/\\\_______        _\/\\\\\\\\\\\/____        _______\/\\\_______     
--     _______\/\\\_______        _\/\\\//////\\\____        _______\/\\\_______    
--      _______\/\\\_______        _\/\\\____\//\\\___        _______\/\\\_______   
--       _______\/\\\_______        _\/\\\_____\//\\\__        _______\/\\\_______  
--        _______\/\\\_______        _\/\\\______\//\\\_        _______\/\\\_______ 
--         _______\///________        _\///________\///__        _______\///________
-- 
-- RapidIO IP Library Core
-- 
-- This file is part of the RapidIO IP library project
-- http://www.opencores.org/cores/rio/

-- Author:  arnaud.samama@thalesgroup.com
-- 
----------------------------------------------------------------------------------
-- 
-- Copyright (C) 2014 Authors and OPENCORES.ORG
-- 
-- 
-- This source file may be used and distributed without 
-- restriction provided that this copyright statement is not 
-- removed from the file and that any derivative work contains 
-- the original copyright notice and the associated disclaimer. 
-- 
-- This source file is free software; you can redistribute it 
-- and/or modify it under the terms of the GNU Lesser General 
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any 
-- later version. 
-- 
-- This source is distributed in the hope that it will be 
-- useful, but WITHOUT ANY WARRANTY; without even the implied 
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
-- PURPOSE. See the GNU Lesser General Public License for more 
-- details. 
-- 
-- You should have received a copy of the GNU Lesser General 
-- Public License along with this source; if not, download it 
-- from http://www.opencores.org/lgpl.shtml 
-- 
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.txt_util.all;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
use std.textio.all;

use work.axi4bfm_pkg.all;
use work.rio_common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity srio2axibridge_switch_tb is
end srio2axibridge_switch_tb;

architecture Behavioral of srio2axibridge_switch_tb is

  constant SWITCH_PORTS : natural := 4;

  component RioSwitch is
    generic(
      SWITCH_PORTS : natural range 3 to 255 := 4; 
      DEVICE_IDENTITY : std_logic_vector(15 downto 0);
      DEVICE_VENDOR_IDENTITY : std_logic_vector(15 downto 0);
      DEVICE_REV : std_logic_vector(31 downto 0);
      ASSY_IDENTITY : std_logic_vector(15 downto 0);
      ASSY_VENDOR_IDENTITY : std_logic_vector(15 downto 0);
      ASSY_REV : std_logic_vector(15 downto 0));
    port(
      clk : in std_logic;
      areset_n : in std_logic;
      
      writeFrameFull_i : in Array1(SWITCH_PORTS-1 downto 0);
      writeFrame_o : out Array1(SWITCH_PORTS-1 downto 0);
      writeFrameAbort_o : out Array1(SWITCH_PORTS-1 downto 0);
      writeContent_o : out Array1(SWITCH_PORTS-1 downto 0);
      writeContentData_o : out Array32(SWITCH_PORTS-1 downto 0);

      readFrameEmpty_i : in Array1(SWITCH_PORTS-1 downto 0);
      readFrame_o : out Array1(SWITCH_PORTS-1 downto 0);
      readFrameRestart_o : out Array1(SWITCH_PORTS-1 downto 0);
      readFrameAborted_i : in Array1(SWITCH_PORTS-1 downto 0);
      readContentEmpty_i : in Array1(SWITCH_PORTS-1 downto 0);
      readContent_o : out Array1(SWITCH_PORTS-1 downto 0);
      readContentEnd_i : in Array1(SWITCH_PORTS-1 downto 0);
      readContentData_i : in Array32(SWITCH_PORTS-1 downto 0);
      
      portLinkTimeout_o : out std_logic_vector(23 downto 0);

      linkInitialized_i : in Array1(SWITCH_PORTS-1 downto 0);
      outputPortEnable_o : out Array1(SWITCH_PORTS-1 downto 0);
      inputPortEnable_o : out Array1(SWITCH_PORTS-1 downto 0);
      
      localAckIdWrite_o : out Array1(SWITCH_PORTS-1 downto 0);
      clrOutstandingAckId_o : out Array1(SWITCH_PORTS-1 downto 0);
      inboundAckId_o : out Array5(SWITCH_PORTS-1 downto 0);
      outstandingAckId_o : out Array5(SWITCH_PORTS-1 downto 0);
      outboundAckId_o : out Array5(SWITCH_PORTS-1 downto 0);
      inboundAckId_i : in Array5(SWITCH_PORTS-1 downto 0);
      outstandingAckId_i : in Array5(SWITCH_PORTS-1 downto 0);
      outboundAckId_i : in Array5(SWITCH_PORTS-1 downto 0);
    
      configStb_o : out std_logic;
      configWe_o : out std_logic;
      configAddr_o : out std_logic_vector(23 downto 0);
      configData_o : out std_logic_vector(31 downto 0);
      configData_i : in std_logic_vector(31 downto 0));
  end component;

	signal clk : std_logic;
	signal sys_clk_p : std_logic;
	signal sys_clk_n : std_logic;
	
	signal gt_clk : std_logic;
	signal gt_clk_p : std_logic;
	signal gt_clk_n : std_logic;

	signal rst_n : std_logic;	
	
	signal busA_p : std_logic_vector(3 downto 0);	
	signal busA_n : std_logic_vector(3 downto 0);
	
	signal busB_p : std_logic_vector(3 downto 0);	
	signal busB_n : std_logic_vector(3 downto 0);
    
    signal master2slave : axi4master2slave_bus_t;
    signal slave2master : axi4slave2master_bus_t;
    
    signal master2slaveLite : AxiLITEmaster2slave_bus_t;
    signal slave2masterLite : AxiLITEslave2master_bus_t; 
    
    constant C_M_AXI_THREAD_ID_WIDTH : integer := 2;
    constant C_M_AXI_ADDR_WIDTH      : integer := 32;
    constant C_M_AXI_DATA_WIDTH      : integer := 32;
    constant C_M_AXI_AWUSER_WIDTH    : integer := 1;
    constant C_M_AXI_ARUSER_WIDTH    : integer := 1;
    constant C_M_AXI_WUSER_WIDTH     : integer := 1;
    constant C_M_AXI_RUSER_WIDTH     : integer := 1;
    constant C_M_AXI_BUSER_WIDTH     : integer := 1;
    constant C_S_AXI_ADDR_WIDTH      : integer := 32;
    constant C_S_AXI_DATA_WIDTH      : integer := 32;   
    constant C_S_AXI_BASE_ADDR       : std_logic_vector(32 - 1 downto 8):= x"FFFF00";
    constant C_AXI_LOCK_WIDTH        : integer := 1;

  
    signal   anError                 : std_logic;
    signal   localAckIdWrite_o       : std_logic;
    signal   clrOutstandingAckId_o   : std_logic;
    signal   inboundAckId_o          : std_logic_vector(4 downto 0);
    signal   outstandingAckId_o      : std_logic_vector(4 downto 0);
    signal   outboundAckId_o         : std_logic_vector(4 downto 0);
    signal   inboundAckId_i          : std_logic_vector(4 downto 0);
    signal   outstandingAckId_i      : std_logic_vector(4 downto 0);
    signal   outboundAckId_i         : std_logic_vector(4 downto 0);
    signal   readFrameEmpty_o        : STD_LOGIC;
    signal   readFrame_i             : STD_LOGIC;
    signal   readFrameRestart_i      : STD_LOGIC;
    signal   readFrameAborted_o      : STD_LOGIC;
    signal   readWindowEmpty_o       : STD_LOGIC;
    signal   readWindowReset_i       : STD_LOGIC;
    signal   readWindowNext_i        : STD_LOGIC;
    signal   readContentEmpty_o      : STD_LOGIC;
    signal   readContent_i           : STD_LOGIC;
    signal   readContentEnd_o        : STD_LOGIC;
    signal   readContentData_o       : STD_LOGIC_VECTOR (31 downto 0);
    signal   writeFrameFull_o        : STD_LOGIC;
    signal   writeFrame            : Array1(SWITCH_PORTS-1 downto 0);
    signal   writeFrame_i            : STD_LOGIC;
    signal   writeFrameAbort_i       : STD_LOGIC;
    signal   writeContent_i          : STD_LOGIC;
    signal   writeContentData_i      : STD_LOGIC_VECTOR (31 downto 0);
    
    signal   anError_br                 : std_logic;
    signal   localAckIdWrite_o_br       : std_logic;
    signal   clrOutstandingAckId_o_br   : std_logic;
    signal   inboundAckId_o_br          : std_logic_vector(4 downto 0);
    signal   outstandingAckId_o_br      : std_logic_vector(4 downto 0);
    signal   outboundAckId_o_br         : std_logic_vector(4 downto 0);
    signal   inboundAckId_i_br          : std_logic_vector(4 downto 0);
    signal   outstandingAckId_i_br      : std_logic_vector(4 downto 0);
    signal   outboundAckId_i_br         : std_logic_vector(4 downto 0);
    signal   readFrameEmpty_o_br        : STD_LOGIC;
    signal   readFrame_i_br             : STD_LOGIC;
    signal   readFrameRestart_i_br      : STD_LOGIC;
    signal   readFrameAborted_o_br      : STD_LOGIC;
    signal   readWindowEmpty_o_br       : STD_LOGIC;
    signal   readWindowReset_i_br       : STD_LOGIC;
    signal   readWindowNext_i_br        : STD_LOGIC;
    signal   readContentEmpty_o_br      : STD_LOGIC;
    signal   readContent_i_br           : STD_LOGIC;
    signal   readContentEnd_o_br        : STD_LOGIC;
    signal   readContentData_o_br       : STD_LOGIC_VECTOR (31 downto 0);
    signal   writeFrameFull_o_br        : STD_LOGIC;
    signal   writeFrame_i_br            : STD_LOGIC;
    signal   writeFrameAbort_i_br       : STD_LOGIC;
    signal   writeContent_i_br          : STD_LOGIC;
    signal   writeContentData_i_br      : STD_LOGIC_VECTOR (31 downto 0);

    signal writeFrameFull_swtch         : Array1(SWITCH_PORTS-1 downto 0);
    signal writeFrame_swtch             : Array1(SWITCH_PORTS-1 downto 0);
    signal writeFrameAbort_swtch        : Array1(SWITCH_PORTS-1 downto 0);
    signal writeContent_swtch           : Array1(SWITCH_PORTS-1 downto 0);
    signal writeContentData_swtch       : Array32(SWITCH_PORTS-1 downto 0);

    signal readFrameEmpty_swtch         : Array1(SWITCH_PORTS-1 downto 0);
    signal readFrame_swtch              : Array1(SWITCH_PORTS-1 downto 0);
    signal readFrameRestart_swtch       : Array1(SWITCH_PORTS-1 downto 0);
    signal readFrameAborted_swtch       : Array1(SWITCH_PORTS-1 downto 0);
    signal readContentEmpty_swtch       : Array1(SWITCH_PORTS-1 downto 0);
    signal readContent_swtch            : Array1(SWITCH_PORTS-1 downto 0);
    signal readContentEnd_swtch         : Array1(SWITCH_PORTS-1 downto 0);
    signal readContentData_swtch        : Array32(SWITCH_PORTS-1 downto 0);

    signal portLinkTimeout_swtch        : std_logic_vector(23 downto 0);

    signal linkInitialized_swtch        : Array1(SWITCH_PORTS-1 downto 0);
    signal outputPortEnable_swtch       : Array1(SWITCH_PORTS-1 downto 0);
    signal inputPortEnable_swtch        : Array1(SWITCH_PORTS-1 downto 0);

    signal localAckIdWrite_swtch        : Array1(SWITCH_PORTS-1 downto 0);
    signal clrOutstandingAckId_swtch    : Array1(SWITCH_PORTS-1 downto 0);
    signal inboundAckId_out_swtch       : Array5(SWITCH_PORTS-1 downto 0);
    signal outstandingAckId_out_swtch   : Array5(SWITCH_PORTS-1 downto 0);
    signal outboundAckId_in_swtch          : Array5(SWITCH_PORTS-1 downto 0);
    signal inboundAckId_in_swtch        : Array5(SWITCH_PORTS-1 downto 0);
    signal outstandingAckId_in_swtch    : Array5(SWITCH_PORTS-1 downto 0);
    signal outboundAckId_out_swtch          : Array5(SWITCH_PORTS-1 downto 0);
    signal configStb: std_logic;
    signal configWe: std_logic;
    signal configAddr: std_logic_vector(23 downto 0);
    signal configData: std_logic_vector(31 downto 0);

    -- Maximum size of an RapidIO frame
    type SRioFrame is array (1 to 266) of std_logic_vector(31 downto 0);
    signal frame : SRioFrame := (others => (others => '0'));
    
    type string_ptr is access string;
    

    
    type SrioFrameType is (
       SRIO_IMPLEMENTATION_DEFINED,
       SRIO_RESERVED,
       SRIO_REQUEST,
       SRIO_WRITE,
       SRIO_SWRITE,
       SRIO_MAINTENANCE,
       SRIO_DOORBELL,
       SRIO_MESSAGE     
    );
    
    impure function CheckResult( 
        test_name   : string;
        expected    : std_logic_vector(31 downto 0);
        data        : std_logic_vector(31 downto 0);
        ok_message  : string) return boolean is
        begin
            if expected /= data then 
                print("ERROR: " & test_name & " read 0x" & hstr(data) & " instead of 0x" & hstr(expected) );
                return false;
            else
                print("OK   : " & test_name & ", " & ok_message);
                return true;
            end if;
            
        end function;
        
  
begin
    writeFrame_i <= writeFrame(1);
    

RioSerial2Axi4Bridge_INST: entity work.RioSerial2Axi4Bridge
   generic map (
      C_M_AXI_THREAD_ID_WIDTH => C_M_AXI_THREAD_ID_WIDTH,
      C_M_AXI_ADDR_WIDTH      => C_M_AXI_ADDR_WIDTH,
      C_M_AXI_DATA_WIDTH      => C_M_AXI_DATA_WIDTH,
      C_M_AXI_AWUSER_WIDTH    => C_M_AXI_AWUSER_WIDTH,
      C_M_AXI_ARUSER_WIDTH    => C_M_AXI_ARUSER_WIDTH,
      C_M_AXI_WUSER_WIDTH     => C_M_AXI_WUSER_WIDTH,
      C_M_AXI_RUSER_WIDTH     => C_M_AXI_RUSER_WIDTH,
      C_M_AXI_BUSER_WIDTH     => C_M_AXI_BUSER_WIDTH,
      C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
      C_AXI_LOCK_WIDTH        => C_AXI_LOCK_WIDTH,

      -- Switch has not been designed for use with the windowed buffer
      C_USE_WINDOW_BUFFER   => false,
      C_S_AXI_BASE_ADDR       => C_S_AXI_BASE_ADDR)
   port map (
      clk                   => clk,
      rst_n                 => rst_n,
      S_AXI_AWADDR          => master2slaveLite.S_AXI_AWADDR,
      S_AXI_AWPROT          => master2slaveLite.S_AXI_AWPROT,
      S_AXI_AWVALID         => master2slaveLite.S_AXI_AWVALID,
      S_AXI_AWREADY         => slave2masterLite.S_AXI_AWREADY,
      S_AXI_WDATA           => master2slaveLite.S_AXI_WDATA,
      S_AXI_WSTRB           => master2slaveLite.S_AXI_WSTRB,
      S_AXI_WVALID          => master2slaveLite.S_AXI_WVALID,
      S_AXI_WREADY          => slave2masterLite.S_AXI_WREADY,
      S_AXI_BRESP           => slave2masterLite.S_AXI_BRESP,
      S_AXI_BVALID          => slave2masterLite.S_AXI_BVALID,
      S_AXI_BREADY          => master2slaveLite.S_AXI_BREADY,
      S_AXI_ARADDR          => master2slaveLite.S_AXI_ARADDR,
      S_AXI_ARPROT          => master2slaveLite.S_AXI_ARPROT,
      S_AXI_ARVALID         => master2slaveLite.S_AXI_ARVALID,
      S_AXI_ARREADY         => slave2masterLite.S_AXI_ARREADY,
      S_AXI_RDATA           => slave2masterLite.S_AXI_RDATA,
      S_AXI_RRESP           => slave2masterLite.S_AXI_RRESP,
      S_AXI_RVALID          => slave2masterLite.S_AXI_RVALID,
      S_AXI_RREADY          => master2slaveLite.S_AXI_RREADY,
      
      M_AXI_AWID            => master2slave.M_AXI_AWID,
      M_AXI_AWADDR          => master2slave.M_AXI_AWADDR,
      M_AXI_AWLEN           => master2slave.M_AXI_AWLEN,
      M_AXI_AWSIZE          => master2slave.M_AXI_AWSIZE,
      M_AXI_AWBURST         => master2slave.M_AXI_AWBURST,
      M_AXI_AWLOCK          => master2slave.M_AXI_AWLOCK,
      M_AXI_AWCACHE         => master2slave.M_AXI_AWCACHE,
      M_AXI_AWPROT          => master2slave.M_AXI_AWPROT,
      M_AXI_AWQOS           => master2slave.M_AXI_AWQOS,
      M_AXI_AWUSER          => master2slave.M_AXI_AWUSER,
      M_AXI_AWVALID         => master2slave.M_AXI_AWVALID,
      M_AXI_AWREADY         => slave2master.M_AXI_AWREADY,
      M_AXI_WDATA           => master2slave.M_AXI_WDATA,
      M_AXI_WSTRB           => master2slave.M_AXI_WSTRB,
      M_AXI_WLAST           => master2slave.M_AXI_WLAST,
      M_AXI_WUSER           => master2slave.M_AXI_WUSER,
      M_AXI_WVALID          => master2slave.M_AXI_WVALID,
      M_AXI_WREADY          => slave2master.M_AXI_WREADY,
      M_AXI_BID             => slave2master.M_AXI_BID,
      M_AXI_BRESP           => slave2master.M_AXI_BRESP,
      M_AXI_BUSER           => slave2master.M_AXI_BUSER,
      M_AXI_BVALID          => slave2master.M_AXI_BVALID,
      M_AXI_BREADY          => master2slave.M_AXI_BREADY,
      M_AXI_ARID            => master2slave.M_AXI_ARID,
      M_AXI_ARADDR          => master2slave.M_AXI_ARADDR,
      M_AXI_ARLEN           => master2slave.M_AXI_ARLEN,
      M_AXI_ARSIZE          => master2slave.M_AXI_ARSIZE,
      M_AXI_ARBURST         => master2slave.M_AXI_ARBURST,
      M_AXI_ARLOCK          => master2slave.M_AXI_ARLOCK,
      M_AXI_ARCACHE         => master2slave.M_AXI_ARCACHE,
      M_AXI_ARPROT          => master2slave.M_AXI_ARPROT,
      M_AXI_ARQOS           => master2slave.M_AXI_ARQOS,
      M_AXI_ARUSER          => master2slave.M_AXI_ARUSER,
      M_AXI_ARVALID         => master2slave.M_AXI_ARVALID,
      M_AXI_ARREADY         => slave2master.M_AXI_ARREADY,
      M_AXI_RID             => slave2master.M_AXI_RID,
      M_AXI_RDATA           => slave2master.M_AXI_RDATA,
      M_AXI_RRESP           => slave2master.M_AXI_RRESP,
      M_AXI_RLAST           => slave2master.M_AXI_RLAST,
      M_AXI_RUSER           => slave2master.M_AXI_RUSER,
      M_AXI_RVALID          => slave2master.M_AXI_RVALID,
      M_AXI_RREADY          => master2slave.M_AXI_RREADY,
      error                 => anError,
      localAckIdWrite_o     => localAckIdWrite_swtch(0),
      clrOutstandingAckId_o => clrOutstandingAckId_swtch(0),
      inboundAckId_o        => inboundAckId_in_swtch(0),
      outstandingAckId_o    => outstandingAckId_in_swtch(0),
      outboundAckId_o       => outboundAckId_in_swtch(0),
      inboundAckId_i        => inboundAckId_out_swtch(0),
      outstandingAckId_i    => outstandingAckId_out_swtch(0),
      outboundAckId_i       => outboundAckId_out_swtch(0),
      readFrameEmpty_o      => readFrameEmpty_swtch(0),
      readFrame_i           => readFrame_swtch(0),
      readFrameRestart_i    => readFrameRestart_swtch(0),
      readFrameAborted_o    => readFrameAborted_swtch(0),
      readWindowEmpty_o     => readWindowEmpty_o,
      readWindowReset_i     => readWindowReset_i,
      readWindowNext_i      => readWindowNext_i,

      readContentEmpty_o    => readContentEmpty_swtch(0),
      readContent_i         => readContent_swtch(0),
      readContentEnd_o      => readContentEnd_swtch(0),
      readContentData_o     => readContentData_swtch(0),
      writeFrameFull_o      => writeFrameFull_swtch(0),
      writeFrame_i          => writeFrame_swtch(0),
      writeFrameAbort_i     => writeFrameAbort_swtch(0),
      writeContent_i        => writeContent_swtch(0),
      writeContentData_i    => writeContentData_swtch(0),

      port_initialized_i => '1',
      Nx_mode_active_i   => '0',
      mgt_pll_locked_i     => '1',
      rxelecidle_i         => "0000",
      linkInitialized_i    => '1'
 
  );

      localAckIdWrite_swtch(1)          <= localAckIdWrite_o;
      clrOutstandingAckId_swtch(1)      <= clrOutstandingAckId_o;
      inboundAckId_in_swtch(1)          <= inboundAckId_o;
      outstandingAckId_in_swtch(1)      <= outstandingAckId_o;
      outboundAckId_in_swtch(1)         <= outboundAckId_o;
      inboundAckId_i                    <= inboundAckId_out_swtch(1);
      outstandingAckId_i                <= outstandingAckId_out_swtch(1);
      outboundAckId_i                   <= outboundAckId_out_swtch(1);
      readFrameEmpty_swtch(1)           <= readFrameEmpty_o;
      readFrame_i                       <= readFrame_swtch(1);
      readFrameRestart_i                <= readFrameRestart_swtch(1);
      readFrameAborted_swtch(1)         <= readFrameAborted_o;
      readContentEmpty_swtch(1)         <= readContentEmpty_o;
      readContent_i                     <= readContent_swtch(1);
      readContentEnd_swtch(1)           <= readContentEnd_o;
      readContentData_swtch(1)          <= readContentData_o;
      writeFrameFull_swtch(1)           <= writeFrameFull_o;
      writeFrame_i                      <= writeFrame_swtch(1);
      writeFrameAbort_i                 <= writeFrameAbort_swtch(1);
      writeContent_i                    <= writeContent_swtch(1);
      writeContentData_i                <= writeContentData_swtch(1);




RioSwitch_INST: entity work.RioSwitch
   generic map (

   SWITCH_PORTS => 4,
   DEVICE_IDENTITY  => x"5A11", 
   DEVICE_VENDOR_IDENTITY => x"DAAA",
   DEVICE_REV => x"00000001",
   ASSY_IDENTITY => x"1111",
   ASSY_VENDOR_IDENTITY => x"2222",
   ASSY_REV => x"0001"
   )

   port map (
      clk                   => clk,
      areset_n                 => rst_n,

      writeFrameFull_i(0) =>  writeFrameFull_swtch(0),
      writeFrameFull_i(1) =>  writeFrameFull_swtch(1),
      writeFrameFull_i(2) =>  writeFrameFull_swtch(2),
      writeFrameFull_i(3) =>  writeFrameFull_swtch(3),

      writeFrame_o(0) =>  writeFrame_swtch(0),
      writeFrame_o(1) =>  writeFrame_swtch(1),
      writeFrame_o(2) =>  writeFrame_swtch(2),
      writeFrame_o(3) =>  writeFrame_swtch(3),

      writeFrameAbort_o(0) =>  writeFrameAbort_swtch(0),
      writeFrameAbort_o(1) =>  writeFrameAbort_swtch(1),
      writeFrameAbort_o(2) =>  writeFrameAbort_swtch(2),
      writeFrameAbort_o(3) =>  writeFrameAbort_swtch(3),

      writeContent_o(0) =>  writeContent_swtch(0),
      writeContent_o(1) =>  writeContent_swtch(1),
      writeContent_o(2) =>  writeContent_swtch(2),
      writeContent_o(3) =>  writeContent_swtch(3),

      writeContentData_o(0) =>  writeContentData_swtch(0),
      writeContentData_o(1) =>  writeContentData_swtch(1),
      writeContentData_o(2) =>  writeContentData_swtch(2),
      writeContentData_o(3) =>  writeContentData_swtch(3),

      readFrameEmpty_i(0) =>  readFrameEmpty_swtch(0),
      readFrameEmpty_i(1) =>  readFrameEmpty_swtch(1),
      readFrameEmpty_i(2) =>  readFrameEmpty_swtch(2),
      readFrameEmpty_i(3) =>  readFrameEmpty_swtch(3),


      readFrame_o(0) =>  readFrame_swtch(0),
      readFrame_o(1) =>  readFrame_swtch(1),
      readFrame_o(2) =>  readFrame_swtch(2),
      readFrame_o(3) =>  readFrame_swtch(3),


      readFrameRestart_o(0) =>  readFrameRestart_swtch(0),
      readFrameRestart_o(1) =>  readFrameRestart_swtch(1),
      readFrameRestart_o(2) =>  readFrameRestart_swtch(2),
      readFrameRestart_o(3) =>  readFrameRestart_swtch(3),

      readFrameAborted_i(0) =>  readFrameAborted_swtch(0),
      readFrameAborted_i(1) =>  readFrameAborted_swtch(1),
      readFrameAborted_i(2) =>  readFrameAborted_swtch(2),
      readFrameAborted_i(3) =>  readFrameAborted_swtch(3),

      readContentEmpty_i(0) =>  readContentEmpty_swtch(0),
      readContentEmpty_i(1) =>  readContentEmpty_swtch(1),
      readContentEmpty_i(2) =>  readContentEmpty_swtch(2),
      readContentEmpty_i(3) =>  readContentEmpty_swtch(3),

      readContent_o(0) =>  readContent_swtch(0),
      readContent_o(1) =>  readContent_swtch(1),
      readContent_o(2) =>  readContent_swtch(2),
      readContent_o(3) =>  readContent_swtch(3),

      readContentEnd_i(0) =>  readContentEnd_swtch(0),
      readContentEnd_i(1) =>  readContentEnd_swtch(1),
      readContentEnd_i(2) =>  readContentEnd_swtch(2),
      readContentEnd_i(3) =>  readContentEnd_swtch(2),

      readContentData_i(0) =>  readContentData_swtch(0),
      readContentData_i(1) =>  readContentData_swtch(1),
      readContentData_i(2) =>  readContentData_swtch(2),
      readContentData_i(3) =>  readContentData_swtch(3),

      portLinkTimeout_o =>  portLinkTimeout_swtch,

      linkInitialized_i =>  linkInitialized_swtch,

      outputPortEnable_o =>  outputPortEnable_swtch,

      inputPortEnable_o =>  inputPortEnable_swtch,

      inboundAckId_i =>  inboundAckId_in_swtch,

      outstandingAckId_i =>  outstandingAckId_in_swtch,

      outboundAckId_i =>  outboundAckId_in_swtch,

      localAckIdWrite_o =>  localAckIdWrite_swtch,

      clrOutstandingAckId_o =>  clrOutstandingAckId_swtch,

      inboundAckId_o =>  inboundAckId_out_swtch,

      outstandingAckId_o =>  outstandingAckId_out_swtch,

      outboundAckId_o =>  outboundAckId_out_swtch,

      configStb_o => configStb,
      configWe_o => configWe,
      configAddr_o => configAddr,
      configData_o => configData,
      configData_i => (others => '0')

  );
  
  
	-----------------------------------------------------------------------------
	-- Clock generation.
	-----------------------------------------------------------------------------
	-- 200 MHz
	SysClockGenerator: process
	begin
		clk <= '0';
		wait for 2.5 ns;
		clk <= '1';
		wait for 2.5 ns;
	end process;

		
	TestDriver: process
        variable data : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        variable result : boolean;
        variable frame_size : integer;
        variable frame_type : SrioFrameType;
        variable test_result : boolean;
        -- Contains the last payload size computed by the checking function
        variable payload_size : unsigned(31 downto 0);
        variable offset_addr  : unsigned(31 downto 0);
        variable base_addr   : unsigned(31 downto 0);
        
        procedure SetInboundWriteContent(
            constant frame : in RioFrame) is
        begin
            writeFrame_i <= '0';
            assert writeFrameFull_o = '0' report "Inbound frame cannot be accepted." severity ERROR;
            print("Frame length " & str(frame.length) );
            for i in 0 to frame.length -1 loop
              
                writeContent_i <= '1';
                writeContentData_i <= frame.payload(i);
                wait until rising_edge(clk);              

            end loop;
            wait for 1 ns;
            writeContent_i <= '0';
            writeFrame_i <= '1';
            writeContentData_i <= (others=>'U');
            wait until rising_edge(clk);
            wait for 1 ns;
            writeFrame_i <= '0';
        end procedure;

        procedure SetInboundWriteFrame is
        begin
            writeFrame_i <= '1';
            wait until clk'event and clk = '1';
            wait for 1 ns;

            writeFrame_i <= '0';
        end procedure;       

        
        
        procedure UnloadSRIOFrame( signal clk : std_logic; size_frame : out integer ) is
            variable srio_word : integer := 0;
            variable srio_bytes : integer ;
        begin
            readcontent_i               <= '0';
            readFrame_i                 <= '0';
            readFrameRestart_i          <= '0';
            readWindowReset_i           <= '0';
            readWindowNext_i            <= '0';
            
            -- Waiting for a frame being present
            wait until  rising_edge(clk) and readContentEmpty_o = '0';
            
            print("OK   : Starting to retrieve SRIO frame ");
            -- while the frame is not terminated.
            --while readContentEnd_o /= '1'  loop
            loop
            
                -- Ask for the next word being presented
                readContent_i <= '1'; 
                wait until  rising_edge(clk) ;
                wait for 1 ns;
                
                if readContentEnd_o /= '1' then 
                
                    srio_word := srio_word + 1; 
                    -- Word should be available
                    frame(srio_word) <= readContentData_o;

                    
                    
                    -- If there is no data available, we wait for them
                    if readContentEmpty_o = '1' then
                        readContent_i <= '0';
                        wait until  rising_edge(clk) and readContentEmpty_o = '0';
                    end if;
                else

                    exit;
                end if;
                

                
            end loop;
            readcontent_i <= '0'; 
            
            -- Ack the frame
            readWindowNext_i <= '1';
            wait until  rising_edge(clk);
            readWindowNext_i <= '0';
            
            srio_bytes := srio_word * (C_S_AXI_DATA_WIDTH /8);
            -- Maximum SRIO is 69 words of 32 bits
            if srio_bytes <= 276 then 
                print("OK   : Retrieved " & str(srio_bytes) & " bytes from SRIO Buffer");
            else
                print("ERROR: Retrieved " & str(srio_bytes) & " bytes from SRIO Buffer");
            end if;
            
            size_frame := srio_word;
            
        end procedure;
        
  
        
        procedure strcat( lhs : inout string; rhs : in string) is
            variable pos_lhs : integer := lhs'left;
            variable pos_rhs : integer := rhs'left;
        begin
            loop
                exit when lhs(pos_lhs) = NUL or pos_lhs > lhs'right;
                pos_lhs := pos_lhs + 1;
            end loop;
            
            loop
                exit when pos_lhs > lhs'right or pos_rhs > rhs'right;
                
                if rhs(pos_rhs) /= NUL then
                    lhs(pos_lhs) := rhs(pos_rhs);
                    pos_lhs := pos_lhs + 1;
                    pos_rhs := pos_rhs + 1;
                end if;
            end loop;
                
        end procedure;
        
        --Procedure DecodeSRIOFrame( aFrame: SRioFrame; size : integer) is
        impure function DecodeSRIOFrame( aFrame: SRioFrame; size : integer) return SrioFrameType is
            variable packet_header : std_logic_vector(31 downto 0);
            variable specific_header : std_logic_vector(31 downto 0);
            variable data_01 : std_logic_vector(31 downto 0);
            variable data_02 : std_logic_vector(31 downto 0);
            variable ftype_str : string( 1 to 255);
            variable frame_type : SrioFrameType;

        begin
            -- First word is the header
            packet_header   := aFrame(1);
            
            print(" AckId   : " & hstr(packet_header(31 downto 26)));
            print(" VC      : " & str(packet_header(25)));
            print(" CRF     : " & str(packet_header(24)));
            print(" PRIO    : " & str(packet_header(23 downto 22)));
            print(" TT      : " & str(packet_header(21 downto 20)));

            -- Are we using long or short ID ?
            if packet_header(21 downto 20) = "01" then
                specific_header(31 downto 16) := aFrame(2)(15 downto 0);
                specific_header(15 downto 0)  := aFrame(3)(31 downto 16);
                data_01         := aFrame(3)(15 downto 0) & aFrame(4)(31 downto 16);
                data_02         := aFrame(4)(15 downto 0) & aFrame(5)(31 downto 16);
            else
                specific_header := aFrame(2);
                data_01         := aFrame(3);
                data_02         := aFrame(4);
            end if;

            
            case ( packet_header(19 downto 16) ) is
                when "0000" =>
                    strcat( ftype_str, "Implementation defined");
                    frame_type := SRIO_IMPLEMENTATION_DEFINED;
                    
                when "0001" =>
                    strcat( ftype_str, "Reserved"); 
                    frame_type := SRIO_RESERVED;
                    
                when "0010" =>
                    strcat( ftype_str,"Request");
                    frame_type := SRIO_REQUEST;
                    case packet_header(15 downto 12) is 
                    
                        when "0100" =>
                            strcat( ftype_str," READ");
                        when "1100" =>
                            strcat( ftype_str," ATOMIC INC");
                        when "1101" =>
                            strcat( ftype_str," ATOMIC DEC");
                        when "1110" =>
                            strcat( ftype_str," ATOMIC SET");
                        when "1111" =>
                            strcat( ftype_str," ATOMIC CLR");
                        when others =>
                            strcat( ftype_str," Reserved");  
                        
                    end case;
                        
                when "0011" =>
                   strcat( ftype_str, "Reserved");
                   frame_type := SRIO_RESERVED;
                   
                when "0100" =>
                   strcat( ftype_str, "Reserved");
                   frame_type := SRIO_RESERVED;
                   
                when "0101" =>
                   strcat( ftype_str, "WRITE");
                   frame_type := SRIO_WRITE;
                  case packet_header(15 downto 12) is 
                      when "0100" =>
                         strcat( ftype_str, " NWRITE");
                      when "0101" =>
                         strcat( ftype_str, " NWRITE_R");
                      when "1100" =>
                         strcat( ftype_str, " ATOMIC Swap");
                      when "1101" =>
                         strcat( ftype_str, " ATOMIC Compare_and_swap");
                      when "1110" =>
                         strcat( ftype_str, " ATOMIC Test_and_swap");
                      when others =>
                         strcat( ftype_str, " Reserved");                          
                  end case;                    
                when "0110" =>
                   strcat( ftype_str, "STREAMING-WRITE");
                   frame_type := SRIO_SWRITE;
                   
                when "1000" =>
                   strcat( ftype_str, "MAINTENANCE");
                   frame_type := SRIO_MAINTENANCE;
                  case specific_header(31 downto 28) is 
                      when "0000" =>
                        strcat( ftype_str, " Read request");
                      when "0001" =>
                        strcat( ftype_str, " Write request");
                      when "0010" =>
                        strcat( ftype_str, " Read response");
                      when "0011" =>
                        strcat( ftype_str, " Write response");
                      when "0100" =>
                        strcat( ftype_str, " post-write request");
                      when others =>
                        strcat( ftype_str, " Reserved");                          
                  end case; 
                    strcat( ftype_str, " wrsize=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(27 downto 24)) ) ) );
                    strcat( ftype_str, " srcTID=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(23 downto 16)) ) ) );
                    strcat( ftype_str, " hop_cpunt=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(15 downto 8)) ) ) );
                    strcat( ftype_str, " config_offset=");
                    strcat( ftype_str, hstr(specific_header(7 downto 0) & data_01(31 downto 19)) );
                    strcat( ftype_str, " wdptr=");
                    strcat( ftype_str, str(data_01(18) ) );
                    strcat( ftype_str, " config_data=");
                    strcat( ftype_str, hstr(data_01(15 downto 0) &  data_02(31 downto 16) ) );


                when "1010" =>
                    strcat( ftype_str, "DOORBELL");
                    frame_type := SRIO_DOORBELL;
                    
                when "1011" =>
                    strcat( ftype_str, "MESSAGE ");
                    frame_type := SRIO_MESSAGE;
                    strcat( ftype_str, "length=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(31 downto 28)) ) ) );
                    strcat( ftype_str, " size=");
                    case specific_header(27 downto 24) is 
                        when "1001" =>
                            strcat( ftype_str, "  8 bytes ");
                        when "1010" =>
                            strcat( ftype_str, " 16 bytes ");
                        when "1011" =>
                            strcat( ftype_str, " 32 bytes ");
                        when "1100" =>
                            strcat( ftype_str, " 64 bytes ");
                        when "1101" =>
                            strcat( ftype_str, "128 bytes ");
                        when "1110" =>
                            strcat( ftype_str, "256 bytes ");
                        when others =>
                            strcat( ftype_str, "Reserved ");
                    end case;

                     
                    strcat( ftype_str, " letter=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(23 downto 22)) ) ) );
                    strcat( ftype_str, " mbox=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(21 downto 20)) ) ) );
                    strcat( ftype_str, " MsqSeq=");
                    strcat( ftype_str, str(to_integer(unsigned(specific_header(19 downto 16)) ) ) );
                                    
                when Others =>
                  strcat( ftype_str, "Reserved");
                  frame_type := SRIO_RESERVED;
                 
            end case;       
            print(" Type    : " & ftype_str );
            
            return frame_type;
        end function;
          function GetByteFromSrioFrame(aFrame: SRioFrame; byteIndex : integer) return std_logic_vector is
            variable word : std_logic_vector(31 downto 0);
            variable modulo : integer;
            variable result : std_logic_vector(7 downto 0);
            variable byte : integer;
        begin
            word := aFrame((byteIndex-1)/4  + 1);
            byte := ((byteIndex-1) mod 4);
            result := word(7 + 8*(3-byte) downto 8*(3-byte));
            
            return result;
            
        end;
        
        impure function CheckSrioFrame( aFrame: SRioFrame; address : unsigned; size : integer) return unsigned is
            variable frame_type : SrioFrameType;
            variable word_idx : integer;
            variable byte_idx : integer;
            variable data : std_logic_vector(31 downto 0);
            variable payload, expected_payload : std_logic_vector(31 downto 0);
            variable payload_idx : integer;
            variable payload_offset : unsigned(31 downto 0);
            variable crc_frame : std_logic_vector(15 downto 0);
            variable byte : std_logic_vector(7 downto 0);
            variable crc_computed : std_logic_vector(15 downto 0);
            -- At the beginning, we don't knwo the size of the header
            variable packet_header_byte_size : integer := 999;
            

        begin
            frame_type := DecodeSRIOFrame(aFrame, size);
            
            -- CRC is initialized
            crc_computed := x"FFFF";
            
            case ( frame_type) is
                when SRIO_MESSAGE =>
                
                    -- We start from the first byte containing the payload
                    byte_idx := 1;
                    word_idx := 3;
                    payload_idx := 3;
                    payload_offset := (others => '0');
                    --print("Size is " & str(size) );
                    while byte_idx < size*4  loop
                        byte := GetByteFromSrioFrame(aFrame, byte_idx);
                        --print("byte_idx is " & str(byte_idx) );
                        -- The first byte is the ackid, we replace it by 0 for CRC computation                       
                        if byte_idx = 1 then
                            data(7 + 8*word_idx downto 8*word_idx) := "000000" & byte( 1 downto 0);
                            word_idx := word_idx - 1;
                        else
                            data(7 + 8*word_idx downto 8*word_idx) := byte;
                            word_idx := word_idx - 1;
                        end if; 

                        -- In the second byte, we have the size of the identifier giving us the size of the packet header
                        if byte_idx = 2 then
                            if byte(5 downto 4) = "01" then
                                packet_header_byte_size := 8;
                                print("Checking SRIO MESSAGE with long id");
                            else
                                packet_header_byte_size := 6;
                                print("Checking SRIO MESSAGE with short id");
                            end if;
                        end if;

                        
                        
                        --if byte_idx >= 7 and (byte_idx /= 81) and (byte_idx /= 82) and (byte_idx /= size*4 -1) then
                        if byte_idx >=  (packet_header_byte_size +1) and (byte_idx /= 81) and (byte_idx /= 82)  then
                            --print("byte_idx=" & str(byte_idx) );
                            --print("byte    =" & hstr(byte) );
                            payload(7 + 8*payload_idx downto 8*payload_idx) := byte;
                            payload_idx := payload_idx - 1;
                            if payload_idx = -1 then
                                
                                -- Compute the value we are supposed to find for this address
                                expected_payload := GetPatternFromAddr(std_logic_vector(address), payload_offset);
                                if expected_payload = payload then
                                    --print("Word OK : 0x" & hstr(payload) );
                                else
                                    print("Word ERROR : Found 0x" & hstr(payload) & " instead 0x" & hstr(expected_payload));
                                end if;
                                payload_idx := 3;
                                payload_offset := payload_offset + 4;
                            end if;
                        end if;
                        
                        -- In addition to retrieving the complete word, if it's then
                        -- intermediary checksum, we retrieve it and validate it
                        if byte_idx = 81 then
                            crc_frame(15 downto 8) := byte;
                        elsif byte_idx = 82 then
                            crc_frame(7 downto 0) := byte;
                            print("CRC : 0x" & hstr(crc_frame) );
                            
                            -- Check if the intermediary CRC match the computed one
                            if crc_computed = crc_frame then
                                print("OK    : CRC intermediary validated 0x" & hstr(crc_computed) );
                            else
                                print("ERROR : CRC intermediary doesn't match 0x" & hstr(crc_computed) & " /= " &   hstr(crc_frame) );
                            end if;
                        end if;
                        
                        -- Are we at the end of the frame
                        if byte_idx = size*4 -3 then
                            -- If the frame is below 80 bytes for a message, as it's only multiple of double word, 
                            --  the CRC is the last word
                            if size*4 <= 84 then
                                
                                -- Short Header we are aligned, the csum is at the end 
                                if packet_header_byte_size = 6 then 
                                    crc_frame(15 downto 8) := GetByteFromSrioFrame(aFrame, byte_idx + 2);
                                    crc_frame( 7 downto 0) := GetByteFromSrioFrame(aFrame, byte_idx + 3);

                                    -- We need to add the half word preceding the checksum to the current csum as it's
                                    --  data
                                    data(31 downto 24) :=  GetByteFromSrioFrame(aFrame, byte_idx + 0);
                                    data(23 downto 16) :=  GetByteFromSrioFrame(aFrame, byte_idx + 1);
                                    crc_computed := Crc16( data(31 downto 16), crc_computed);

                                -- Long Header we are not aligned, the csum is before padding
                                else
                                    crc_frame(15 downto 8) := GetByteFromSrioFrame(aFrame, byte_idx );
                                    crc_frame( 7 downto 0) := GetByteFromSrioFrame(aFrame, byte_idx + 1);
                                    if GetByteFromSrioFrame(aFrame, byte_idx + 2) /= x"00" and 
                                            GetByteFromSrioFrame(aFrame, byte_idx + 3) /= x"00" then
                                        print("ERROR : No padding as expected" );
                                    end if;


                                end if;
 
                            else
                                -- Long Header we are aligned, the csum is at the end 
                                if packet_header_byte_size = 8 then 
                                    crc_frame(15 downto 8) := GetByteFromSrioFrame(aFrame, byte_idx + 2);
                                    crc_frame( 7 downto 0) := GetByteFromSrioFrame(aFrame, byte_idx + 3);

                                    -- We need to add the half word preceding the checksum to the current csum as it's
                                    --  data
                                    data(31 downto 24) :=  GetByteFromSrioFrame(aFrame, byte_idx + 0);
                                    data(23 downto 16) :=  GetByteFromSrioFrame(aFrame, byte_idx + 1);
                                    crc_computed := Crc16( data(31 downto 16), crc_computed);

                                -- Short Header we are not aligned, the csum is before padding
                                else
                                    crc_frame(15 downto 8) := GetByteFromSrioFrame(aFrame, byte_idx);
                                    crc_frame( 7 downto 0) := GetByteFromSrioFrame(aFrame, byte_idx + 1);  
                                    if GetByteFromSrioFrame(aFrame, byte_idx + 2) /= x"00" and 
                                    GetByteFromSrioFrame(aFrame, byte_idx + 3) /= x"00" then
                                        print("ERROR : No padding as expected" );
                                    end if;
                                end if;
                            end if;
                            
                            if crc_computed = crc_frame then
                                print("OK    : Final CRC validated 0x" & hstr(crc_computed) );
                            else 
                                print("ERROR : Final CRC doesn't match 0x" & hstr(crc_computed) & " /= " &   hstr(crc_frame) );
                            end if;    
                                                       
                        end if;
                        
                        -- Do we have a complete word
                        if word_idx = -1 then
                            word_idx := 3;
                            --print("Word : 0x" & hstr(data) );
                            
                            -- Update the CRC with the new word
                            crc_computed := Crc16( data(31 downto 16), crc_computed);
                            --print("CRC : 0x" & hstr(crc_computed) );
                            crc_computed := Crc16( data(15 downto 0) , crc_computed);
                            --print("CRC : 0x" & hstr(crc_computed) );

                        end if;
                       
                       byte_idx := byte_idx + 1;
                    end loop;
                when others =>
                    null;
            end case;
    
            return payload_offset;
                    
                    
        end function;    
        
        variable aMessageShort_00_00, aMessageShort_00_01, aMessageShort_01_01 : RioPayload;
        variable aMessageShort_00_02 : RioPayload;
        variable aMessageLong_00_00, aMessageLong_00_01, aMessageLong_01_01 : RioPayload;
        variable aFrame : RioFrame;
        variable payload : WordArray(0 to 67);
        variable seed1: positive:=10;
        variable seed2: positive:=15;
        
        variable data_tb : memory_tb_t(0 to 1024);
        file data_file : text;
        variable written : integer;
        variable ivect : integer;
        variable success : boolean;
        variable maint_addr : std_logic_vector(31 downto 0);
        
	begin
        -- Generate a startup reset pulse.
        wait until rising_edge(clk);
        rst_n <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst_n <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        report "Resetting done";
        readcontent_i <= '0';
        
        -- Waiting for the clocks being stable
        wait for 7 us;
        -- Default initialization of the bus values
        AxiLITEMasterInit(clk, master2slaveLite);
        
        -- Read the identification register
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"FFFF0000", data );
        
        -- Do we have read GOOD_SIO in hexspeak
        result := CheckResult("Identification register", x"600D0510", data, hstr(data)); 
        
        -- Reading invalid address register
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000F0", data );
        result := CheckResult("Non-existent register", x"BADACCE5", data, hstr(data)); 
        
        -- Set source and destination IDs
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"00000014", x"DEADBEEF");

        -- Read a maintenance packet targetting the switch
        ---            Hop-Count _ Config-offset 21bits _ w _ 00 
        -- Read Device identity CAR
        maint_addr := "00000000" & "00000" & x"0000"    & "0" & "00";
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A0", maint_addr);
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000A4", data );
        result := CheckResult("Checking the Switch Device Identity Register", x"5A11DAAA", data, hstr(data)); 

        -- Read a maintenance packet targetting an invalid address
        ---            Hop-Count _ Config-offset 21bits _ w _ 00 
        -- Read Device identity CAR, we must have a failure
        maint_addr := "00000111" & "00000" & x"0000"    & "0" & "00";
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A0", maint_addr);
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000A4", data );
        result := CheckResult("Checking we have an invalid access when hop doesn't reach a valid switch", x"BADACCE5", data, hstr(data)); 

        -- Checking if we have an error, when we try to write to an invalid hop
        report "Checking we have a bus error access when hop doesn't reach a valid switch";
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A0", maint_addr);
        maint_addr := "00000111" & "00000000" & x"0068";
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A4", x"00000002" );

        -- Try to lock the switch
        maint_addr := "00000000" & "00000000" & x"0068";
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A0", maint_addr);


        -- Read the content of the lock
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000A4", data );
        result := CheckResult("Lock register is not held", x"0000FFFF", data, hstr(data)); 

        -- then try to lock
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A4", x"00000002" );
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000A4", data );
        result := CheckResult("Checking the lock is held by us", x"00000002", data, hstr(data)); 

        -- then release the lock
        AxiLITEMasterWrite( clk, master2slaveLite, slave2masterLite, x"000000A4", x"00000002" );
        AxiLITEMasterRead( clk, master2slaveLite, slave2masterLite, x"000000A4", data );
        result := CheckResult("Checking the lock is not held by anyone", x"0000FFFF", data, hstr(data)); 
        wait; -- will wait forever
		
	end process;
    
 	-- -----------------------------------------------------------------------------
	-- -- AXI Slave burst read bus simulation 
	-- -----------------------------------------------------------------------------  
   slave_read: process
    begin
        Axi4SlaveReadInit(clk, slave2master );
        loop
            Axi4SlaveAcceptAnyRead( clk, master2slave, slave2master, PATTERN_RANDOM );
        end loop;
    end process;
    
 	-- -----------------------------------------------------------------------------
	-- -- AXI Slave burst write bus simulation 
	-- -----------------------------------------------------------------------------  
    slave_write: process
     begin
        Axi4SlaveWriteInit(clk, slave2master );
         loop
             Axi4SlaveAcceptAnyWrite( clk, master2slave, slave2master );
         end loop;
     end process; 
end Behavioral;
