module eth_pkt_type(
	input						rst_n,
	input						clk,
	
	input						i_sync,
	
	input		[31:0]			i_self_ip,
	input		[47:0]			i_self_mac,
				
	input		[31:0]			i_in_data,		// input stream (from MAC)
	input						i_in_sop,
	input						i_in_eop,
	input						i_in_vld,
	output						o_in_rdy,
	
	input						i_arp_ready,
	input						i_udp_ready,
	input						i_ping_ready,
	
	output		[1:0]			o_pkt_type,
	
	output		[47:0]			o_arp_req_mac,
	output		[31:0]			o_arp_req_ip,
	
	output		[7:0]			o_payload_size,
	output		[47:0]			o_ping_req_mac,
	output		[31:0]			o_ping_req_ip,
	output		[31:0]			o_ping_req_data,
	input						i_ping_req_rdy,
	
	output						o_udp_sync,
	output						o_arp_sync,
	output						o_ping_sync,
	
	output		[31:0]			o_def_addr,
	output		[31:0]			o_def_data,
	output						o_def_wren,
	input						i_def_rdy,
	
	output		[5:0]			o_vrc_addr,
	output		[31:0]			o_vrc_data,
	output		[1:0]			o_vrc_wren
);
	`include "packet_type.h"
	
	reg			[0:0]			prev_sync;
	initial prev_sync <= 1'b0;
	always @ (posedge clk) prev_sync <= i_sync;

	assign o_pkt_type = pkt_type;

	reg			[1:0]			pkt_type;
	initial pkt_type = PT_NONE;

	reg			[1:0]			prev_pkt_type;
	initial prev_pkt_type = PT_NONE;
	always @ (posedge clk) prev_pkt_type <= pkt_type;
	
	reg			[0:0]			sync_lutched;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			sync_lutched <= 1'b0;
		else
		if(i_sync & ~prev_sync)
			sync_lutched <= 1'b1;
		else
			if(prev_pkt_type == PT_NONE && pkt_type == PT_UDP)
					sync_lutched <= 1'b0;
					
	assign o_arp_sync = prev_pkt_type == PT_NONE && pkt_type == PT_ARP;
	assign o_udp_sync = prev_pkt_type == PT_NONE && pkt_type == PT_UDP;
	assign o_ping_sync = prev_pkt_type == PT_NONE && pkt_type == PT_PING;
	
	wire						arp_req_flag;
	wire						ping_req_flag;
	eth_parser eth_parser_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_self_ip(i_self_ip),
		.i_self_mac(i_self_mac),
		
		.i_in_data(i_in_data),
		.i_in_sop(i_in_sop),
		.i_in_eop(i_in_eop),
		.i_in_vld(i_in_vld),
		.o_in_rdy(o_in_rdy),
		
		.o_arp_req_flag(arp_req_flag),		// the flag will be set when an ARP REQUEST is received
		.o_arp_req_mac(o_arp_req_mac),
		.o_arp_req_ip(o_arp_req_ip),
		
		.o_ping_req_flag(ping_req_flag),	// the flag will be set when an PING REQUEST is received
		.o_ping_req_data(o_ping_req_data),
		.o_ping_req_mac(o_ping_req_mac),
		.o_ping_req_ip(o_ping_req_ip),
		.i_ping_req_rdy(i_ping_req_rdy),
		.o_payload_size(o_payload_size),
		
		.i_clear_arp_req(prev_pkt_type == PT_NONE && pkt_type == PT_ARP),	// clear flag when sending ARP RESPONSE
		.i_clear_ping_req(prev_pkt_type == PT_NONE && pkt_type == PT_PING),
		
		.o_def_addr(o_def_addr),
		.o_def_data(o_def_data),
		.o_def_wren(o_def_wren),
		.i_def_rdy(i_def_rdy),
		
		.o_vrc_addr(o_vrc_addr),
		.o_vrc_data(o_vrc_data),
		.o_vrc_wren(o_vrc_wren)
	);
	
	wire						arp_ready_rise;
	rise_detector arp_rise_detector(.rst_n(rst_n), .clk(clk), .i_signal(i_arp_ready), .o_rise(arp_ready_rise));
	
	wire						udp_ready_rise;
	rise_detector udp_rise_detector(.rst_n(rst_n), .clk(clk), .i_signal(i_udp_ready), .o_rise(udp_ready_rise));
	
	wire						ping_ready_rise;
	rise_detector ping_rise_detector(.rst_n(rst_n), .clk(clk), .i_signal(i_ping_ready), .o_rise(ping_ready_rise));
	
//	reg			[0:0]			prev_arp_ready;
//	always @ (posedge clk or negedge rst_n) prev_arp_ready <= ~rst_n ? 1'b0 : i_arp_ready;
//	wire						arp_ready_rise;
//	assign arp_ready_rise = ~prev_arp_ready & i_arp_ready ? 1'b1 : 1'b0;
//	
//	reg			[0:0]			prev_udp_ready;
//	always @ (posedge clk or negedge rst_n) prev_udp_ready <= ~rst_n ? 1'b0 : i_udp_ready;
//	wire						udp_ready_rise;
//	assign udp_ready_rise = ~prev_udp_ready & i_udp_ready ? 1'b1 : 1'b0;	
//	
//	reg			[0:0]			prev_ping_ready;
//	always @ (posedge clk or negedge rst_n) prev_ping_ready <= ~rst_n ? 1'b0 : i_ping_ready;
//	wire						ping_ready_rise;
//	assign ping_ready_rise = ~prev_ping_ready & i_ping_ready ? 1'b1 : 1'b0;	
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			pkt_type <= PT_NONE;
		end
		else
			case(pkt_type)
				PT_NONE: pkt_type <= arp_req_flag && i_arp_ready ? PT_ARP : 
									 ping_req_flag && i_ping_ready ? PT_PING :
									 sync_lutched && i_udp_ready ? PT_UDP : PT_NONE;
				PT_ARP: pkt_type <= arp_ready_rise ? PT_NONE : PT_ARP;
				PT_UDP: pkt_type <= udp_ready_rise ? PT_NONE : PT_UDP;
				PT_PING: pkt_type <= ping_ready_rise ? PT_NONE : PT_PING;
			endcase

endmodule

