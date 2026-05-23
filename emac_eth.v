module emac_eth(
	input						rst_n,
	input						sysclk,
	
	input						i_sync,
	
	input		[31:0]			i_frame_data,
	input						i_frame_vld,
	output						o_frame_rdy,
	
	input		[15:0]			i_frame_size,
	
	output		[31:0]			o_def_addr,
	output		[31:0]			o_def_data,
	output						o_def_wren,
	
	input						i_refclk,			// 50 MHz input
	//output						o_refclk,			//lan8720 clock 50 MHz

	//output						o_ephy_rst_n,		//lan8720 reset
	
	output		[1:0]			o_txd,
	output						o_txen,
	
	input 		[1:0]			i_rxd,
	input						i_rxdv,
	input 						i_rxer,
	
	output						o_mdc,
	inout						io_mdio
);

	//assign o_refclk = i_refclk;
	//assign o_ephy_rst_n = rst_n;

	wire		[7:0]			phy_ctr_addr;
	wire		[31:0]			phy_ctr_wr_data;
	wire						phy_ctr_wr;
	wire		[31:0]			phy_ctr_rd_data;
	wire						phy_ctr_rd;
	wire						phy_ctr_waitreqest;

	init_phy init_phy_u0(
		.clk(sysclk),
		.rst_n(rst_n),

		.o_phy_ctr_addr(phy_ctr_addr),
		.o_phy_ctr_wr_data(phy_ctr_wr_data),
		.o_phy_ctr_wr(phy_ctr_wr),
		.i_phy_ctr_rd_data(phy_ctr_rd_data),
		.o_phy_ctr_rd(phy_ctr_rd),
		
		.i_phy_ctr_waitreqest(phy_ctr_waitreqest)
	);

	wire						mdio_in_phy;
	wire						mdio_out_phy;
	wire						mdio_oen_phy;

	assign mdio_in_phy = io_mdio;
	assign io_mdio = mdio_oen_phy ? 1'bZ : mdio_out_phy;

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

	wire						mii_rxclk;
	wire		[3:0]			mii_rxd;
	wire						mii_rxen;
	wire						mii_rxer;
	wire						mii_crs;
	wire						mii_col;
	
	wire						mii_txclk;
	wire		[3:0]			mii_txd;
	wire						mii_txen;
	wire						mii_txer;

	mac mac_unit(
		.reset(~rst_n),
		.clk(sysclk),
		
		.reg_addr(phy_ctr_addr),
		.reg_data_out(phy_ctr_rd_data),
		.reg_rd(phy_ctr_rd),
		.reg_data_in(phy_ctr_wr_data),
		.reg_wr(phy_ctr_wr),
		.reg_busy(phy_ctr_waitreqest),

//		.address(phy_ctr_addr),
//		.readdata(phy_ctr_rd_data),
//		.read(phy_ctr_rd),
//		.writedata(phy_ctr_wr_data),
//		.write(phy_ctr_wr),
//		.waitrequest(phy_ctr_waitreqest),
		
		.set_10(1'b0),
		.set_1000(1'b0),
		
		.rx_clk(mii_rxclk),
		.m_rx_d(mii_rxd),
		.m_rx_en(mii_rxen),
		.m_rx_err(mii_rxer),
		.m_rx_crs(mii_crs),
		.m_rx_col(mii_col),
		
		.tx_clk(mii_txclk),
		.m_tx_d(mii_txd),
		.m_tx_en(mii_txen),
		.m_tx_err(mii_txer),
		
		.mdc(o_mdc),
		.mdio_in(mdio_in_phy),
		.mdio_out(mdio_out_phy),
		.mdio_oen(mdio_oen_phy),
		
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
		.ff_rx_rdy(1'b1) //rx_rdy)
	);

	mii2rmii mii2rmii_unit(
		.RefClk(i_refclk), // clk50), // refclko),
		.Rstn(rst_n),
		
		//mii(Mac) <-> rmii Tx
		.tx_clk(mii_txclk),
		.m_tx_en(mii_txen),
		.m_tx_d(mii_txd),
		.m_tx_err(mii_txer),
		
		//rmii <-> Mac Rx
		.rx_clk(mii_rxclk),
		.m_rx_en(mii_rxen),
		.m_rx_d(mii_rxd),
		.m_rx_err(mii_rxer),
		.m_rx_crs(mii_crs),
		.m_rx_col(mii_col),
		
		//rmii <-> PHY
		.rmii_crs_dv(i_rxdv), //Carrier Sense/Receive Data Valid
		.rmii_rx_d(i_rxd),   //Receive Data
		.rmii_rx_err(i_rxer),

		.rmii_tx_en(o_txen),  //
		.rmii_tx_d(o_txd),
		
		.ena_10(1'b0)
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
		
		//.i_in_data(frame_data),
		.i_in_vld(1'b1), //frame_vld),
		//.o_in_rdy(frame_rdy),
		
		//.o_def_addr(cmd_magic),
		//.o_def_data(cmd_command),
		//.o_def_wren(cmd_vld),
		.i_def_rdy(1'b1), //cmd_rdy),
		
		.i_udp_pkt_len({i_frame_size[13:0], 2'b00})	// convert 32bit word to bytes (x4)
	);

endmodule
