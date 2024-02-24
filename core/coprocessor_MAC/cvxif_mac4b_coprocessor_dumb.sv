// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon (guillaume.chauvon@thalesgroup.com)
// Example coprocessor adds rs1,rs2(,rs3) together and gives back the result to the CPU via the CoreV-X-Interface.
// Coprocessor delays the sending of the result depending on result least significant bits.

module cvxif_mac4b_coprocessor
  import cvxif_pkg::*;
  import cvxif_mac4b_instr_pkg::*;
(
    input  logic        clk_i,        // Clock
    input  logic        rst_ni,       // Asynchronous reset active low
    input  cvxif_req_t  cvxif_req_i,
    output cvxif_resp_t cvxif_resp_o
);

  //Compressed interface
  logic               x_compressed_valid_i;
  logic               x_compressed_ready_o;
  x_compressed_req_t  x_compressed_req_i;
  x_compressed_resp_t x_compressed_resp_o;
  //Issue interface
  logic               x_issue_valid_i;
  logic               x_issue_ready_o;
  x_issue_req_t       x_issue_req_i;
  x_issue_resp_t      x_issue_resp_o;
  //Commit interface
  logic               x_commit_valid_i;
  x_commit_t          x_commit_i;
  //Memory interface
  logic               x_mem_valid_o;
  logic               x_mem_ready_i;
  x_mem_req_t         x_mem_req_o;
  x_mem_resp_t        x_mem_resp_i;
  //Memory result interface
  logic               x_mem_result_valid_i;
  x_mem_result_t      x_mem_result_i;
  //Result interface
  logic               x_result_valid_o;
  logic               x_result_ready_i;
  x_result_t          x_result_o;

  //RD address signals
  logic [4:0]         rd;

  //Data signals
  logic [31:0]        rs1;
  logic [31:0]        rs2;
  logic [31:0]        mac_sum;


  assign x_compressed_valid_i            = cvxif_req_i.x_compressed_valid;
  assign x_compressed_req_i              = cvxif_req_i.x_compressed_req;
  assign x_issue_valid_i                 = cvxif_req_i.x_issue_valid;
  assign x_issue_req_i                   = cvxif_req_i.x_issue_req;
  assign x_commit_valid_i                = cvxif_req_i.x_commit_valid;
  assign x_commit_i                      = cvxif_req_i.x_commit;
  assign x_mem_ready_i                   = cvxif_req_i.x_mem_ready;
  assign x_mem_resp_i                    = cvxif_req_i.x_mem_resp;
  assign x_mem_result_valid_i            = cvxif_req_i.x_mem_result_valid;
  assign x_mem_result_i                  = cvxif_req_i.x_mem_result;
  assign x_result_ready_i                = cvxif_req_i.x_result_ready;

  assign cvxif_resp_o.x_compressed_ready = x_compressed_ready_o;
  assign cvxif_resp_o.x_compressed_resp  = x_compressed_resp_o;
  assign cvxif_resp_o.x_issue_ready      = x_issue_ready_o;
  assign cvxif_resp_o.x_issue_resp       = x_issue_resp_o;
  assign cvxif_resp_o.x_mem_valid        = x_mem_valid_o;
  assign cvxif_resp_o.x_mem_req          = x_mem_req_o;
  assign cvxif_resp_o.x_result_valid     = x_result_valid_o;
  assign cvxif_resp_o.x_result           = x_result_o;

  //Compressed interface (Not implemented in CVA6 according to documentation + we don't need it)
  assign x_compressed_ready_o            = '0;
  assign x_compressed_resp_o             = '0;

  //Memory / Memory result interface (not implemented)
  assign x_mem_valid_o                   = '0;
  assign x_mem_req_o                     = '0;

  instr_decoder_mac4b #(
      .NbInstr   (cvxif_mac4b_instr_pkg::NbInstr),
      .CoproInstr(cvxif_mac4b_instr_pkg::CoproInstr)
  ) instr_decoder_i (
      .clk_i         (clk_i),
      .x_issue_req_i (x_issue_req_i),
      .rd_o          (rd),
      .x_issue_resp_o(x_issue_resp_o)
  );


  // Get RS values, assign them as MAC4B inputs
  assign rs1 = x_issue_req_i.rs[0];     // First operand are the INPUTS
  assign rs2 = x_issue_req_i.rs[1];     // Second operand are the WEIGHTS
  mac4b mac_init 
  (
      .in_0     (rs1[7:0]),
      .in_1     (rs1[15:8]),
      .in_2     (rs1[23:16]),
      .in_3     (rs1[31:24]),
      .weight_0 (rs2[7:0]),
      .weight_1 (rs2[15:8]),
      .weight_2 (rs2[23:16]),
      .weight_3 (rs2[31:24]),
      .sum_out  (mac_sum)
  );

  always_comb begin
    // Issue interface
    x_issue_ready_o      = 1;

    // Commit interface (nothing to do since there is no output signal)
  
    // Result interface
    x_result_valid_o   = x_issue_resp_o.accept;
    x_result_o.id      = x_issue_req_i.id;
    x_result_o.data    = mac_sum;
    x_result_o.rd      = rd;
    x_result_o.we      = 1;
    x_result_o.exc     = 0;
    x_result_o.exccode = 0;
  end

  // always_ff @(posedge clk_i or negedge rst_ni) begin
	// 	if (!rst_ni) begin 
	// 		x_result_valid_o   <= 0;
  //     x_result_o.id      <= '0;
  //     x_result_o.data    <= '0;
  //     x_result_o.rd      <= '0;
  //     x_result_o.we      <= '0;
  //     x_result_o.exc     <= '0;
  //     x_result_o.exccode <= '0;
	// 	end else begin
	// 		if (x_issue_resp_o.accept) begin
  //       x_result_valid_o   <= '1;
  //       x_result_o.id      <= x_issue_req_i.id;
  //       x_result_o.data    <= mac_sum;
  //       x_result_o.rd      <= rd;
  //       x_result_o.we      <= '1;
  //       x_result_o.exc     <= '0;
  //       x_result_o.exccode <= '0;
  //     end else begin
  //       x_result_valid_o   <= '0;
  //       x_result_o.id      <= '0;
  //       x_result_o.data    <= '0;
  //       x_result_o.rd      <= '0;
  //       x_result_o.we      <= '0;
  //       x_result_o.exc     <= '0;
  //       x_result_o.exccode <= '0;
  //     end
	// 	end
	// end

endmodule
