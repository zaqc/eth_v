module gmac_init_tb;

	reg			[0:0]			rst_n;
	reg			[0:0]			sys_clk;
	reg			[0:0]			pll_lock;
	
	initial begin
		$display("Start...");
		$display(`TARGET_NAME);
		//$dumpfile("dumpfile_sdrc.vcd");
		$dumpfile({"dumpfile_", `TARGET_NAME, ".vcd"});
		$dumpvars(0);
		pll_lock <= 1'b0;
		rst_n <= 1'b0;
		#10
		rst_n <= 1'b1;
		#10
		pll_lock <= 1'b1;
		#3000000
		$finish();
	end
	
	initial begin
		sys_clk <= 1'b0;
		forever begin
			#5
			sys_clk <= ~sys_clk;
		end
	end
	
	reg			[0:0]			us_clk;
	initial begin
		us_clk <= 1'b0;
		forever begin
			#37
			us_clk <= ~us_clk;
		end
	end
	
	reg			[0:0]			sync;
	initial begin
		sync <= 1'b0;
		#50
		@ (negedge sys_clk) sync <= 1'b1;
		#20
		@ (negedge sys_clk) sync <= 1'b0;
		#140000
		@ (negedge sys_clk) sync <= 1'b1;
		#20
		@ (negedge sys_clk) sync <= 1'b0;
	end
	
	wire						st_vld;
	
	reg			[0:0]			rdy;
	initial begin
		rdy <= 1'b1;
		#10100
		rdy <= 1'b0;
		#1000
		rdy <= 1'b1;
	end
	
	reg			[31:0]			rnd;
	initial rnd <= 32'd0;
	
	always @ (posedge sys_clk)
		rnd <= {rnd[30:0], ~(rnd[31] ^ rnd[17] ^ rnd[11] ^ rnd[3] ^ rnd[1])};

	gmac_init gmac_init_unit(
		.rst_n(rst_n),
		.clk(sys_clk),
		
		.i_rd_data(32'h0000),
		
		.i_wtrq(1'b0)
	);
	
endmodule
