module cmd_parser(
	input						rst_n,
	input						clk,
	
	input		[15:0]			i_cmd_addr,
	input		[31:0]			i_cmd_data,
	input						i_cmd_wren,
	
	output		[7:0]			o_vrc_addr_0,
	output		[7:0]			o_vrc_data_0,
	output						o_vrc_wren_0,
	
	output		[7:0]			o_vrc_addr_1,
	output		[7:0]			o_vrc_data_1,
	output						o_vrc_wren_1
);
	
	wire						wren;
	rise_detector rise_wren(.rst_n(rst_n), .clk(clk), .i_signal(i_cmd_wren), .o_rise(wren));

	wire						vrc_0;
	assign vrc_0 = ~i_cmd_addr[9] & i_cmd_addr[8] ? 1'b1 : 1'b0;
	
	wire						vrc_1;
	assign vrc_1 = i_cmd_addr[9] & ~i_cmd_addr[8] ? 1'b1 : 1'b0;
	
	assign o_vrc_addr_0 = vrc_0 ? i_cmd_addr[7:0] : 8'hXX;
	assign o_vrc_data_0 = vrc_0 ? i_cmd_data[7:0] : 8'hXX;
	assign o_vrc_wren_0 = vrc_0 ? wren : 1'b0;

	assign o_vrc_addr_1 = vrc_1 ? i_cmd_addr[7:0] : 8'hXX;
	assign o_vrc_data_1 = vrc_1 ? i_cmd_data[7:0] : 8'hXX;
	assign o_vrc_wren_1 = vrc_1 ? wren : 1'b0;
		
	wire						cmd;
	assign cmd = i_cmd_addr[9] & i_cmd_addr[8] ? 1'b1 : 1'b0;
	
	wire						ch_cmd_0;
	assign ch_cmd_0 = cmd & ~i_cmd_addr[0] ? 1'b1 : 1'b0;
	
	wire						ch_cmd_1;
	assign ch_cmd_1 = cmd & i_cmd_addr[0] ? 1'b1 : 1'b0;
	
endmodule
