module init_phy(
	input						clk,
	input						rst_n,
	
	output		[7:0]			o_phy_ctr_addr,
	output		[31:0]			o_phy_ctr_wr_data,
	output						o_phy_ctr_wr,
	input		[31:0]			i_phy_ctr_rd_data,
	output						o_phy_ctr_rd,

	input						i_phy_ctr_waitreqest
);

	assign o_phy_ctr_addr = phy_ctr_addr;
	assign o_phy_ctr_wr_data = phy_ctr_wr_data;
	assign o_phy_ctr_wr = phy_ctr_wr;
	assign o_phy_ctr_rd = phy_ctr_rd;

//----------------------------------------------------------------------------
//	init phy
//----------------------------------------------------------------------------

	reg			[3:0]			phy_state;

	reg			[7:0]			phy_ctr_addr;
	reg			[31:0]			phy_ctr_wr_data;
	reg			[0:0]			phy_ctr_wr;
	reg			[0:0]			phy_ctr_rd;

	reg			[7:0]			phy_wait;

	always @ (posedge clk or negedge rst_n)
	begin
		if(~rst_n) begin
			phy_state <= 4'd0;
			phy_wait <= 8'd0;
		end
		else
			if(~&{phy_wait})
				phy_wait <= phy_wait + 8'd1;
			else
				if(~i_phy_ctr_waitreqest) begin
					if(phy_state != 4'd8) begin
						if(~&{phy_state})
							phy_state <= phy_state + 4'd1;
					end 
					else
						if(~(i_phy_ctr_rd_data & 32'h8000))
							phy_state <= phy_state + 4'd1;
				end
	end
	
	phy_init_probe(.probe({4'd0, phy_state}));

	// src_mac = {8'h00, 8'h23, 8'h54, 8'h3C, 8'h47, 8'h1B};
	always begin
		phy_ctr_addr = 8'd0;
		phy_ctr_wr_data = 32'h00000000;
		phy_ctr_wr = 1'b0;
		phy_ctr_rd = 1'b0;
		
		case(phy_state)
			4'd0: begin
				phy_ctr_addr = 8'd02;
				phy_ctr_wr_data = 32'h00000000;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end				
			4'd1: begin
				phy_ctr_addr = 8'd03;
				// phy_ctr_wr_data = 32'h11362200;
				phy_ctr_wr_data = 32'h3C542300;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end
			4'd2: begin
				phy_ctr_addr = 8'd04;
				phy_ctr_wr_data = 32'h00001B47;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end
			4'd3: begin
				phy_ctr_addr = 8'h0F;
				phy_ctr_wr_data = 32'h00000000;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end			
			4'd4: begin
				phy_ctr_addr = 8'h10;
				phy_ctr_wr_data = 32'h00000001;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end			
				
			// Software RESET
			//IOWR(ETH_TSE_BASE, 0x80, IORD(ETH_TSE_BASE, 0x80) | 0x8000);
			4'd5: begin	
				phy_ctr_addr = 8'h80;
				phy_ctr_wr = 1'b0;
				phy_ctr_rd = 1'b1;
			end				
			4'd6: begin
				phy_ctr_addr = 8'h80;
				phy_ctr_wr_data = i_phy_ctr_rd_data | 32'h8000;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end
			
			// Wait for wakeup after reset
			//while (IORD(ETH_TSE_BASE, 0x80) & 0x8000) __asm("NOP");
			4'd7: begin
				phy_ctr_addr = 8'h80;
				phy_ctr_wr = 1'b0;
				phy_ctr_rd = 1'b1;
			end
			
			4'd8: begin
				if(i_phy_ctr_rd_data & 32'h8000) begin
					phy_ctr_addr = 8'h80;
					phy_ctr_wr = 1'b0;
					phy_ctr_rd = 1'b1;
				end 
				else begin
					phy_ctr_addr = 8'h02; //IOWR(ETH_TSE_BASE, 2, IORD(ETH_TSE_BASE, 2) | 0x00000003); // TX_ENA & RX_ENA & 1GBit
					phy_ctr_wr = 1'b0;
					phy_ctr_rd = 1'b1;
				end
			end
					
			4'd9: begin	
				phy_ctr_addr = 8'h02;
				phy_ctr_wr_data = 32'h13; //i_phy_ctr_rd_data | 32'h00000003 | 32'h00000010;
				phy_ctr_wr = 1'b1;
				phy_ctr_rd = 1'b0;
			end			

			default: begin
				phy_ctr_wr = 1'b0;
				phy_ctr_rd = 1'b0;
			end
		endcase
	end

	//----------------------------------------------------------------------------

endmodule
