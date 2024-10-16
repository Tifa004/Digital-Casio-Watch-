module casio_tb ();

reg clk,rst;
reg Mode;
reg toggle,confirm;
reg [4:0] compare_hours;
reg [5:0]compare_minutes;
wire [4:0] hours;
wire [5:0] minutes,LapM,LapS;
wire ring;

localparam clockP=8;

casio U0(clk,rst,toggle,confirm,Mode,hours ,minutes,ring,LapM,LapS);


always @* begin
	if (minutes<10 && hours<10) begin
 				$display("0%0d:0%0d",hours,minutes);
 			end else if (minutes<10)
 				$display("%0d:0%0d",hours,minutes);
 			else if (hours<10) begin
 				$display("0%0d:%0d",hours,minutes);
 			end else
 				$display("%0d:%0d",hours,minutes);
end

initial begin
	clk=0;
	forever #4 clk=~clk ;
end



initial begin
reset();

initialize();

//Test 1 Normal Time
check_time(0,0,0);

//Test 2 Setting an Alarm
repeat(2)
	mode_button();
repeat(3) begin
	confirm_button();
end
repeat(2) begin
	toggle_button();
end
check_ring(1);
confirm_button();
repeat(2)
	mode_button();
check_ring(0);
//This should ring at 00:02


//Test 3 Set time 

//we increment the hours
compare_hours=(hours+10)%20;
compare_hours=(compare_hours+7)%24;
compare_minutes=(minutes+9)%10;
compare_minutes=(compare_minutes+30)%60;
mode_button();
toggle_button();//toggle leftmost digit 1
confirm_button();
repeat(7) begin // toggle second leftmost digit 7 
	toggle_button();
end
confirm_button();

repeat(3) begin
	toggle_button(); //toggle second rightmost digit 3
end
confirm_button();

repeat(9) begin
	toggle_button(); //toggle rightmost digit 9 times
end

confirm_button();
repeat(3)
	mode_button();
check_time(U0.seconds,compare_minutes,compare_hours);


//Test 4 StopWatch
repeat(3)
	mode_button();
toggle_button(); //stopwatch should run
check_stopwatch(1,1,0,0);

repeat(50)
	@(posedge clk);
toggle_button();
confirm_button();
check_stopwatch(0,1,0,0);


 $dumpfile("waveform.vcd");
 $stop;
end
task initialize;
	begin
	Mode=0;
	confirm=0;
	toggle=0;
end
endtask

task reset;
	begin
	rst=0;
	#(clockP/4) 
	rst=1;
end
endtask 

task mode_button;
	begin
	@(negedge clk);
	Mode=1;
	@(negedge clk);
	Mode=0;
	end
endtask

task confirm_button;
	begin
	@(negedge clk);
	confirm=1;
	@(negedge clk);
	confirm=0;
	end
endtask 

task toggle_button;
	begin
	@(negedge clk);
	toggle=1;
	@(negedge clk);
	toggle=0;
	end
endtask

task check_time;
input [5:0] secondsTB,minutesTB;
input [4:0] hoursTB;
begin
     repeat(60) begin
     	@(posedge clk)
            if (secondsTB < 59) begin
                secondsTB = secondsTB + 1;
            end else if (minutesTB < 59) begin
                minutesTB = minutesTB + 1;
                secondsTB = 0;
            end else begin
                minutesTB = 0;
                hoursTB = hoursTB + 1;
            end
            if (hoursTB == 24)
                hoursTB = 0;
       	@(negedge clk);
				if (hoursTB==hours && minutesTB==minutes)
					$display("Clock's Working Well");
				else
					$display("Repair your Clock %t",$time);
			end
end
endtask

task check_ring ;
reg [4:0] ringH;
reg [5:0] ringM;
input save_or_ring;
begin
	if(save_or_ring) begin
		ringH=hours;
		ringM=minutes;
	end
	else begin
		while(~(ringH==hours && ringM==minutes)) begin
			#1;
		end
	repeat(2)
		@(negedge clk);
	if(ring)
		$display("Wake up");
	else
		$display("You overslept :( ");
	end
end
endtask 

task check_stopwatch;
input toggles;
input confirms;
input[5:0] SW_minutesTB,SW_secondsTB;
reg [5:0] saveM;
reg [5:0] saveS;
begin
     
   
     if (toggles) begin
     	repeat(50) begin
     		 @(posedge clk);
             	if (SW_secondsTB < 59) begin
                	SW_secondsTB = SW_secondsTB + 1;
            	end else begin
                	SW_secondsTB = 0;
                	SW_minutesTB = SW_minutesTB + 1;
            	end
            	if (SW_minutesTB == 60)
                	SW_minutesTB = 0;
            	
		end
				@(negedge clk);
				if (SW_minutesTB==hours && SW_secondsTB==minutes)
					$display("Stopwatch's's working well");
				else
					$display("Repair Stopwatch %t",$time);

            	if(confirms) begin
            		saveS=SW_secondsTB+1;
            		saveM=SW_minutesTB;
            		confirm_button();
            		check_lap(saveM,saveS);
				end
            
      end else
        		if (confirms) begin
        			SW_secondsTB=0;
        			SW_minutesTB=0;
        			 @(negedge clk);
					if (SW_minutesTB==hours && SW_secondsTB==minutes)
						$display("Stopwatch reset well");
					else
						$display("Repair Stopwatch reset %t",$time);
		
        		end
        
end
endtask

task check_lap;
	input[5:0] LAPM,LAPS;
begin
		if (LAPS==LapS && LAPM==LapM)
			$display("Lapped");
		else
			$display("Not Lapped %t",$time);
end
endtask
endmodule 