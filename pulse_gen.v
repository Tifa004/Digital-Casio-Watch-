module pulse_gen (
	input bus_enable,
	input clk,rst,
	output reg enable
	
);

reg after_FF;

always @(posedge clk or negedge rst) begin 
	if(~rst) begin
		 after_FF<= 0;
	end else begin
		 after_FF<=bus_enable;
	end
end

always @* begin 
	enable=bus_enable&~after_FF;
end

endmodule 