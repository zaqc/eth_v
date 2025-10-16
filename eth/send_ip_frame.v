module send_ip_frame(
	input						rst_n,
	input						clk,
	
	input						i_sync,
	output						o_ready,
	
	input		[31:0]			i_in_data,
	input						i_in_vld,
	output						o_in_rdy,
	
	input		[47:0]			i_dst_mac,
	input		[47:0]			i_src_mac,
	input		[31:0]			i_dst_ip,
	input		[31:0]			i_src_ip,
	
	input		[7:0]			i_protocol,
	
	input						i_more_frame,
	input		[15:0]			i_pkt_id,
	input		[15:0]			i_frame_size,
	input		[15:0]			i_frame_offset,
	
	output		[31:0]			o_eth_data,
	output						o_eth_sop,
	output						o_eth_eop,
	output						o_eth_vld,
	input						i_eth_rdy
);	

	assign o_ready = s_step == SS_NONE ? 1'b1 : 1'b0;
	
	reg			[0:0]			prev_sync;
	always @ (posedge clk) prev_sync <= i_sync;
	
//----------------------------------------------------------------------------
//	HDR_1
//----------------------------------------------------------------------------
	parameter	[3:0]			ip_header_ver = 4'h4;			// 4 - for IPv4
	parameter	[3:0]			ip_header_size = 4'h5;			// size in 32bit word's
	parameter	[7:0]			ip_DSCP_ECN = 8'h00;			// ?

	wire		[31:0]			ip_hdr1;
	assign ip_hdr1 = {ip_header_ver, ip_header_size, ip_DSCP_ECN, (i_frame_size + 16'h0014)};

//----------------------------------------------------------------------------
//	HDR_2
//----------------------------------------------------------------------------
	wire		[2:0]			ip_pkt_flags;					// pkt flags
	assign ip_pkt_flags = {2'b01, i_more_frame};
	wire		[31:0]			ip_hdr2;
	assign ip_hdr2 = {i_pkt_id, ip_pkt_flags, i_frame_offset[15:3]};

//----------------------------------------------------------------------------
//	HDR_3
//----------------------------------------------------------------------------
	parameter	[7:0]			ip_pkt_TTL = 8'hC8;				// pkt TTL
	//parameter	[7:0]			ip_pkt_type = 8'd17;			// pkt UDP == 17
	wire		[15:0]			ip_pkt_CRC;						// pkt flags
	wire		[31:0]			tmp_crc;
	assign tmp_crc = ip_hdr1[31:16] + ip_hdr1[15:0] +
		ip_hdr2[31:16] + ip_hdr2[15:0] + ip_hdr3[31:16] +
		i_src_ip[31:16] + i_src_ip[15:0] + i_dst_ip[31:16] + i_dst_ip[15:0];
	assign ip_pkt_CRC = ~(tmp_crc[31:16] + tmp_crc[15:0]);
	wire			[31:0]		ip_hdr3;	
	//assign ip_hdr3 = {ip_pkt_TTL, ip_pkt_type, ip_pkt_CRC};
	assign ip_hdr3 = {ip_pkt_TTL, i_protocol, ip_pkt_CRC};




	parameter	[3:0]			SS_NONE = 		4'd0,
								SS_START = 		4'd1,
								SS_ETH_HDR_1 = 	4'd2,
								SS_ETH_HDR_2 = 	4'd3,
								SS_ETH_HDR_3 = 	4'd4,
								SS_IP_HDR_1 = 	4'd5,
								SS_IP_HDR_2 = 	4'd6,
								SS_IP_HDR_3 = 	4'd7,
								SS_SRC_IP = 	4'd8,
								SS_DST_IP = 	4'd9,
								SS_SEND_DATA = 	4'd10;
	
	wire		[3:0]			next_step;
	
	reg			[3:0]			s_step;
		
	reg			[15:0]			data_cntr;

	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			s_step <= SS_NONE;
		else
			if(~prev_sync & i_sync) begin
				s_step <= SS_START;
								
				data_cntr <= 16'd0;
			end
			else begin
				s_step <= i_eth_rdy ? next_step : s_step;
				data_cntr <= s_step == SS_SEND_DATA && i_eth_rdy && i_in_vld ? data_cntr + 16'd4 : data_cntr;
			end
		
	assign {next_step, o_eth_sop, o_eth_eop, o_eth_data, o_eth_vld} = 
		s_step == SS_NONE 		? {SS_NONE, 1'b0, 1'b0, 32'dX, 1'b0} : 
		s_step == SS_START 		? {SS_ETH_HDR_1, 1'b1, 1'b0, 16'd0, i_dst_mac[47:32], 1'b1} :
		s_step == SS_ETH_HDR_1 	? {SS_ETH_HDR_2, 1'b0, 1'b0, i_dst_mac[31:0], 1'b1} :
		s_step == SS_ETH_HDR_2 	? {SS_ETH_HDR_3, 1'b0, 1'b0, i_src_mac[47:16], 1'b1} :
		s_step == SS_ETH_HDR_3 	? {SS_IP_HDR_1, 1'b0, 1'b0, i_src_mac[15:0], 16'h0800, 1'b1} :
		s_step == SS_IP_HDR_1 	? {SS_IP_HDR_2, 1'b0, 1'b0, ip_hdr1, 1'b1} : 
		s_step == SS_IP_HDR_2 	? {SS_IP_HDR_3, 1'b0, 1'b0, ip_hdr2, 1'b1} : 
		s_step == SS_IP_HDR_3 	? {SS_SRC_IP, 1'b0, 1'b0, ip_hdr3, 1'b1} :
		s_step == SS_SRC_IP 	? {SS_DST_IP, 1'b0, 1'b0, i_src_ip, 1'b1} :
		s_step == SS_DST_IP 	? {SS_SEND_DATA, 1'b0, 1'b0, i_dst_ip, 1'b1} :
		s_step == SS_SEND_DATA 	? {data_cntr + 16'd4 < i_frame_size || ~i_eth_rdy || ~i_in_vld ? 
										{SS_SEND_DATA, 1'b0, 1'b0} : {SS_NONE, 1'b0, 1'b1}, i_in_data, i_in_vld} :
								  {SS_NONE, 1'b0, 1'b0, 32'dX, 1'b0};
			
	assign o_in_rdy = s_step == SS_SEND_DATA ? i_eth_rdy : 1'b0;

endmodule
