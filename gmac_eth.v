module gmac_eth(
	input						rst_n,
	input						sysclk,
	
	input						i_sync,
	
	input		[31:0]			i_frame_data,
	input						i_frame_vld,
	output						o_frame_rdy,
	
	input		[15:0]			i_frame_size,
	
	output		[31:0]			o_cmd_addr,
	output		[31:0]			o_cmd_data,
	output						o_cmd_vld,
	
	input						i_rxclk,
	input		[3:0]			i_rxd,
	input						i_rxctl,
	
	input						i_txclk,
	output		[3:0]			o_txd,
	output						o_txctl,
	
	output						o_mdc,
	inout						io_mdio,
	
	input						i_set_eth_param,
	input		[31:0]			i_self_ip,
	input		[47:0]			i_self_mac,
	input		[31:0]			i_mcast_ip,
	input		[47:0]			i_mcast_mac,
	input		[15:0]			i_src_port,
	input		[15:0]			i_dst_port
);

	wire		[7:0]			gmac_addr;
	wire		[31:0]			gmac_rd_data;
	wire						gmac_rd;
	wire		[31:0]			gmac_wr_data;
	wire						gmac_wr;
	wire						gmac_wtrq;
	
	wire		[47:0]			self_mac;
		
	gmac_init gmac_init_unit(
		.rst_n(rst_n),
		.clk(sysclk),
		
		.i_init(i_set_eth_param),
		.i_mac_addr(self_mac),
		
		.o_addr(gmac_addr),
		.o_wr_data(gmac_wr_data),
		.o_wr(gmac_wr),
		.i_rd_data(gmac_rd_data),
		.o_rd(gmac_rd),
		.i_wtrq(gmac_wtrq)
	);

	wire		[31:0]			tx_data;
	wire						tx_vld;
	wire						tx_sop;
	wire						tx_eop;
	wire						tx_rdy;
	
	wire		[31:0]			rx_data;
	wire						rx_vld;
	wire						rx_sop;
	wire						rx_eop;
	wire						rx_rdy;

	wire						mdio_in;
	wire						mdio_out;
	wire						mdio_oen;

	//assign mdio_in = phy2_mdio;
	//assign phy2_mdio = mdio_oen ? 1'bZ : mdio_out;

	gmac gmac_unit(
		.reset(~rst_n),
		.clk(sysclk),
		
		.address(gmac_addr),
		.readdata(gmac_rd_data),
		.read(gmac_rd),
		.writedata(gmac_wr_data),
		.write(gmac_wr),
		.waitrequest(gmac_wtrq),
		
		.set_10(1'b0),
		.set_1000(1'b1),
		
		.rx_clk(i_rxclk),
		.rgmii_in(i_rxd),
		.rx_control(i_rxctl),
		
		.tx_clk(i_txclk),
		.rgmii_out(o_txd),
		.tx_control(o_txctl),
		
		//.mdc(phy2_mdc),
		//.mdio_in(mdio_in),
		//.mdio_out(mdio_out),
		//.mdio_oen(mdio_oen),
		
		.ff_tx_clk(sysclk),
		.ff_tx_data(tx_data),
		.ff_tx_wren(tx_vld),
		.ff_tx_sop(tx_sop),
		.ff_tx_eop(tx_eop),
		.ff_tx_rdy(tx_rdy),
		.ff_tx_mod(2'd0),
		
		.ff_rx_clk(sysclk),
		.ff_rx_data(rx_data),
		.ff_rx_dval(rx_vld),
		.ff_rx_sop(rx_sop),
		.ff_rx_eop(rx_eop),
		.ff_rx_rdy(rx_rdy)
	);
	
	packet_sender packet_sender_unit(
		.rst_n(rst_n),
		.clk(sysclk),
		
		.i_sync(i_sync),

		.i_rx_data(rx_data),
		.i_rx_vld(rx_vld),
		.i_rx_sop(rx_sop),
		.i_rx_eop(rx_eop),
		.o_rx_rdy(rx_rdy),
		
		.o_tx_data(tx_data),
		.o_tx_vld(tx_vld),
		.o_tx_sop(tx_sop),
		.o_tx_eop(tx_eop),
		.i_tx_rdy(tx_rdy),
		
		.i_in_data(i_frame_data),
		.i_in_vld(i_frame_vld),
		.o_in_rdy(o_frame_rdy),
		
		.o_def_addr(o_cmd_addr),
		.o_def_data(o_cmd_data),
		.o_def_wren(o_cmd_vld),
		.i_def_rdy(1'b1), //cmd_rdy),
		
		.i_udp_pkt_len({i_frame_size[13:0], 2'b00}),	// convert 32bit word to bytes (x4)
		
		.i_set_eth_param(i_set_eth_param),
		.i_self_ip(i_self_ip),
		.i_self_mac(i_self_mac),
		.i_mcast_ip(i_mcast_ip),
		.i_mcast_mac(i_mcast_mac),
		.i_src_port(i_src_port),
		.i_dst_port(i_dst_port),
		
		.o_self_mac(self_mac)
	);

endmodule

