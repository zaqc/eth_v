module eth_parser(
	input						rst_n,
	input						clk,
		
	input		[31:0]			i_self_ip,
	input		[47:0]			i_self_mac,
		
	input		[31:0]			i_in_data,
	input						i_in_sop,
	input						i_in_eop,
	input						i_in_vld,
	output						o_in_rdy,
		
	output						o_arp_req_flag,		// the flag will be set when an ARP REQUEST is received
	output		[47:0]			o_arp_req_mac,
	output		[31:0]			o_arp_req_ip,			
	input						i_clear_arp_req,	// clear flag when sending ARP RESPONSE
	
	output						o_ping_req_flag,
	output		[47:0]			o_ping_req_mac,
	output		[31:0]			o_ping_req_ip,
	output		[31:0]			o_ping_req_data,
	input						i_ping_req_rdy,
	output		[7:0]			o_payload_size,	
	input						i_clear_ping_req,	// clear flag when sending PING RESPONSE
	
	output		[31:0]			o_def_addr,
	output		[31:0]			o_def_data,
	output						o_def_wren,
	input						i_def_rdy,
	
	output		[31:0]			o_vrc_data,
	output		[5:0]			o_vrc_addr,
	output		[1:0]			o_vrc_wren
);

	assign o_arp_req_flag = arp_req_flag;
	assign o_arp_req_mac = arp_req_mac;
	assign o_arp_req_ip = arp_req_ip;
	
	assign o_ping_req_flag = ping_req_flag;
	assign o_ping_req_mac = ping_req_mac;
	assign o_ping_req_ip = ping_req_ip;
	
	assign o_def_addr = def_addr;
	assign o_def_data = def_data;
		
	assign o_in_rdy = ~rst_n ? 1'b0 : 1'b1;
								
	reg			[4:0]			recv_state;
	initial recv_state = 5'd0;
	
	reg			[47:0]			dst_mac;
	reg			[47:0]			src_mac;
	reg			[15:0]			pkt_type;
	reg			[31:0]			arp_hdr1;
	reg			[31:0]			arp_hdr2;
	reg			[15:0]			opcode;
	
	reg			[47:0]			sha;
	reg			[31:0]			spa;
	reg			[47:0]			tha;
	reg			[31:0]			tpa;
	
	// IP_HEADER 1
	reg			[3:0]			ip_ver;
	reg			[3:0]			ip_len;
	reg			[7:0]			ip_DSCP_ECN;
	reg			[15:0]			ip_total_len;
	
	// IP_HEADER 2
	reg			[15:0]			ip_pkt_id;
	reg			[2:0]			ip_pkt_flags;
	reg			[12:0]			ip_frame_offset;
	
	// IP_HEADER 3
	reg			[7:0]			ip_TTL;
	reg			[7:0]			ip_protocol;
	reg			[15:0]			ip_hdr_crc;
		
	reg			[31:0]			src_ip;
	reg			[31:0]			dst_ip;
	
	reg			[15:0]			udp_src_port;
	reg			[15:0]			udp_dst_port;
	reg			[15:0]			udp_data_len;
	reg			[15:0]			udp_data_crc;
	
	reg			[7:0]			icmp_type;
	reg			[7:0]			icmp_code;
	reg			[15:0]			icmp_crc;
	reg			[15:0]			icmp_id;
	reg			[15:0]			icmp_seq;
	
	reg			[31:0]			tmp_def_addr;
	reg			[31:0]			tmp_def_data;
	
	reg			[6:0]			vrc_addr;
	assign o_vrc_addr = vrc_addr[5:0];
	assign o_vrc_data = i_in_data;
	assign o_vrc_wren = ~vrc_addr[6] && recv_state == RS_FILL_VRCH /*5'd26*/ && i_in_vld ? 
				tmp_def_data[7:0] == 8'h0F ? 2'b10 : 
				tmp_def_data[7:0] == 8'hF0 ? 2'b01 : 2'b00 : 2'b00;
		
	always @ (posedge clk)
		if(i_in_vld) begin
			case(recv_state)
				// Ethernet header
				5'd00: dst_mac[47:32] <= i_in_sop ? i_in_data[15:0] : dst_mac[47:32];
				5'd01: dst_mac[31:0] <= i_in_data;
				5'd02: src_mac[47:16] <= i_in_data;
				5'd03: {src_mac[15:0], pkt_type} <= i_in_data;
				
				// ARP
				5'd04: arp_hdr1 <= i_in_data;
				5'd05: arp_hdr2 <= i_in_data;
				5'd06: sha[47:16] <= i_in_data;
				5'd07: {sha[15:0], spa[31:16]} <= i_in_data;
				5'd08: {spa[15:0], tha[47:32]} <= i_in_data;
				5'd09: tha[31:0] <= i_in_data;
				5'd10: tpa <= i_in_data;
				
				// IPv4
				5'd11: {ip_ver, ip_len, ip_DSCP_ECN, ip_total_len} <= i_in_data;
				5'd12: {ip_pkt_id, ip_pkt_flags, ip_frame_offset} <= i_in_data;
				5'd13: {ip_TTL, ip_protocol, ip_hdr_crc} <= i_in_data;
				5'd14: src_ip <= i_in_data;
				5'd15: dst_ip <= i_in_data;
				
				// UDP
				5'd16: {udp_src_port, udp_dst_port} <= i_in_data;
				5'd17: {udp_data_len, udp_data_crc} <= i_in_data;
				
				// ICMP
				5'd18: {icmp_type, icmp_code, icmp_crc} <= i_in_data;
				5'd19: {icmp_id, icmp_seq} <= i_in_data;
				
				// UDP Payload
				5'd24: tmp_def_addr <= i_in_data;
				5'd25: 
					begin
						tmp_def_data <= i_in_data;
						vrc_addr <= 7'd0;
					end
				//5'd26: 
				RS_FILL_VRCH: vrc_addr <= ~vrc_addr[6] ? vrc_addr + 1'd1 : vrc_addr;
				
			endcase
			
			if(i_in_eop) begin					
				dst_mac <= 48'd0;
				src_mac <= 48'd0;

				arp_hdr1 <= 32'd0;
				arp_hdr2 <= 32'd0;
				sha <= 48'd0;
				spa <= 32'd0;
				tha <= 48'd0;
				tpa <= 32'd0;
				icmp_type <= 8'hFF;
				icmp_code <= 8'hFF;
				
				dst_ip <= 32'd0;
				src_ip <= 32'd0;
				
				ip_protocol <= 8'd0;
				
				pkt_type <= 16'd0;
			end
		end
			
	parameter	[4:0]			RS_WAIT_SOP =5'd0,
								RS_MAC_ADDR = 5'd1,
								RS_PKT_TYPE = 5'd3,
								RS_ARP_PKT = 5'd10,
								RS_UDP_ICMP = 5'd15,
								RS_UDP_PORT = 5'd17,
								RS_ICMP_PAYLOAD = 5'd20,
								RS_UDP_VRCH_HDR = 5'd25,
								RS_FILL_VRCH = 5'd26,
								RS_UDP_COMMAND = 5'd27;
			
	ping_payload ping_payload_unit(
		.rst_n(rst_n),
		.clk(clk),
		
		.i_start(recv_state == 5'd18),
		.i_eop(recv_state == RS_ICMP_PAYLOAD /*5'd20*/ && i_in_vld && i_in_eop),
		
		.i_in_data(i_in_data),
		.i_wren(recv_state >= 5'd18 && recv_state <= 5'd20 && i_in_vld),
		
		.o_payload_size(o_payload_size),
		.o_out_data(o_ping_req_data),
		.i_out_rdy(i_ping_req_rdy)
	);
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			recv_state <= 5'd0;
		else			
			if(i_in_vld)
				if(i_in_eop)
					recv_state <= 5'd0;
				else
					case(recv_state)
						// 5'd00: 
						RS_WAIT_SOP: recv_state <= i_in_sop ? 4'd01 : recv_state;
						
						// 5'd01: 
						RS_MAC_ADDR: recv_state <= {dst_mac[47:32], i_in_data} == i_self_mac || 
												&{dst_mac[47:32], i_in_data} ? 5'd2 : 5'h1F;
																		
						// 5'd03: 
						RS_PKT_TYPE: recv_state <= i_in_data[15:0] == 16'h0806 ? 5'd04 : 
											 i_in_data[15:0] == 16'h0800 ? 5'd11 : 5'h1F;
											 
						// 5'd10: 
						RS_ARP_PKT: recv_state <= 5'h1F;
						
						// 5'd15: 	
						RS_UDP_ICMP:
							case(ip_protocol)
								8'd01: recv_state <= 5'd18;	// ICMP
								8'd17: recv_state <= 5'd16;	// UDP
								default: recv_state <= 5'h1F;
							endcase
							
						// 5'd17:
						RS_UDP_PORT: recv_state <= (udp_src_port == 16'd14057 && udp_dst_port == 16'd17814) ? 5'd24 : 5'h1F;
						
						// 5'd25:
						RS_UDP_VRCH_HDR: recv_state <= (tmp_def_addr == 32'hAA0FF055 && tmp_def_data[31:8] == 24'hACCA55) ? RS_FILL_VRCH /*5'd26*/ : RS_UDP_COMMAND /*5'h27*/;
						
						default: // recv_state 5'd20 - receive ICMP Ping Payload
							recv_state <= ~&{recv_state} 
									&& recv_state != RS_ICMP_PAYLOAD /*5'd20*/
									&& recv_state != RS_FILL_VRCH /*5'd26*/
									&& recv_state != RS_UDP_COMMAND /*5'd27*/ ? recv_state + 1'd1 : recv_state;
					endcase

	reg			[0:0]			arp_req_flag;
	reg			[47:0]			arp_req_mac;
	reg			[31:0]			arp_req_ip;
		
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) 
			arp_req_flag <= 1'd0;
		else
			if(i_in_vld & i_in_eop && pkt_type == 16'h0806 && 
					arp_hdr1 == 32'h00010800 && arp_hdr2 == 32'h06040001 && 
					((recv_state == RS_ARP_PKT /*4'd10*/ && i_in_data == i_self_ip) ||
					(&{recv_state} && tpa == i_self_ip))) begin
				arp_req_flag <= 1'b1;
				arp_req_mac <= sha;
				arp_req_ip <= spa;				
			end
			else
				if(i_clear_arp_req)
					arp_req_flag <= 1'b0;
					
	reg			[0:0]			udp_cmd_flag;
	reg			[31:0]			def_addr;
	reg			[31:0]			def_data;
	reg			[0:0]			def_wren;
	
	always @ (posedge clk or negedge rst_n)
		if(~rst_n) 
			def_wren <= 1'd0;
		else
			if(i_in_vld & i_in_eop && recv_state == RS_UDP_COMMAND /*5'd27*/) begin
				def_wren <= 1'b1;
				def_addr <= tmp_def_addr;
				def_data <= tmp_def_data;
			end
			else
				if(i_def_rdy)
					def_wren <= 1'b0;
					
	assign o_def_wren = def_wren;
			
	reg			[0:0]			ping_req_flag;
	reg			[47:0]			ping_req_mac;
	reg			[31:0]			ping_req_ip;

	always @ (posedge clk or negedge rst_n)
		if(~rst_n) 
			ping_req_flag <= 1'd0;
		else					
			if(i_in_vld & i_in_eop && pkt_type == 16'h0800 && ip_protocol == 8'h01 &&	// ICMP
					icmp_type == 8'd8 && icmp_code == 8'd0 &&
					dst_mac == i_self_mac && dst_ip == i_self_ip) begin
					
				ping_req_flag <= 1'b1;
				ping_req_mac <= src_mac;
				ping_req_ip <= src_ip;								
			end
			else
				if(i_clear_ping_req)
					ping_req_flag <= 1'b0;
		
endmodule

