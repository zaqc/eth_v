module packet_sender(
	input						rst_n,
	input						clk,
	
	input						i_sync,		// sync for UDP Packet Send

	input		[7:0]			i_eb_addr,
	input		[31:0]			i_eb_wr_data,
	input						i_eb_wr,
	output		[31:0]			o_eb_rd_data,
	input						i_eb_rd,
	
	output		[31:0]			o_tx_data,	// send to Ethernet
	output						o_tx_vld,
	output						o_tx_sop,
	output						o_tx_eop,
	input						i_tx_rdy,
	
	input		[31:0]			i_rx_data,	// receive from Ethernet
	input						i_rx_vld,
	input						i_rx_sop,
	input						i_rx_eop,
	output						o_rx_rdy,
	
	input		[31:0]			i_in_data,	// Data Stream to Send
	input						i_in_vld,
	output						o_in_rdy,
	
	output		[31:0]			o_def_addr,	// DScope commands after RX_UDP parsing
	output		[31:0]			o_def_data,
	output						o_def_wren,
	input						i_def_rdy,
	
	output		[31:0]			o_vrc_data,
	output		[5:0]			o_vrc_addr,
	output		[1:0]			o_vrc_wren,
	
	output		[3:0]			o_arp_blink,
	
	input		[15:0]			i_udp_pkt_len
);
	`include "packet_type.h"

	wire		[1:0]			pkt_type;

	assign o_eb_rd_data = 32'd0;
								
	wire		[47:0]			self_mac;
	wire		[31:0]			self_ip;
	
	wire		[47:0]			mcast_mac;
	wire		[31:0]			mcast_ip;
	
	wire		[15:0]			udp_dst_port;
	wire		[15:0]			udp_src_port;
	
	wire		[15:0]			udp_pkt_len;
	wire		[15:0]			udp_start_addr;
	
	wire						arp_sync;
	wire						udp_sync;
	wire						ping_sync;
	
	reg			[0:0]			prev_arp_sync;
	initial prev_arp_sync <= 1'b0;
	always @ (posedge clk) prev_arp_sync <= arp_sync;
	
	reg			[3:0]			arp_blink;
	initial arp_blink <= 1'b0;
	always @ (posedge clk) arp_blink <= i_rx_vld & i_rx_sop ? arp_blink + 1'd1 : arp_blink;
	
	assign o_arp_blink = arp_blink;

	packet_param packet_param_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_eb_addr(i_eb_addr),
		.i_eb_wr_data(i_eb_wr_data),
		.i_eb_wr(i_eb_wr),
	
		.o_self_mac(self_mac),
		.o_self_ip(self_ip),
		
		.o_mcast_mac(mcast_mac),
		.o_mcast_ip(mcast_ip),
		
		.o_udp_src_port(udp_src_port),
		.o_udp_dst_port(udp_dst_port),
	
		.o_udp_pkt_len(udp_pkt_len),
		.o_udp_start_addr(udp_start_addr)
	);
	
	wire						arp_ready;	// module ready
	wire						udp_ready;
	wire						ping_ready;
	
	wire		[47:0]			arp_req_mac;
	wire		[31:0]			arp_req_ip;
	
	wire		[47:0]			ping_req_mac;
	wire		[31:0]			ping_req_ip;
	wire		[7:0]			payload_size;
	
	wire		[31:0]			ping_req_data;
	wire						ping_req_rdy;

	eth_pkt_type eth_pkt_type_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_sync(i_sync),
		
		.i_self_mac(self_mac),
		.i_self_ip(self_ip),
		
		.i_in_data(i_rx_data),
		.i_in_sop(i_rx_sop),
		.i_in_eop(i_rx_eop),
		.i_in_vld(i_rx_vld),
		.o_in_rdy(o_rx_rdy),
		
		.i_arp_ready(arp_ready),
		.i_udp_ready(udp_ready),
		.i_ping_ready(ping_ready),
		
		.o_pkt_type(pkt_type),
		
		.o_udp_sync(udp_sync),
		
		.o_arp_sync(arp_sync),
		.o_arp_req_mac(arp_req_mac),
		.o_arp_req_ip(arp_req_ip),
		.o_payload_size(payload_size),
		
		.o_ping_sync(ping_sync),
		.o_ping_req_mac(ping_req_mac),
		.o_ping_req_ip(ping_req_ip),
		.o_ping_req_data(ping_req_data),
		.i_ping_req_rdy(ping_req_rdy),
		
		.o_def_addr(o_def_addr),
		.o_def_data(o_def_data),
		.o_def_wren(o_def_wren),
		.i_def_rdy(i_def_rdy),
		
		.o_vrc_addr(o_vrc_addr),
		.o_vrc_data(o_vrc_data),
		.o_vrc_wren(o_vrc_wren)
	);
	
	//------------------------------------------------------------------------
							
	wire		[31:0]			arp_data;
	wire						arp_sop;
	wire						arp_eop;
	wire						arp_vld;
	wire						arp_rdy;	// i_rx_ready
	
	send_arp_pkt	send_arp_pkt_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.o_ready(arp_ready),
		.i_sync(arp_sync),
		
		.i_dst_mac(arp_req_mac),
		.i_src_mac(self_mac),
		.i_arp_opcode(16'd02),	// ARP RESPONSE

		.i_arp_sha(self_mac),
		.i_arp_spa(self_ip),
		.i_arp_tha(arp_req_mac),
		.i_arp_tpa(arp_req_ip),

		.o_eth_sop(arp_sop),
		.o_eth_eop(arp_eop),
		.o_eth_vld(arp_vld),
		.o_eth_data(arp_data),
		.i_eth_rdy(arp_rdy)
	);
	
	//------------------------------------------------------------------------

	wire		[31:0]			udp_data;
	wire						udp_sop;
	wire						udp_eop;
	wire						udp_vld;
	wire						udp_rdy;
	
	send_udp_pkt send_udp_pkt_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_dst_mac(mcast_mac),
		.i_src_mac(self_mac),
		
		.i_dst_ip(mcast_ip),
		.i_src_ip(self_ip),
		
		.i_src_port(udp_src_port),
		.i_dst_port(udp_dst_port),
		
		.i_data_len(i_udp_pkt_len),
		
		.i_sync(udp_sync),
		.o_ready(udp_ready),
		
		.i_in_data(i_in_data),
		.i_in_vld(i_in_vld),
		.o_in_rdy(o_in_rdy),

		.o_eth_sop(udp_sop),
		.o_eth_eop(udp_eop),
		.o_eth_vld(udp_vld),
		.o_eth_data(udp_data),
		.i_eth_rdy(udp_rdy)
	);
	
	//------------------------------------------------------------------------
	
	wire		[31:0]			ping_data;
	wire						ping_sop;
	wire						ping_eop;
	wire						ping_vld;
	wire						ping_rdy;
	
	send_ping_resp send_ping_resp_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_ping_sync(ping_sync),
		.o_ready(ping_ready),
		
		.i_self_mac(self_mac),
		.i_self_ip(self_ip),
		
		.i_ping_req_mac(ping_req_mac),
		.i_ping_req_ip(ping_req_ip),
		
		.i_payload_size(payload_size),
		
		.i_ping_req_data(ping_req_data),
		.o_ping_req_rdy(ping_req_rdy),

		.o_eth_sop(ping_sop),
		.o_eth_eop(ping_eop),
		.o_eth_vld(ping_vld),
		.o_eth_data(ping_data),
		.i_eth_rdy(ping_rdy) //1'b1)//ping_rdy)
	);
	
	//------------------------------------------------------------------------
	
	wire		[31:0]			tx_fifo_data;
	wire						tx_fifo_sop;
	wire						tx_fifo_eop;
	wire						tx_fifo_rdy;
	wire						tx_fifo_vld;

	eth_switch_output eth_switch_output_unit(
		.o_tx_data(tx_fifo_data),	// send to Ethernet
		.o_tx_vld(tx_fifo_vld),
		.o_tx_sop(tx_fifo_sop),
		.o_tx_eop(tx_fifo_eop),
		.i_tx_rdy(tx_fifo_rdy),
	
		.i_arp_data(arp_data),
		.i_arp_sop(arp_sop),
		.i_arp_eop(arp_eop),
		.i_arp_vld(arp_vld),
		.o_arp_rdy(arp_rdy),
		
		.i_udp_data(udp_data),
		.i_udp_sop(udp_sop),
		.i_udp_eop(udp_eop),
		.i_udp_vld(udp_vld),
		.o_udp_rdy(udp_rdy),
		
		.i_ping_data(ping_data),
		.i_ping_sop(ping_sop),
		.i_ping_eop(ping_eop),
		.i_ping_vld(ping_vld),
		.o_ping_rdy(ping_rdy),

		.i_pkt_type(pkt_type)
	);
	
	//------------------------------------------------------------------------		
	
`ifdef TESTMODE
	assign o_tx_data = tx_fifo_data;
	assign o_tx_eop = tx_fifo_eop;
	assign o_tx_sop = tx_fifo_sop;
	assign o_tx_vld = tx_fifo_vld;
	assign tx_fifo_rdy = i_tx_rdy;
`else
	wire		[1:0]			tx_fifo_dummy;
	wire						tx_fifo_full;

	reg			[3:0]			ff_cntr;
	
	wire		[0:0]			f_filled;
	assign f_filled = |{ff_cntr};
		
	wire						f_empty;
	assign o_tx_vld = ~f_empty & f_filled;
	
	wire						f_rd;
	assign f_rd = i_tx_rdy & f_filled;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			ff_cntr <= 4'd0;
		else
			if(tx_fifo_vld & tx_fifo_eop & ~tx_fifo_full)
				ff_cntr <= ~f_empty & f_rd & o_tx_eop ? ff_cntr : ff_cntr + 1'b1;
			else
				if(~f_empty & f_rd & o_tx_eop)
					ff_cntr <= ff_cntr - 1'd1;

	eth_tx_fifo eth_tx_fifo_unit(
		.aclr(~rst_n),
		
		.clock(clk),
		.data({tx_fifo_data, tx_fifo_sop, tx_fifo_eop, 2'dX}),
		.wrreq(tx_fifo_vld),
		.full(tx_fifo_full),
		
		.q({o_tx_data, o_tx_sop, o_tx_eop, tx_fifo_dummy}),
		.rdreq(f_rd),
		.empty(f_empty)
	);
	
	assign tx_fifo_rdy = ~tx_fifo_full;
`endif

endmodule
