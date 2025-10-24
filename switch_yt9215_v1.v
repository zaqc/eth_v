module switch_yt9215_v1(
//system
	clk50,
	clk50_1,
	reset_n,
	alt_rdy,
//YT9215 RGMII
	rg1_txclk,
	rg1_txctl,
	rg1_txd,
	rg1_rxclk,
	rg1_rxctl,
	rg1_rxd,
//YT9215 control
	sw_resn,
	sspi_cs,
	sspi_sck_mdc,
	sspi_si_mdio,
	sspi_so,
	disspiss,
//external 9215 PHY control
	phy1_mdio,
	phy1_mdc,
	phy1_resn,
//YT8511 RGMII
	rg3_clk25m,
	rg3_led100,
	rg3_txclk,
	rg3_txctl,
	rg3_txd,
	rg3_rxclk,
	rg3_rxctl,
	rg3_rxd,
//YT8511 control
	phy2_resn,
	phy2_mdc,
	phy2_mdio,	
//GPIO
	io,
//test leds
	led

);

//system
input clk50;
input clk50_1;
input reset_n;
output alt_rdy;
//YT9215 RGMII
input rg1_txclk;
input rg1_txctl;
input [3:0] rg1_txd;
output rg1_rxclk;
output rg1_rxctl;
output [3:0] rg1_rxd;
//YT9215 control
output sw_resn;		//9215 reset
output sspi_cs;
output sspi_sck_mdc;
inout sspi_si_mdio;
input sspi_so;
output disspiss;		//1 - mdio, 0 - sspi 
//external 9215 PHY control
inout phy1_mdio; 		//if jumpers set to phy1 controlled by altera
output phy1_mdc;		//if jumpers set to phy1 controlled by altera
output phy1_resn;		//phy1 reset (independent of jumpers)
//YT8511 RGMII
input rg3_clk25m;
input rg3_led100;
output rg3_txclk;
output rg3_txctl;
output [3:0] rg3_txd;
input rg3_rxclk;
input rg3_rxctl;
input [3:0] rg3_rxd;
//YT8511 control
output phy2_resn;
output phy2_mdc;
inout phy2_mdio;	
//GPIO
inout [31:0] io;
//test leds
output [3:0] led;
//reset all PHYs	
assign alt_rdy = 1'b1;
assign disspiss = 1;	//select sspi control
reg [31:0] res_gen;
wire res_all;
assign res_all = res_gen > 50000;	//1 ms
assign sw_resn = res_all;
assign phy1_resn = res_all;
assign phy2_resn = res_all;
always@(posedge clk50 or negedge reset_n)
begin
	if(!reset_n) res_gen <= 0;
	else if(!res_all) res_gen <= res_gen + 1'b1;
end

//test
//reg [31:0] t_count;
//assign led = t_count[25:22];
//always@(posedge clk50)
//begin
//	t_count <= t_count + 1'b1;
//end

	wire		[7:0]			gmac_addr;
	wire		[31:0]			gmac_rd_data;
	wire						gmac_rd;
	wire		[31:0]			gmac_wr_data;
	wire						gmac_wr;
	wire						gmac_wtrq;

	wire						rst_n;
	wire						sysclk;
	
	gmac_init gmac_init_unit(
		.rst_n(rst_n),
		.clk(sysclk),
		
		.o_addr(gmac_addr),
		.o_wr_data(gmac_wr_data),
		.o_wr(gmac_wr),
		.i_rd_data(gmac_rd_data),
		.o_rd(gmac_rd),
		.i_wtrq(gmac_wtrq)//,
		
		//.o_gi(led)
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
	
	wire						pll_txclk;
	eth_pll eth_pll_unit(
		.inclk0(clk50),
		.c0(pll_txclk),
		.c1(rg3_txclk),
		
		.c2(sysclk),
		
		.locked(rst_n)
	);

	wire						mdio_in;
	wire						mdio_out;
	wire						mdio_oen;

	assign mdio_in = phy2_mdio;
	assign phy2_mdio = mdio_oen ? 1'bZ : mdio_out;

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
		
		.rx_clk(rg3_rxclk),
		.rgmii_in(rg3_rxd),
		.rx_control(rg3_rxctl),
		
		.tx_clk(pll_txclk),
		.rgmii_out(rg3_txd),
		.tx_control(rg3_txctl),
		
		.mdc(phy2_mdc),
		.mdio_in(mdio_in),
		.mdio_out(mdio_out),
		.mdio_oen(mdio_oen),
		
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
	
	reg 		[3:0] 			led_cntr;
	assign led = led_cntr;

	always@(posedge sysclk or negedge rst_n)
	if(~rst_n)
		led_cntr <= 4'd0;
	else
		if(tx_vld & tx_rdy & tx_sop)
			led_cntr <= led_cntr + 1'b1;
	
	wire		[15:0]			frame_size;
	assign frame_size = 16'd1500;
	
	reg			[23:0]			sync_cntr;
	always @ (posedge sysclk)
		sync_cntr <= sync_cntr + 1'd1;
	
	packet_sender packet_sender_unit(
		.rst_n(rst_n),
		.clk(sysclk),
		
		.i_sync(sync_cntr[14]),

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
		
		.i_udp_pkt_len({frame_size[13:0], 2'b00})	// convert 32bit word to bytes (x4)

	);
	
	reg			[9:0]			tx_addr;
	always @ (posedge sysclk)
		if(rx_vld & rx_rdy)
			tx_addr <= tx_addr + 1'd1;
	
	tx_tst_buf tx_tst_buf_unit(
		.clock(sysclk),
		.address(tx_addr),
		.data(rx_data),
		.wren(rx_vld & rx_rdy)
	);
	
	sys sys_unit(
		.clk_clk(sysclk)
	);


endmodule
