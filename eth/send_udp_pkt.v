module send_udp_pkt(
	input						rst_n,
	input						clk,
	
	output						o_ready,
	input						i_sync,
	
	input		[31:0]			i_in_data,
	input						i_in_vld,
	output						o_in_rdy,
	
	input		[47:0]			i_dst_mac,
	input		[47:0]			i_src_mac,
	
	input		[31:0]			i_src_ip,
	input		[31:0]			i_dst_ip,
	
	input		[15:0]			i_src_port,
	input		[15:0]			i_dst_port,
	
	input		[15:0]			i_data_len,
	
	output		[31:0]			o_eth_data,
	output						o_eth_sop,
	output						o_eth_eop,
	output						o_eth_vld,
	input						i_eth_rdy
);

	reg			[0:0]			prev_sync;
	initial prev_sync <= 1'b0;
	always @ (posedge clk) prev_sync <= i_sync;

	reg			[15:0]			dst_port;
	reg			[15:0]			src_port;
	
	reg			[47:0]			dst_mac;
	reg			[47:0]			src_mac;
	
	reg			[31:0]			dst_ip;
	reg			[31:0]			src_ip;
	
	reg			[15:0]			pkt_id;
	reg			[15:0]			frame_offset;
	
	reg			[15:0]			data_len;
	
	wire		[0:0]			frame_sync;
	wire						ip_sender_ready;
	
	wire		[31:0]			in_data;
	wire						in_vld;
	wire						in_rdy;
	
	
	parameter	[15:0]		max_frame_size = 16'd1480;
	
	wire					more_frame;
	assign more_frame = data_len - frame_offset > max_frame_size ? 1'b1 : 1'b0;
	
	wire		[15:0]		frame_size;
	assign	frame_size =  more_frame ? max_frame_size : data_len - frame_offset;
	
	send_ip_frame send_ip_frame_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_sync(frame_sync),
		.o_ready(ip_sender_ready),
		
		.i_in_data(in_data),	// UDP packet data
		.i_in_vld(in_vld),
		.o_in_rdy(in_rdy),
		
		.i_dst_mac(dst_mac),
		.i_src_mac(src_mac),
		.i_dst_ip(dst_ip),
		.i_src_ip(src_ip),
		
		.i_protocol(8'd17),
		
		.i_more_frame(more_frame),
		.i_pkt_id(pkt_id),
		.i_frame_size(frame_size),
		.i_frame_offset(frame_offset),
		
		.o_eth_data(o_eth_data),
		.o_eth_sop(o_eth_sop),
		.o_eth_eop(o_eth_eop),
		.o_eth_vld(o_eth_vld),
		.i_eth_rdy(i_eth_rdy)
	);
	
	reg			[1:0]		udp_step;
				
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			pkt_id <= 16'd1;
			udp_step <= 2'd0;
		end
		else
			if(~prev_sync & i_sync) begin
				dst_mac <= i_dst_mac;
				src_mac <= i_src_mac;
				dst_ip <= i_dst_ip;
				src_ip <= i_src_ip;
				dst_port <= i_dst_port;
				src_port <= i_src_port;
				
				data_len <= i_data_len + 16'd8;
				
				pkt_id <= pkt_id + 1'd1;
				frame_offset <= 16'd0;
				
				udp_step <= 2'd0;
			end
			else begin
				if(in_rdy)
					udp_step <= next_udp_step;
					
				if(send_state == SS_WAIT_RDY && ip_sender_ready)
					frame_offset <= frame_offset + frame_size;
			end

	wire		[1:0]			next_udp_step;
	assign {next_udp_step, in_data, in_vld, o_in_rdy} =
		udp_step == 16'd0 ? {2'd1, src_port, dst_port, 1'b1, 1'b0} :
		udp_step == 16'd1 ? {2'd2, data_len, 16'd0, 1'b1, 1'b0} : {2'd2, i_in_data, i_in_vld, in_rdy};
		
	parameter	[1:0]			SS_NONE = 2'd0,
								SS_SEND_FRAME = 2'd1,
								SS_WAIT_RDY = 2'd2;
								
	reg			[1:0]			send_state;
	wire		[1:0]			next_send_state;
	
	assign {frame_sync, next_send_state} =
		send_state == SS_NONE ? {1'b0, prev_sync & ~i_sync ? SS_SEND_FRAME : SS_NONE} :
		send_state == SS_SEND_FRAME ? {1'b1, ip_sender_ready ? SS_SEND_FRAME : SS_WAIT_RDY} :
		send_state == SS_WAIT_RDY ? {1'b0, ip_sender_ready ? (more_frame ? SS_SEND_FRAME : SS_NONE) : SS_WAIT_RDY} : 
			{SS_NONE, 1'b0};

	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			send_state <= SS_NONE;
		else
			send_state <= next_send_state;
	
	assign o_ready = send_state == SS_NONE;
	
endmodule
