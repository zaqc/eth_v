CC = iverilog
FLAGS = -Wall -Winfloop -g2005-sv -DTESTMODE=1

TARGET = send_frame

SRC = $(TARGET)_tb.v cmd_parser.v eth_pkt_type.v packet_sender.v packet_param.v eth_parser.v send_ping_resp.v send_udp_pkt.v send_arp_pkt.v send_ip_frame.v eth_switch_output.v ping_payload.v rise_detector.v

$(TARGET) : $(SRC) Makefile
	$(CC) $(FLAGS) -o $(TARGET) $(SRC)
	vvp $(TARGET)
	gtkwave dumpfile_$(TARGET).vcd cfg_$(TARGET).gtkw
	rm -f $(TARGET)

wave:
	gtkwave dumpfile_$(TARGET).vcd cfg_$(TARGET).gtkw
	
edit:
	gedit -s $(SRC) Makefile &
	
clean:
	rm -f $(TARGET)

