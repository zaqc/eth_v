module gmac_init(
	input						rst_n,
	input						clk,
	
	input		[47:0]			i_mac_addr,
	input						i_init,
	output						o_done,
	
	output		[7:0]			o_addr,
	output		[31:0]			o_wr_data,
	output						o_wr,
	input		[31:0]			i_rd_data,
	output						o_rd,
	input						i_wtrq,
	
	output		[3:0]			o_gi
);

	parameter	[3:0]			GI_NONE = 0,
								GI_EN_GBIT = 1, 
								GI_SET_MAC_1 = 2,
								GI_SET_MAC_2 = 3,
								
								GI_SET_PHY_ADDR = 4,
																
								GI_RD_PHY_R16 = 5,	// Set Automatic Crossover
								GI_WR_PHY_R16 = 6,

								GI_RD_PHY_R20 = 7,	// Set Delay for GTX
								GI_WR_PHY_R20 = 8,

								GI_RD_PHY_RST = 9,	// Reset PHY
								GI_WR_PHY_RST = 10,
								GI_WAIT_PHY_RST = 11,

								GI_RD_MAC_CTRL_REG = 12,	// Enable MAC RX & TX
								GI_WR_MAC_CTRL_REG = 13,
								
								GI_DONE = 15;
								
	reg			[3:0]			gi_state;
	
	assign o_gi = gi_state;
	
	reg			[31:0]			r_reg;
	
	wire						rd;
	wire						wr;
	
	// self_mac <= {8'h00, 8'h22, 8'h36, 8'hEC, 8'h04, 8'h01};
	// mac_addr <= {i_mac_addr[23:16], i_mac_addr[31:24], i_mac_addr[39:32], i_mac_addr[47:40], i_mac_addr[7:0], i_mac_addr[15:8]};
	assign 								  {o_addr,	o_wr_data, 					wr, 	rd} =
		gi_state == GI_NONE				? {8'hXX,	32'hXXXXXXXX, 				1'b0, 	1'b0} :
		gi_state == GI_EN_GBIT			? {8'h02,	32'h00000008, 				1'b1, 	1'b0} :
		//gi_state == GI_SET_MAC_1		? {8'h03,	32'hEC362200,	 			1'b1, 	1'b0} :
		//gi_state == GI_SET_MAC_2		? {8'h04,	32'h00000104,				1'b1, 	1'b0} :
		gi_state == GI_SET_MAC_1		? {8'h03,	mac_addr[47:16],			1'b1, 	1'b0} :
		gi_state == GI_SET_MAC_2		? {8'h04,	{16'd0, mac_addr[15:0]},	1'b1, 	1'b0} :
		
		gi_state == GI_SET_PHY_ADDR		? {8'h0F,	32'h00000010,				1'b1, 	1'b0} :
				
		gi_state == GI_RD_PHY_R16		? {8'h90, 	32'hXXXXXXXX,				1'b0, 	1'b1} :
		gi_state == GI_WR_PHY_R16		? {8'h90, 	r_reg | 8'h60, 				1'b1,	1'b0} :	// 0x90
		
		gi_state == GI_RD_PHY_R20		? {8'h94, 	32'hXXXXXXXX, 				1'b0,	1'b1} :
		gi_state == GI_WR_PHY_R20		? {8'h94,	r_reg | 8'h82, 				1'b1,	1'b0} :	// 0x94

		gi_state == GI_RD_PHY_RST		? {8'h80, 	32'hXXXXXXXX,				1'b0, 	1'b1} :
		gi_state == GI_WR_PHY_RST		? {8'h80, 	r_reg | 16'h8000,			1'b1, 	1'b0} :	// 0x80
		gi_state == GI_WAIT_PHY_RST		? {8'h80, 	32'hXXXXXXXX,				1'b0, 	1'b1} :

		gi_state == GI_RD_MAC_CTRL_REG	? {8'h02,	32'hXXXXXXXX, 				1'b0,	1'b1} :
		gi_state == GI_WR_MAC_CTRL_REG	? {8'h02,	r_reg | 4'h3, 				1'b1,	1'b0} :	// Enable TX & RX
										  {8'hXX,	32'hXXXXXXXX, 				1'b0, 	1'b0};
										  
	assign o_wr = wr;
	assign o_rd = rd;

	always @ (posedge clk)
		if(~i_wtrq & rd)
			r_reg <= i_rd_data;
			
	reg			[25:0]			delay;
	reg			[0:0]			delay_done;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			delay <= 0;
			delay_done <= 1'b0;
		end
		else
			if(need_init == 2'b01) begin
				delay_done <= 1'b0;
				delay_done <= 1'b0;
			end
			else
				if(~delay_done)
					if(~&{delay})
						delay <= delay + 1'd1;
					else
						delay_done <= 1'b1;
			
	reg			[1:0]			need_init;
	always @ (posedge clk or negedge rst_n) 
		if(!rst_n)
			need_init <= 2'b00;
		else
			need_init <= {need_init[0], i_init};
	
	reg			[0:0]			done;
	assign o_done = done;
	
	reg			[47:0]			mac_addr;
		
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin
			gi_state <= GI_NONE;
			done <= 1'b0;
		end
		else begin
			done <= 1'b0;
			if(need_init == 2'b01) 
				gi_state <= GI_NONE;
			else
				if(delay_done)
					if(gi_state == GI_NONE || ~i_wtrq)
						case(gi_state)
							GI_NONE:
								begin
									mac_addr <= {i_mac_addr[23:16], i_mac_addr[31:24], i_mac_addr[39:32], i_mac_addr[47:40], i_mac_addr[7:0], i_mac_addr[15:8]};
									gi_state <= GI_EN_GBIT;
								end
							GI_WAIT_PHY_RST: if(~i_rd_data[15]) gi_state <= GI_RD_MAC_CTRL_REG;
							//GI_SET_MAC_2: gi_state <= GI_RD_MAC_CTRL_REG;
							GI_WR_MAC_CTRL_REG: gi_state <= GI_DONE;
							GI_DONE: 
								begin
									gi_state <= gi_state;
									done <= 1'b1;
								end
							default: gi_state <= gi_state + 1'd1;
						endcase
		end
		
//	probe8 probe8_u0(.probe({4'd0, gi_state}));
//	probe48 probe48_u0(.probe(mac_addr));
//	probe48 probe48_u1(.probe(i_mac_addr));

endmodule
