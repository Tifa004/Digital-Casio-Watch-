module casio (
    input clk, rst, toggle_not_pulse, confirm_not_pulse,
    input  Mode_not_pulse,
    output reg [4:0] H,
    output reg [5:0] M,
    output reg Ring,
    output reg [5:0] Lap_min, Lap_sec
);
    
    wire Mode;
    reg [4:0] H_alarm;
    reg [5:0] M_alarm;
    reg [1:0] Current_state;
    reg [1:0] Next_state;
    reg [1:0] counter;
    reg [4:0] hours;
    reg [5:0] minutes;
    reg [5:0] seconds;
    reg [5:0] minutes_stopwatch;
    reg [5:0] seconds_stopwatch;
    reg [1:0] location, locationA;
    reg [4:0] h1, h1_alarm;
    reg [3:0] h2, h2_alarm;
    reg [5:0] m1, m1_alarm;
    reg [3:0] m2, m2_alarm;
    reg start_stop_flag,Alarm_Set;

    pulse_gen pulgM(

        .bus_enable(Mode_not_pulse),
        .clk(clk),
        .rst(rst),
        .enable(Mode)
    );

    pulse_gen pulgT(

        .bus_enable(toggle_not_pulse),
        .clk(clk),
        .rst(rst),
        .enable(toggle)
    );

    pulse_gen pulgC(

        .bus_enable(confirm_not_pulse),
        .clk(clk),
        .rst(rst),
        .enable(confirm)
    );

    localparam H1=0;
    localparam H2=1;
    localparam M1=2;
    localparam M2=3;

    localparam Normal=0;
    localparam Set_Time=1;
    localparam Alarm=2;
    localparam Stop_Watch=3;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            H <= 0;
            M <= 0;
            Ring <= 0;
            H_alarm <= 0;
            M_alarm <= 0;
            location <= H1;
            locationA <= H1;
            counter <= 0;
            Current_state <= Normal;
            hours <= 0;
            minutes <= 0;
            seconds <= 0;
            minutes_stopwatch <= 0;
            seconds_stopwatch <= 0;
            h1 <= 0;
            h2 <= 0;
            m1 <= 0;
            m2 <= 0;
            h1_alarm <= 0;
            h2_alarm <= 0;
            m1_alarm <= 0;
            m2_alarm <= 0;
            start_stop_flag <= 0;
        end else begin
            Current_state <= Next_state;
        end
    end

always @* begin 
	if(Mode && counter!=3)
		counter = counter + 1;
	else if(Mode && counter==3)
		counter = 0;
	else
		counter = counter;

	case (counter)
		
		0: Next_state <= Normal;
		1: Next_state <= Set_Time;
		2: Next_state <= Alarm;
		3: Next_state <= Stop_Watch;
		
	endcase
end
    always @(posedge clk) begin
        if (Current_state == Set_Time) begin
            minutes <= minutes;
            hours <= hours;
            seconds <= 0;
        end else begin
            if (seconds < 59) begin
                seconds <= seconds + 1;
            end else if (minutes < 59) begin
                minutes <= minutes + 1;
                seconds <= 0;
            end else begin
                minutes <= 0;
                hours <= hours + 1;
            end
            if (hours == 24)
                hours <= 0;
        end
    end

    always @(posedge clk) begin
    	 if (Current_state==Stop_Watch &&toggle)
         	start_stop_flag <= ~start_stop_flag; // 1 stopwatch running // 0 pause stopwatch
         else 
         	start_stop_flag <= start_stop_flag;

        if (start_stop_flag) begin
            if (seconds_stopwatch < 59)
                seconds_stopwatch <= seconds_stopwatch + 1;
            else begin
                seconds_stopwatch <= 0;
                if (minutes_stopwatch < 59)
                    minutes_stopwatch <= minutes_stopwatch + 1;
                else
                    minutes_stopwatch <= 0;
            end
        end else if ( ~start_stop_flag) begin
            seconds_stopwatch <= seconds_stopwatch;
            minutes_stopwatch <= minutes_stopwatch;
        end

        if (confirm && start_stop_flag) begin
                    Lap_min = minutes_stopwatch;
                    Lap_sec = seconds_stopwatch;
                end else if (confirm && ~start_stop_flag) begin
                    minutes_stopwatch <= 0;
                    seconds_stopwatch <= 0;
                end
    end

    always @(posedge clk) begin
        if (hours == H_alarm && minutes == M_alarm && Alarm_Set) begin
            Ring <= 1;
            H_alarm <= 0;
            M_alarm <= 0;
        end else
            Ring <= 0;
    end

    always @(Current_state,confirm,toggle,minutes,hours,minutes_stopwatch,seconds_stopwatch) begin
        case (Current_state)
            Normal: begin
                H = hours;
                M = minutes;
                location = H1;
                locationA = H1;
            end

            Set_Time: begin
                locationA = H1;
                case (location)
                    H1: begin
                        if (20 <= H && H <= 29)
                            h1 = 20;
                        else if (10 <= H && H <= 19)
                            h1 = 10;
                        else
                            h1 = 0;

                        h2 = H - h1;

                        if (toggle) begin
                            if (h1 != 20)
                                h1 = h1 + 10;
                            else
                                h1 = 0;
                        end

                        hours = h1 + h2;
                        H = hours == 24 ? 0 : hours;

                        M = minutes;
                        if (confirm)
                            location = H2;
                    end

                    H2: begin
                        h2 = H - h1;

                        if (toggle) begin
                            if (h1 == 20) begin
                                if (h2 != 3)
                                    h2 = h2 + 1;
                                else
                                    h2 = 0;
                            end
                         else begin
                            if (h2 != 9)
                                h2 = h2 + 1;
                            else
                                h2 = 0;
                        end
                    end
                        hours = h1 + h2;
                        H = hours;

                        M = minutes;
                        if (confirm)
                            location = M1;
                    end

                    M1: begin
                        if (50 <= M && M <= 59)
                            m1 = 50;
                        else if (40 <= M && M <= 49)
                            m1 = 40;
                        else if (30 <= M && M <= 39)
                            m1 = 30;
                        else if (20 <= M && M <= 29)
                            m1 = 20;
                        else if (10 <= M && M <= 19)
                            m1 = 10;
                        else
                            m1 = 0;

                        m2 = M - m1;

                        if (toggle) begin
                            if (m1 != 50)
                                m1 = m1 + 10;
                            else
                                m1 = 0;
                        end

                        minutes = m1 + m2;
                        H = hours;
                        M = minutes;

                        if (confirm)
                            location = M2;
                    end

                    M2: begin
                        m2 = M - m1;

                        if (toggle) begin
                            if (m2 != 9)
                                m2 = m2 + 1;
                            else
                                m2 = 0;
                        end

                        minutes = m1 + m2;
                        H = hours;
                        M = minutes;
                        if (confirm)
                            location = H1;
                    end
                endcase
            end

            Alarm: begin
                location = H1;
                case (locationA)
                    H1: begin
                        if (toggle) begin
                            if (h1_alarm != 20)
                                h1_alarm = h1_alarm + 10;
                            else
                                h1_alarm = 0;
                        end

                        H_alarm = h1_alarm + h2_alarm;
                        H = H_alarm;
                        M = M_alarm;
                        if (confirm)
                            locationA = H2;
                    end

                    H2: begin
                        if (toggle) begin
                            if (h1_alarm == 20) begin
                                if (h2_alarm != 3)
                                    h2_alarm = h2_alarm + 1;
                                else
                                    h2_alarm = 0;
                            end
                        else begin
                            if (h2_alarm != 9)
                                h2_alarm = h2_alarm + 1;
                            else
                                h2_alarm = 0;
                        end
                    end
                        H_alarm = (h1_alarm + h2_alarm) == 24 ? 0 : h1_alarm + h2_alarm;
                        H = H_alarm;
                        if (confirm)
                            locationA = M1;
                    end

                    M1: begin
                        if (toggle) begin
                            if (m1_alarm != 50)
                                m1_alarm = m1_alarm + 10;
                            else
                                m1_alarm = 0;
                        end

                        M = m1_alarm + m2_alarm;
                        if (confirm)
                            locationA = M2;
                    end

                    M2: begin
                        if (toggle) begin
                            if (m2_alarm != 9)
                                m2_alarm = m2_alarm + 1;
                            else
                                m2_alarm = 0;
                        end

                        M_alarm = (m1_alarm + m2_alarm) == 60 ? 0 : m1_alarm + m2_alarm;
                        M = M_alarm;
                        if (confirm) begin
                            locationA = H1;
                        	Alarm_Set=1;
                        end
                    end
                endcase
            end

            Stop_Watch: begin
                location = H1;
                locationA = H1;
                H = minutes_stopwatch;
                M = seconds_stopwatch;
            end
        endcase
    end
endmodule




