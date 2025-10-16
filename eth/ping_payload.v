module ping_payload(
	input						rst_n,
	input						clk,
	
	input						i_start,
	input						i_eop,
	
	input		[31:0]			i_in_data,
	input						i_wren,
		
	output		[7:0]			o_payload_size,
	output		[31:0]			o_out_data,
	input						i_out_rdy
);

	reg			[31:0]			mem_buf[0:255];
	
	reg			[7:0]			wr_ptr;
	reg			[7:0]			rd_ptr;
	
	reg			[31:0]			crc;
	
	wire		[15:0]			crc_a1;
	wire		[15:0]			crc_a2;
	
	reg			[7:0]			payload_size;
	assign o_payload_size = payload_size;

	assign crc_a1 = i_in_data[31:16];
	assign crc_a2 = i_in_data[15:0];
	
	reg			[15:0]			checksum;
	
	wire		[31:0]			mem_data; 
	assign mem_data = mem_buf[rd_ptr];
	
	assign o_out_data = ~|{rd_ptr} ? {8'd0, mem_data[23:16], checksum} : mem_buf[rd_ptr];
	
	wire						eop_rise;
	rise_detector eop_rise_detector(.rst_n(rst_n), .clk(clk), .i_signal(i_eop), .o_rise(eop_rise));
	
	wire		[31:0]			next_crc;
	assign next_crc = crc + crc_a1 + crc_a2;
	
	always @ (posedge clk) 
		if(eop_rise) begin
			payload_size <= wr_ptr + 1'd1;
			checksum <= ~crc_sum1[15:0];
		end
		
	always @ (posedge clk)
		if(i_wren) begin
			if(i_start) begin
				mem_buf[8'd0] <= i_in_data;
				crc <= {24'd0, crc_a1[7:0]}; // for debug replase 16'd0 to: crc_a1
				wr_ptr <= 8'd1;
			end
			else begin
				mem_buf[wr_ptr] <= i_in_data;
				crc <= next_crc;
				wr_ptr <= wr_ptr + 8'd1;
			end
		end
			
	wire		[31:0]			crc_sum1;
	assign crc_sum1 = next_crc[31:16] + next_crc[15:0];
	
	wire		[31:0]			crc_sum2;
	assign crc_sum2 = crc_sum1[31:16] + crc_sum1[15:0];
				
	always @ (posedge clk)
		if(i_start)
			rd_ptr <= 8'd0;
		else
			rd_ptr <= i_out_rdy ? rd_ptr + 1'd1 : rd_ptr;
			
	//assign o_out_data = mem_buf[rd_ptr];

endmodule

