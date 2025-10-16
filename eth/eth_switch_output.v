module eth_switch_output(
	output		[31:0]			o_tx_data,	// send to Ethernet
	output						o_tx_vld,
	output						o_tx_sop,
	output						o_tx_eop,
	input						i_tx_rdy,
	
	input		[31:0]			i_arp_data,
	input						i_arp_sop,
	input						i_arp_eop,
	input						i_arp_vld,
	output						o_arp_rdy,

	input		[31:0]			i_udp_data,
	input						i_udp_sop,
	input						i_udp_eop,
	input						i_udp_vld,
	output						o_udp_rdy,
	
	input		[31:0]			i_ping_data,
	input						i_ping_sop,
	input						i_ping_eop,
	input						i_ping_vld,
	output						o_ping_rdy,

	input		[1:0]			i_pkt_type
);
	`include "packet_type.h"

	assign {o_tx_data, o_tx_sop, o_tx_eop, o_tx_vld} = 
		i_pkt_type == PT_ARP ? {i_arp_data, i_arp_sop, i_arp_eop, i_arp_vld} :
		i_pkt_type == PT_UDP ? {i_udp_data, i_udp_sop, i_udp_eop, i_udp_vld} :
		i_pkt_type == PT_PING ? {i_ping_data, i_ping_sop, i_ping_eop, i_ping_vld} :
							 {32'd0, 1'b0, 1'b0, 1'b0};

	assign o_udp_rdy = i_tx_rdy && i_pkt_type == PT_UDP;
	
	assign o_arp_rdy = i_tx_rdy && i_pkt_type == PT_ARP;
	
	assign o_ping_rdy = i_tx_rdy && i_pkt_type == PT_PING;
	
endmodule

