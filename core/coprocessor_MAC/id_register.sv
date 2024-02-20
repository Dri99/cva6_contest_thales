//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.02.2024 14:00:00
// Design Name: 
// Module Name: id_register
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Register for DATA and RD associated to a specific ID
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module id_register 
  import cvxif_pkg::*;
(
	input  logic					clk_i,
	input  logic					rst_ni,

	input  logic 					load_i,

	input  logic [X_ID_WIDTH-1:0] 	id_in_i,
	input  logic [31:0] 			data_i,
	input  logic [4:0] 				rd_i,
	
	input  logic [X_ID_WIDTH-1:0] 	id_out_i,
	output logic [31:0] 			data_o,
	output logic [4:0] 				rd_o
);

	logic [X_ID_WIDTH-1:0][31:0] data_mem;
	logic [X_ID_WIDTH-1:0][4:0] rd_mem;

	// On clock REdge: store the data and the rd address
	always_ff @(posedge clk_i or negedge rst_ni) begin : register_input
		if (!rst_ni) begin 
			data_mem 	<= '0;
			rd_mem 		<= '0;
		end else begin
			if (load_i) begin
				data_mem[id_in_i] = data_i;
				rd_mem[id_in_i] = rd_i;
			end
		end
	end

	// Return the data and rd address associated to id_out
	always_comb begin : register_output
		data_o 	= data_mem[id_out_i];
		rd_o 	= rd_mem[id_out_i]; 
	end

endmodule
