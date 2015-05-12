module etx(/*AUTOARG*/
   // Outputs
   txo_lclk_p, txo_lclk_n, txo_frame_p, txo_frame_n, txo_data_p,
   txo_data_n, txrd_wait, txwr_wait, txrr_wait, etx_cfg_access,
   etx_cfg_packet,
   // Inputs
   reset, sys_clk, tx_lclk, tx_lclk90, tx_lclk_div4, txi_wr_wait_p,
   txi_wr_wait_n, txi_rd_wait_p, txi_rd_wait_n, txrd_access,
   txrd_packet, txwr_access, txwr_packet, txrr_access, txrr_packet,
   etx_cfg_wait
   );
   parameter AW      = 32;
   parameter DW      = 32;
   parameter PW      = 104;
   parameter RFAW    = 6;
   parameter ID      = 12'h000;
   
   //Clocks,reset,config
   input          reset;
   input 	  sys_clk;   
   input 	  tx_lclk;	  // high speed serdes clock
   input 	  tx_lclk90;	  // lclk for output
   input 	  tx_lclk_div4;	  // slow speed parallel clock
   
   //Transmit signals for IO
   output 	  txo_lclk_p, txo_lclk_n;       //tx center aligned clock (>500MHz)
   output 	  txo_frame_p, txo_frame_n;     //tx frame signal
   output [7:0]   txo_data_p, txo_data_n;       //tx data (dual data rate)
   input 	  txi_wr_wait_p,txi_wr_wait_n;  //tx async write pushback
   input 	  txi_rd_wait_p, txi_rd_wait_n; //tx async read pushback

      
   //Read Request Channel Input
   input 	  txrd_access;
   input [PW-1:0] txrd_packet;
   output 	  txrd_wait;
   
   //Write Channel Input
   input 	  txwr_access;
   input [PW-1:0] txwr_packet;
   output 	  txwr_wait;
   
   //Read Response Channel Input
   input 	  txrr_access;
   input [PW-1:0] txrr_packet;
   output 	  txrr_wait;

   //Configuration Interface (for ERX)
   output 	   etx_cfg_access;
   output [PW-1:0] etx_cfg_packet;
   input 	   etx_cfg_wait;
      
 
   //for status?
   wire[15:0] 	  tx_status; 
   wire 	  txwr_fifo_full;
   wire 	  txrr_fifo_full;
   wire 	  txrd_fifo_full;
   wire 	  txrd_fifo_empty;
   wire 	  txrr_fifo_empty;
   wire 	  txwr_fifo_empty;
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/
     
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [63:0]		tx_data_par;		// From etx_core of etx_core.v
   wire [7:0]		tx_frame_par;		// From etx_core of etx_core.v
   wire			tx_rd_wait;		// From etx_io of etx_io.v
   wire			tx_wr_wait;		// From etx_io of etx_io.v
   wire			txrd_fifo_access;	// From etx_fifo of etx_fifo.v
   wire [PW-1:0]	txrd_fifo_packet;	// From etx_fifo of etx_fifo.v
   wire			txrd_fifo_wait;		// From etx_core of etx_core.v
   wire			txrr_fifo_access;	// From etx_fifo of etx_fifo.v
   wire [PW-1:0]	txrr_fifo_packet;	// From etx_fifo of etx_fifo.v
   wire			txrr_fifo_wait;		// From etx_core of etx_core.v
   wire			txwr_fifo_access;	// From etx_fifo of etx_fifo.v
   wire [PW-1:0]	txwr_fifo_packet;	// From etx_fifo of etx_fifo.v
   wire			txwr_fifo_wait;		// From etx_core of etx_core.v
   // End of automatics
   wire [15:0] 		ecfg_status;		// To ecfg_tx of ecfg_tx.v
   
   /************************************************************/
   /*FIFOs                                                     */
   /************************************************************/
   etx_fifo etx_fifo (/*AUTOINST*/
		      // Outputs
		      .txrd_wait	(txrd_wait),
		      .txwr_wait	(txwr_wait),
		      .txrr_wait	(txrr_wait),
		      .etx_cfg_access	(etx_cfg_access),
		      .etx_cfg_packet	(etx_cfg_packet[PW-1:0]),
		      .txrd_fifo_access	(txrd_fifo_access),
		      .txrd_fifo_packet	(txrd_fifo_packet[PW-1:0]),
		      .txrr_fifo_access	(txrr_fifo_access),
		      .txrr_fifo_packet	(txrr_fifo_packet[PW-1:0]),
		      .txwr_fifo_access	(txwr_fifo_access),
		      .txwr_fifo_packet	(txwr_fifo_packet[PW-1:0]),
		      // Inputs
		      .reset		(reset),
		      .sys_clk		(sys_clk),
		      .tx_lclk_div4	(tx_lclk_div4),
		      .txrd_access	(txrd_access),
		      .txrd_packet	(txrd_packet[PW-1:0]),
		      .txwr_access	(txwr_access),
		      .txwr_packet	(txwr_packet[PW-1:0]),
		      .txrr_access	(txrr_access),
		      .txrr_packet	(txrr_packet[PW-1:0]),
		      .etx_cfg_wait	(etx_cfg_wait),
		      .txrd_fifo_wait	(txrd_fifo_wait),
		      .txrr_fifo_wait	(txrr_fifo_wait),
		      .txwr_fifo_wait	(txwr_fifo_wait));

   /***********************************************************/
   /*ELINK CORE LOGIC                                         */
   /***********************************************************/
   /*etx_core   AUTO_TEMPLATE ( 
                                .etx_cfg_access	(etx_cfg_access),
		                .etx_cfg_packet	(etx_cfg_packet[PW-1:0]),
                                .etx_cfg_wait	(etx_cfg_wait),
                                .tx_rd_wait	(tx_rd_wait),
		                .tx_wr_wait	(tx_wr_wait),
    			       .\(.*\)_packet   (\1_fifo_packet[PW-1:0]),
    			       .\(.*\)_access   (\1_fifo_access),
       			       .\(.*\)_wait     (\1_fifo_wait),
    );
    */
   
   defparam etx_core.ID=ID;   
   etx_core etx_core (.clk		(tx_lclk_div4),
		      /*AUTOINST*/
		      // Outputs
		      .tx_data_par	(tx_data_par[63:0]),
		      .tx_frame_par	(tx_frame_par[7:0]),
		      .txrd_wait	(txrd_fifo_wait),	 // Templated
		      .txrr_wait	(txrr_fifo_wait),	 // Templated
		      .txwr_wait	(txwr_fifo_wait),	 // Templated
		      .etx_cfg_access	(etx_cfg_access),	 // Templated
		      .etx_cfg_packet	(etx_cfg_packet[PW-1:0]), // Templated
		      // Inputs
		      .reset		(reset),
		      .tx_rd_wait	(tx_rd_wait),		 // Templated
		      .tx_wr_wait	(tx_wr_wait),		 // Templated
		      .txrd_access	(txrd_fifo_access),	 // Templated
		      .txrd_packet	(txrd_fifo_packet[PW-1:0]), // Templated
		      .txrr_access	(txrr_fifo_access),	 // Templated
		      .txrr_packet	(txrr_fifo_packet[PW-1:0]), // Templated
		      .txwr_access	(txwr_fifo_access),	 // Templated
		      .txwr_packet	(txwr_fifo_packet[PW-1:0]), // Templated
		      .etx_cfg_wait	(etx_cfg_wait));		 // Templated
   
   
   /***********************************************************/
   /*TRANSMIT I/O LOGIC                                       */
   /***********************************************************/

   etx_io etx_io (
		    /*AUTOINST*/
		  // Outputs
		  .txo_lclk_p		(txo_lclk_p),
		  .txo_lclk_n		(txo_lclk_n),
		  .txo_frame_p		(txo_frame_p),
		  .txo_frame_n		(txo_frame_n),
		  .txo_data_p		(txo_data_p[7:0]),
		  .txo_data_n		(txo_data_n[7:0]),
		  .tx_wr_wait		(tx_wr_wait),
		  .tx_rd_wait		(tx_rd_wait),
		  // Inputs
		  .reset		(reset),
		  .txi_wr_wait_p	(txi_wr_wait_p),
		  .txi_wr_wait_n	(txi_wr_wait_n),
		  .txi_rd_wait_p	(txi_rd_wait_p),
		  .txi_rd_wait_n	(txi_rd_wait_n),
		  .tx_lclk_div4		(tx_lclk_div4),
		  .tx_lclk		(tx_lclk),
		  .tx_lclk90		(tx_lclk90),
		  .tx_frame_par		(tx_frame_par[7:0]),
		  .tx_data_par		(tx_data_par[63:0]));
   
   
endmodule // elink
// Local Variables:
// verilog-library-directories:("." "../../emmu/hdl" "../../memory/hdl" "../../edma/hdl/")
// End:


/*
 Copyright (C) 2015 Adapteva, Inc.
 
 Contributed by Andreas Olofsson <andreas@adapteva.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.This program is distributed in the hope 
 that it will be useful,but WITHOUT ANY WARRANTY; without even the implied 
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details. You should have received a copy 
 of the GNU General Public License along with this program (see the file 
 COPYING).  If not, see <http://www.gnu.org/licenses/>.
 */
