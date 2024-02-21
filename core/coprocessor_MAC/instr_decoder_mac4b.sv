// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon (guillaume.chauvon@thalesgroup.com)

module instr_decoder_mac4b
  import cvxif_pkg::*;
#(
    parameter int                                       NbInstr             = 1,
    parameter cvxif_mac4b_instr_pkg::copro_issue_resp_t CoproInstr[NbInstr] = {0}
) (
    input  logic          clk_i,
    input  x_issue_req_t  x_issue_req_i,
    output logic [4:0]    rd_o,
    output x_issue_resp_t x_issue_resp_o
);

  logic [NbInstr-1:0] sel;

  for (genvar i = 0; i < NbInstr; i++) begin : gen_predecoder_selector
    assign sel[i] = ((CoproInstr[i].mask & x_issue_req_i.instr) == CoproInstr[i].instr) && (CoproInstr[i].rs_valid == x_issue_req_i.rs_valid);
  end

  always_comb begin
    x_issue_resp_o.accept    = '0;
    x_issue_resp_o.writeback = '0;
    x_issue_resp_o.dualwrite = '0;
    x_issue_resp_o.dualread  = '0;
    x_issue_resp_o.loadstore = '0;
    x_issue_resp_o.exc       = '0;
    rd_o                     = '0;
    for (int unsigned i = 0; i < NbInstr; i++) begin
      if (sel[i]) begin
        x_issue_resp_o.accept    = CoproInstr[i].resp.accept;
        x_issue_resp_o.writeback = CoproInstr[i].resp.writeback;
        x_issue_resp_o.dualwrite = CoproInstr[i].resp.dualwrite;
        x_issue_resp_o.dualread  = CoproInstr[i].resp.dualread;
        x_issue_resp_o.loadstore = CoproInstr[i].resp.loadstore;
        x_issue_resp_o.exc       = CoproInstr[i].resp.exc;
        rd_o[4:0]                = CoproInstr[i].instr[11:7];       // Retrieve destination register address
      end
    end
  end

  assert property (@(posedge clk_i) $onehot0(sel))
  else $warning("This offloaded instruction is valid for multiple coprocessor instructions !");

endmodule
