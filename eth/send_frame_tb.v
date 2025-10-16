module packet_sender_tb;

	initial begin
		`ifdef TESTMODE
			$display("Defined TESTMODE...");
		`endif
		$dumpfile("dumpfile_send_frame.vcd");
		$dumpvars(0);
	end

	reg			[0:0]			clk;
	reg			[0:0]			rst_n;
	initial begin
		rst_n <= 1'b0;
		clk <= 1'b0;
		#5
		rst_n <= 1'b1;
		forever begin
			#10
			clk <= ~clk;
		end
	end

	initial begin
		$display("start...");
		#1000000
		$finish();
	end
	
	reg			[0:0]			sys_clk;
	initial begin 
		sys_clk <= 1'b0;
		forever begin
			#3
			sys_clk <= ~sys_clk;
		end
	end
			
	reg			[0:0]			rdy;
	initial begin
		rdy <= 1'b1;
		#1074
		rdy <= 1'b0;
		#30
		rdy <= 1'b1;
		#80
		rdy <= 1'b0;
		#30
		rdy <= 1'b1;
	end
	
	reg			[0:0]			vld;
	initial begin
		vld <= 1'b1;
		#1120
		vld <= 1'b0;
		#30
		vld <= 1'b1;
		#40
		vld <= 1'b0;
		#30
		vld <= 1'b1;
	end
	
	reg			[0:0]			sync;
	initial begin
		sync <= 1'b0;
		#2000
		sync <= 1'b1;
		#50
		sync <= 1'b0;
	end
	
	reg			[0:0]			prev_sync;
	initial prev_sync <= 1'b0;
	always @ (posedge clk) prev_sync <= sync;
	
	reg			[7:0]			out_cntr;
	initial out_cntr <= {8{1'b1}};
	
	reg			[0:0]			send_arp;
	reg			[0:0]			send_ping;
	reg			[0:0]			send_udp;
	reg			[15:0]			pkt_type;
		
	initial begin
		pkt_type <= 16'h0806;
		
		send_arp <= 1'b0;
		send_ping <= 1'b0;
		send_udp <= 1'b0;
		
		#50
		send_arp <= 1'b1;
		#20
		send_arp <= 1'b0;
		#40000
		
		send_udp <= 1'b1;
		#20
		send_udp <= 1'b0;		
		#40000
		
		//pkt_type <= 16'h0800;
				
		send_ping <= 1'b1;
		#20
		send_ping <= 1'b0;
		
	end
	
	always @ (posedge clk)
		if(send_arp) //~prev_sync & sync)
			out_cntr <= 8'd0;
		else
			if(send_ping)
				out_cntr <= 8'd20;
			else
				if(send_udp)
					out_cntr <= 8'd50;
				else
					case(out_cntr)
						8'd10: out_cntr <= {8{1'b1}};
						8'd44: out_cntr <= {8{1'b1}};
						8'd92: out_cntr <= {8{1'b1}};
						default:
							out_cntr <= ~&{out_cntr} ? out_cntr + 1'd1 : out_cntr;
					endcase
			
	parameter	[15:0]			arp_opcode = 16'h0001;	// ARP REQ
	
	parameter	[31:0]			arp_hdr1 = {16'h0001, 16'h0800},	// Ethernet=0x0001 IPv4=0x0800
								arp_hdr2 = {8'h6, 8'h4, arp_opcode};// HW_SIZE=0x06 PHY_SIZE=0x04 ARP_REQ=0x0001			
								
	parameter	[47:0]			self_mac = {8'h00, 8'h22, 8'h36, 8'hEC, 8'h04, 8'h01};
	parameter	[31:0]			self_ip = {8'd10, 8'd0, 8'd0, 8'd20};//{8'd192, 8'd168, 8'd1, 8'd202};
	
	parameter	[47:0]			dst_mac = {48{1'b1}};
	parameter	[47:0]			src_mac = 48'h3CF011B2523C;
	
	parameter	[47:0]			arp_sha = 48'h3CF011B2523C;
	parameter	[31:0]			arp_spa = {8'd192, 8'd168, 8'd1, 8'd46};
	parameter	[47:0]			arp_tha = {48{1'b0}};
	parameter	[31:0]			arp_tpa = self_ip; //{32{1'b0}};

			
	wire		[31:0]			eth_data;
	assign eth_data = 
		// ARP Reqest
		out_cntr == 8'd00 ? {16'd0, dst_mac[47:32]} :
		out_cntr == 8'd01 ? dst_mac[31:0] :
		out_cntr == 8'd02 ? src_mac[47:16] :
		out_cntr == 8'd03 ? {src_mac[15:0], pkt_type} :
		out_cntr == 8'd04 ? arp_hdr1 :
		out_cntr == 8'd05 ? arp_hdr2 :
		out_cntr == 8'd06 ? arp_sha[47:16] :
		out_cntr == 8'd07 ? {arp_sha[15:0], arp_spa[31:16]} :
		out_cntr == 8'd08 ? {arp_spa[15:0], arp_tha[47:32]} :
		out_cntr == 8'd09 ? arp_tha[31:0] :
		out_cntr == 8'd10 ? arp_tpa : 

		// PING Request
		out_cntr == 8'd20 ? 32'h00000022 :	// dst MAC
		out_cntr == 8'd21 ? 32'h36ec0401 :	// dst_mac
		out_cntr == 8'd22 ? 32'h0c54a531 :	// dst_mac src_mac
		out_cntr == 8'd23 ? 32'h24850800 :	// src_mac pkt_type=0800 (IPv4)
		out_cntr == 8'd24 ? 32'h45000054 :	// ver=4, len=5(5*4=20 byte header), DSCP=0x00, total_len=0x0054 (84 byte)
		out_cntr == 8'd25 ? 32'h41694000 :  // id =0x4169 flags = 0x4000
		out_cntr == 8'd26 ? 32'h4001e516 :	// TTL=0x40 (64) Protocol=0x01 hdr_crc=e516
		out_cntr == 8'd27 ? 32'h0a000016 :	// src_ip = 10.0.0.22
		out_cntr == 8'd28 ? 32'h0a000014 :	// dst_ip = 10.0.0.20
		out_cntr == 8'd29 ? 32'h080082af :	// icmp_type=0x08 icmp_code = 0x00 icmp_crc=0x82af
		out_cntr == 8'd30 ? 32'h148645c1 :	// icmp_id=0x1486 icmp_seq_num=0x45c1
		out_cntr == 8'd31 ? 32'h5522b660 :	// timestamp
		out_cntr == 8'd32 ? 32'h00000000 :	// timestamp
		out_cntr == 8'd33 ? 32'h4eb30200 :	// payload
		out_cntr == 8'd34 ? 32'h00000000 :
		out_cntr == 8'd35 ? 32'h10111213 :
		out_cntr == 8'd36 ? 32'h14151617 :
		out_cntr == 8'd37 ? 32'h18191a1b :
		out_cntr == 8'd38 ? 32'h1c1d1e1f :
		out_cntr == 8'd39 ? 32'h20212223 :
		out_cntr == 8'd40 ? 32'h24252627 :
		out_cntr == 8'd41 ? 32'h28292a2b :
		out_cntr == 8'd42 ? 32'h2c2d2e2f :
		out_cntr == 8'd43 ? 32'h30313233 :
		out_cntr == 8'd44 ? 32'h34353637 : 
		
		// UDP Packet
		out_cntr == 8'd50 ? 32'h00000022 : 
		out_cntr == 8'd51 ? 32'h36ec0401 : 
		out_cntr == 8'd52 ? 32'h0c54a531 : 
		out_cntr == 8'd53 ? 32'h24850800 : 
		out_cntr == 8'd54 ? 32'h4500009c : 
		out_cntr == 8'd55 ? 32'hdc364000 : 
		out_cntr == 8'd56 ? 32'h401149f1 : 
		out_cntr == 8'd57 ? 32'h0a000016 :
		out_cntr == 8'd58 ? 32'h0a000014 :
		out_cntr == 8'd59 ? 32'h11225152 :
		out_cntr == 8'd60 ? 32'h008814c3 :
		out_cntr == 8'd61 ? 32'h2c270055 :
		out_cntr == 8'd62 ? 32'h00000000 :
		out_cntr == 8'd63 ? 32'h00000000 :
		out_cntr == 8'd64 ? 32'h00000000 :
		out_cntr == 8'd65 ? 32'h00000000 :
		out_cntr == 8'd66 ? 32'h00000000 :
		out_cntr == 8'd67 ? 32'h00000000 :
		out_cntr == 8'd68 ? 32'h00000000 :
		out_cntr == 8'd69 ? 32'h00000000 :
		out_cntr == 8'd70 ? 32'h00000000 :
		out_cntr == 8'd71 ? 32'h00000000 :
		out_cntr == 8'd72 ? 32'h00000000 :
		out_cntr == 8'd73 ? 32'h00000000 :
		out_cntr == 8'd74 ? 32'h00000000 :
		out_cntr == 8'd75 ? 32'h00000000 :
		out_cntr == 8'd76 ? 32'h00000000 :
		out_cntr == 8'd77 ? 32'h00000000 :
		out_cntr == 8'd78 ? 32'h00000000 :
		out_cntr == 8'd79 ? 32'h00000000 :
		out_cntr == 8'd80 ? 32'h00000000 : 
		out_cntr == 8'd81 ? 32'h00000000 :
		out_cntr == 8'd82 ? 32'h00000000 :
		out_cntr == 8'd83 ? 32'h00000000 :
		out_cntr == 8'd84 ? 32'h00000000 :
		out_cntr == 8'd85 ? 32'h00000000 :
		out_cntr == 8'd86 ? 32'h00000000 :
		out_cntr == 8'd87 ? 32'h00000000 :
		out_cntr == 8'd88 ? 32'h00000000 :
		out_cntr == 8'd89 ? 32'h00000000 :
		out_cntr == 8'd90 ? 32'h00000000 :
		out_cntr == 8'd91 ? 32'h00000000 :
		out_cntr == 8'd92 ? 32'h00000000 :
							32'hXXXXXXXX;
		
	wire						eth_sp;
	assign eth_sp = ~|{out_cntr} || out_cntr == 8'd20 || out_cntr == 8'd50 ? 1'b1 : 1'b0;
	 
	wire						eth_ep;
	assign eth_ep = out_cntr == 8'd10 || out_cntr == 8'd44 || out_cntr == 8'd92 ? 1'b1 : 1'b0;
	
	wire						eth_vld;
	assign eth_vld = (out_cntr >= 8'd0 && out_cntr <= 8'd10) 
					|| (out_cntr >= 8'd20 && out_cntr <= 8'd44) 
					|| (out_cntr >= 8'd50 && out_cntr <= 8'd92) ? 1'b1 : 1'b0;
	
	wire						eth_rdy;

//	send_frame send_frame_unit(
//		.rst_n(rst_n),
//		.clk(clk),
//		
//		.i_sync(sync),
//		
//		.i_self_mac(self_mac),
//		.i_self_ip(self_ip),
//		
//		.i_in_data(eth_data),
//		.i_in_sp(eth_sp),
//		.i_in_ep(eth_ep),
//		.i_in_vld(eth_vld)
//	);
	
	wire						in_rdy;
	packet_sender packet_sender_unit(
		.clk(clk),
		.rst_n(rst_n),
		
		.i_sync(sync),
		
		.i_rx_data(eth_data),
		.i_rx_sop(eth_sp),
		.i_rx_eop(eth_ep),
		.i_rx_vld(eth_vld),
		.o_rx_rdy(eth_rdy),
		
		.i_tx_rdy(1'b1),
		
		.i_in_vld(1'b1),
		.o_in_rdy(in_rdy),
		
		.i_udp_pkt_len(16'd2048)
	);
	
	reg			[15:0]			pkt_len;
	always @ (posedge clk or negedge rst_n)
		if(~rst_n)
			pkt_len <= 16'hFFFF;
		else
			if(sync)
				pkt_len <= 16'd0;
			else
				pkt_len <= in_rdy ? pkt_len + 1'd1 : pkt_len;
		
endmodule

