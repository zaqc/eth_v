module rise_detector(
	input						rst_n,
	input						clk,
	
	input						i_signal,
	output						o_rise
);
	reg			[0:0]			prev_signal;
	always @ (posedge clk or negedge rst_n) prev_signal <= ~rst_n ? 1'b0 : i_signal;
	assign o_rise = ~prev_signal & i_signal ? 1'b1 : 1'b0;
endmodule
