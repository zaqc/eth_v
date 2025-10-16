module packet_param(
	input						rst_n,
	input						clk,
	
	input		[7:0]			i_eb_addr,
	input		[31:0]			i_eb_wr_data,
	input						i_eb_wr,

	output		[47:0]			o_self_mac,
	output		[31:0]			o_self_ip,

	output		[47:0]			o_mcast_mac,
	output		[31:0]			o_mcast_ip,
	
	output		[15:0]			o_udp_src_port,
	output		[15:0]			o_udp_dst_port,
		
	output		[15:0]			o_udp_pkt_len,
	output		[15:0]			o_udp_start_addr
);

	reg			[47:0]			self_mac;
	reg			[31:0]			self_ip;

	reg			[47:0]			mcast_mac;
	reg			[31:0]			mcast_ip;
	
	reg			[15:0]			udp_src_port;
	reg			[15:0]			udp_dst_port;
	reg			[15:0]			udp_pkt_len;
	reg			[15:0]			udp_start_addr;
	
	assign o_self_mac = self_mac;
	assign o_self_ip = self_ip;
	
	assign o_mcast_mac = mcast_mac;
	assign o_mcast_ip = mcast_ip;
			
	assign o_udp_dst_port = udp_dst_port;
	assign o_udp_src_port = udp_src_port;

	assign o_udp_pkt_len = udp_pkt_len;
	assign o_udp_start_addr = udp_start_addr;
					
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) begin			
			self_mac <= {8'h00, 8'h22, 8'h36, 8'hEC, 8'h04, 8'h01};
			self_ip <= {8'd10, 8'd0, 8'd0, 8'd20}; // {8'd192, 8'd168, 8'd1, 8'd202}; 
			
			mcast_mac <= {8'h01, 8'h00, 8'h5e, 8'h4d, 8'hec, 8'h06};
			mcast_ip = {8'd224, 8'd77, 8'd236, 8'd6};
			
			udp_src_port <= 16'h5152;
			udp_dst_port <= 16'h2179;			
			udp_pkt_len <= 16'd2000;
			udp_start_addr <= 16'd0;			
		end
		else
			if(i_eb_wr) begin
				case(i_eb_addr[3:0])
					4'h1: self_mac[47:16] <= i_eb_wr_data;
					4'h2: self_mac[15:0] <= i_eb_wr_data[15:0];
					4'h3: self_ip <= i_eb_wr_data;
					
					4'h4: mcast_mac[47:16] <= i_eb_wr_data;
					4'h5: mcast_mac[15:0] <= i_eb_wr_data[15:0];
					4'h6: mcast_ip <= i_eb_wr_data;
										
					4'h7: udp_src_port <= i_eb_wr_data[15:0];
					4'h8: udp_dst_port <= i_eb_wr_data[15:0];
					4'h9: udp_pkt_len <= i_eb_wr_data[15:0];
					4'hA: udp_start_addr <= i_eb_wr_data[15:0];
				endcase
			end
endmodule
