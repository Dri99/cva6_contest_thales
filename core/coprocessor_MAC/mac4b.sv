`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.02.2024 20:47:49
// Design Name: 
// Module Name: mac_8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mac4b(
    input unsigned [7:0] in_0,
    input unsigned [7:0] in_1,
    input unsigned [7:0] in_2,
    input unsigned [7:0] in_3,
    input signed [7:0] weight_0,
    input signed [7:0] weight_1,
    input signed [7:0] weight_2,
    input signed [7:0] weight_3,
    input signed [31:0] sum_in,
    output signed [31:0] sum_out
    );
    
    // addiplier & Additions results declaration
    logic signed [15:0] res_mult_0;
    logic signed [15:0] res_mult_1;
    logic signed [15:0] res_mult_2;
    logic signed [15:0] res_mult_3;
    
    logic signed [16:0] res_add_0;
    logic signed [16:0] res_add_1;
    logic signed [17:0] res_add_2;
    
        
    // Multiplications
    assign res_mult_0 = in_0 * weight_0;
    assign res_mult_1 = in_1 * weight_1;
    assign res_mult_2 = in_2 * weight_2;
    assign res_mult_3 = in_3 * weight_3;
    
    // Additions
    assign res_add_0 = res_mult_0 + res_mult_1;
    assign res_add_1 = res_mult_2 + res_mult_3;
    
    assign res_add_2 = res_add_0 + res_add_1;
    
    // Accumulator
    assign sum_out = res_add_2 + sum_in;

endmodule
