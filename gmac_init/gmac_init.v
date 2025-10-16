module gmac_init(
	input						rst_n,
	input						clk,
	
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
								
								GI_SET_PHY_ADDR_0 = 4,
								GI_SET_PHY_ADDR_1 = 5,
																
								GI_RD_PHY_R16 = 6,	// Set Automatic Crossover
								GI_WR_PHY_R16 = 7,
								
								GI_RD_PHY_R20 = 8,	// Set Delay for GTX
								GI_WR_PHY_R20 = 9,

								GI_RD_PHY_RST = 10,	// Reset PHY
								GI_WR_PHY_RST = 11,
								GI_WAIT_PHY_RST = 12,

								GI_RD_MAC_CTRL_REG = 13,	// Enable MAC RX & TX
								GI_WR_MAC_CTRL_REG = 14,
								
								GI_DONE = 15;
								
	reg			[3:0]			gi_state;
	
	assign o_gi = gi_state;
	
	reg			[31:0]			r_reg;
	
	wire						rd;
	wire						wr;
								
	assign 								  {o_addr,	o_wr_data, 			wr, 	rd} =
		gi_state == GI_NONE				? {8'hXX,	32'hXXXXXXXX, 		1'b0, 	1'b0} :
		gi_state == GI_EN_GBIT			? {8'h02,	32'h00000008, 		1'b1, 	1'b0} :
		gi_state == GI_SET_MAC_1		? {8'h03,	32'hEC362200,	 	1'b1, 	1'b0} :
		gi_state == GI_SET_MAC_2		? {8'h04,	32'h00000104,		1'b1, 	1'b0} :
		
		gi_state == GI_SET_PHY_ADDR_0	? {8'h0F,	32'h00000004 /*0x10*/,		1'b1, 	1'b0} :	
		gi_state == GI_SET_PHY_ADDR_1	? {8'h10,	32'h00000000 /*0x10*/,		1'b1, 	1'b0} :	
				
		gi_state == GI_RD_PHY_R16		? {8'h90, 	32'hXXXXXXXX,		1'b0, 	1'b1} :
		gi_state == GI_WR_PHY_R16		? {8'h90, 	r_reg | 8'h60, 		1'b1,	1'b0} :	// 0x90
		
		gi_state == GI_RD_PHY_R20		? {8'h94, 	32'hXXXXXXXX, 		1'b0,	1'b1} :
		gi_state == GI_WR_PHY_R20		? {8'h94,	r_reg | 8'h82, 		1'b1,	1'b0} :	// 0x94

		gi_state == GI_RD_PHY_RST		? {8'h80, 	32'hXXXXXXXX,		1'b0, 	1'b1} :
		gi_state == GI_WR_PHY_RST		? {8'h80, 	r_reg | 16'h8000,	1'b1, 	1'b0} :	// 0x80
		gi_state == GI_WAIT_PHY_RST		? {8'h80, 	32'hXXXXXXXX,		1'b0, 	1'b1} :

		gi_state == GI_RD_MAC_CTRL_REG	? {8'h02,	32'hXXXXXXXX, 		1'b0,	1'b1} :
		gi_state == GI_WR_MAC_CTRL_REG	? {8'h02,	r_reg | 4'h3, 		1'b1,	1'b0} :	// Enable TX & RX
										  {8'hXX,	32'hXXXXXXXX, 		1'b0, 	1'b0};
										  
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
			if(~delay_done)
				if(~&{delay})
					delay <= delay + 1'd1;
				else
					delay_done <= 1'b1;
		
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			gi_state <= GI_NONE;
		else
			if(delay_done)
				if(~|{gi_state} || ~i_wtrq)
					case(gi_state)
						GI_SET_PHY_ADDR_1: gi_state <= GI_RD_PHY_RST;
						GI_WAIT_PHY_RST: if(~i_rd_data[15]) gi_state <= GI_RD_MAC_CTRL_REG;
						GI_WR_MAC_CTRL_REG: gi_state <= GI_DONE;
						GI_DONE: gi_state <= gi_state;
						default: gi_state <= gi_state + 1'd1;
					endcase

endmodule
