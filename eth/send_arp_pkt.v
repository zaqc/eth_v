module send_arp_pkt(
	input						rst_n,
	input						clk,
	
	output						o_ready,
	input						i_sync,
	
	input		[47:0]			i_dst_mac,
	input		[47:0]			i_src_mac,

	input		[15:0]			i_arp_opcode,

	input		[47:0]			i_arp_sha,
	input		[31:0]			i_arp_spa,
	input		[47:0]			i_arp_tha,
	input		[31:0]			i_arp_tpa,

	output						o_eth_sop,
	output						o_eth_eop,
	output						o_eth_vld,
	output		[31:0]			o_eth_data,
	input						i_eth_rdy
);

	reg			[47:0]			dst_mac;
	reg			[47:0]			src_mac;
	reg			[15:0]			arp_pkt_type;
	reg			[31:0]			hdr1;
	reg			[31:0]			hdr2;
	reg			[15:0]			opcode;
	
	reg			[47:0]			sha;
	reg			[31:0]			spa;
	reg			[47:0]			tha;
	reg			[31:0]			tpa;
	
	reg			[0:0]			prev_sync;
	always @ (posedge clk) prev_sync <= i_sync;
	
	reg			[3:0]			s_step;
	
	assign o_ready = s_step == SS_NONE ? 1'b1 : 1'b0;
	
	parameter	[3:0]			SS_NONE = 4'd0,
								SS_START = 4'd1,
								SS_STEP_0 = 4'd2,
								SS_STEP_1 = 4'd3,
								SS_STEP_2 = 4'd4,
								SS_STEP_3 = 4'd5,
								SS_STEP_4 = 4'd6,
								SS_STEP_5 = 4'd7,
								SS_STEP_6 = 4'd8,
								SS_STEP_7 = 4'd9,
								SS_STEP_8 = 4'd10,
								SS_STEP_9 = 4'd11,
								SS_STEP_A = 4'd12,
								SS_STEP_B = 4'd13;
	
	wire		[3:0]			next_step;
	reg			[4:0]			dummy_cnt;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			s_step <= SS_NONE;
		else
			if(i_sync & ~prev_sync) begin
				s_step <= SS_START;
				
				dst_mac <= i_dst_mac;
				src_mac <= i_src_mac;
				arp_pkt_type <= 16'h0806;
				hdr1 <= {16'h0001, 16'h0800};
				hdr2 <= {8'h6, 8'h4, i_arp_opcode};
				sha <= i_arp_sha;
				spa <= i_arp_spa;
				tha <= i_arp_tha;
				tpa <= i_arp_tpa;
				dummy_cnt <= 5'd0;
			end
			else begin
				s_step <= i_eth_rdy ? next_step : s_step;
				dummy_cnt <= i_eth_rdy & ~&{dummy_cnt} && s_step == SS_STEP_B ? dummy_cnt + 1'd1 : dummy_cnt;
			end
				
	assign {next_step, o_eth_sop, o_eth_eop, o_eth_data, o_eth_vld} =
		s_step == SS_NONE ? 	{SS_NONE, 1'b0, 1'b0, 32'dX, 1'b0} :
		s_step == SS_START ?	{SS_STEP_1, 1'b1, 1'b0, 16'd0, dst_mac[47:32], 1'b1} :
		s_step == SS_STEP_1 ?	{SS_STEP_2, 1'b0, 1'b0, dst_mac[31:0], 1'b1} :
		s_step == SS_STEP_2 ?	{SS_STEP_3, 1'b0, 1'b0, src_mac[47:16], 1'b1} :
		s_step == SS_STEP_3 ?	{SS_STEP_4, 1'b0, 1'b0, src_mac[15:0], arp_pkt_type, 1'b1} :
		s_step == SS_STEP_4 ?	{SS_STEP_5, 1'b0, 1'b0, hdr1[31:0], 1'b1} :
		s_step == SS_STEP_5 ?	{SS_STEP_6, 1'b0, 1'b0, hdr2[31:0], 1'b1} :
		s_step == SS_STEP_6 ?	{SS_STEP_7, 1'b0, 1'b0, sha[47:16], 1'b1} :
		s_step == SS_STEP_7 ?	{SS_STEP_8, 1'b0, 1'b0, sha[15:0], spa[31:16], 1'b1} :
		s_step == SS_STEP_8 ?	{SS_STEP_9, 1'b0, 1'b0, spa[15:0], tha[47:32], 1'b1} :
		s_step == SS_STEP_9 ?	{SS_STEP_A, 1'b0, 1'b0, tha[31:0], 1'b1} :
		s_step == SS_STEP_A ?	{SS_NONE, 1'b0, 1'b1, tpa[31:0], 1'b1} :	//{SS_STEP_B, 1'b0, 1'b0, tpa[31:0], 1'b1} :
		//s_step == SS_STEP_B ?	&{dummy_cnt} ? {SS_NONE, 1'b0, 1'b1, 32'd0, 1'b1} : {SS_STEP_B, 1'b0, 1'b0, 32'd0, 1'b1} :
								{SS_NONE, 1'b0, 1'b0, 32'dX, 1'b0};
								
endmodule
