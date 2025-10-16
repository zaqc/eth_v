module send_ping_resp(
	input						rst_n,
	input						clk,
	
	input						i_ping_sync,
	output						o_ready,
	
	output		[31:0]			o_eth_data,
	output						o_eth_sop,
	output						o_eth_eop,
	output						o_eth_vld,
	input						i_eth_rdy,
	
	input		[47:0]			i_self_mac,
	input		[31:0]			i_self_ip,
	
	input		[47:0]			i_ping_req_mac,
	input		[31:0]			i_ping_req_ip,
	
	input		[7:0]			i_payload_size,
	input		[31:0]			i_ping_req_data,
	output						o_ping_req_rdy
);
	
	reg			[15:0]			pkt_id;
	always @ (posedge clk or negedge rst_n) 
		pkt_id <= ~rst_n ? 16'h0001 :
			o_eth_vld & o_eth_eop ? pkt_id + 1'd1 : pkt_id;
	
	send_ip_frame send_ip_frame_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_sync(i_ping_sync),
		.o_ready(o_ready),
		
		.i_in_data(i_ping_req_data),	// Payload packet data
		.i_in_vld(1'b1),
		.o_in_rdy(o_ping_req_rdy),
		
		.i_dst_mac(i_ping_req_mac),
		.i_src_mac(i_self_mac),
		.i_dst_ip(i_ping_req_ip),
		.i_src_ip(i_self_ip),
		
		.i_protocol(8'd01),			// ICMP 
		
		.i_more_frame(1'b0),
		.i_pkt_id(pkt_id),
		.i_frame_size({6'd0, i_payload_size, 2'd0}),
		.i_frame_offset(16'd0),
		
		.o_eth_data(o_eth_data),
		.o_eth_sop(o_eth_sop),
		.o_eth_eop(o_eth_eop),
		.o_eth_vld(o_eth_vld),
		.i_eth_rdy(i_eth_rdy)
	);
	
endmodule

