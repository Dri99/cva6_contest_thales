// Copyright 2021 Thales DIS design services SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Guillaume Chauvon (guillaume.chauvon@thalesgroup.com)

package cvxif_mac4b_instr_pkg;

  typedef struct packed {
    logic [31:0]                          instr;
    logic [31:0]                          mask;
    logic [cvxif_pkg::X_NUM_RS-1:0]       rs_valid;
    cvxif_pkg::x_issue_resp_t             resp;
  } copro_issue_resp_t;

  // 1 Possible RISCV instructions for Coprocessor (MAC4B)
  parameter int unsigned NbInstr = 1;
  parameter copro_issue_resp_t CoproInstr[NbInstr] = '{
      '{
          instr: 32'b00000_11_00000_00000_0_00_00000_0110011,  // MAC4B opcode
          mask: 32'b00000_11_00000_00000_1_11_00000_1111111,
          rs_valid: '1,                                        // All operands required 
          resp : '{
              accept : 1'b1,
              writeback : 1'b1,
              dualwrite : 1'b0,
              dualread : 1'b0,
              loadstore : 1'b0,
              exc : 1'b0
          }
      }
  };

endpackage
