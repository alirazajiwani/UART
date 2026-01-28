package uart_tb_package;

// CONFIGURATION

class uart_config;
    int SYS_FREQ = 50_000_000;
    int BAUD_RATE = 9600;
    int DATABITS = 8;
    int PARITY_EN = 1;
    int PARITY_TYPE = 0;

    function int get_bit_period();
        return (SYS_FREQ / BAUD_RATE);
    endfunction
endclass

class trans;
    uart_config cfg;
    
    rand bit [7:0] data_sent;
    rand bit parity_error_inject;
    rand bit stop_error_inject;

    bit [7:0] data_got;
    bit parity;
    bit tx_done;
    bit rx_done;
    bit error_flag;

    constraint normal_op {
        parity_error_inject dist {0 := 80, 1 := 20};
        stop_error_inject dist {0 := 80, 1 := 20};
    }
    
    function void post_randomize();
        if (cfg.PARITY_EN) begin
            parity = (cfg.PARITY_TYPE) ? ~(^data_sent) : ^(data_sent);
        end
    endfunction
    
    function void display(string tag);
        if (cfg.PARITY_EN) begin
            $display("[%0t][%s]: Data_Sent=0x%02h, Parity=%0b, ParityErr_Inj=%0b, StopErr_Inj=%0b", 
                $time, tag, data_sent, parity, parity_error_inject, stop_error_inject);
        end else begin
            $display("[%0t][%s]: Data_Sent=0x%02h, StopErr_Inj=%0b", 
                $time, tag, data_sent, stop_error_inject);
        end
    endfunction
    
    function void display_result(string tag);
        $display("[%0t][%s]: Data_Got=0x%02h, TX_Done=%0b, RX_Done=%0b, Error_Flag=%0b",
            $time, tag, data_got, tx_done, rx_done, error_flag);
    endfunction
endclass

// COVERAGE

class coverage;
    uart_config cfg;
    trans tr;
    
    // Coverage group for UART transactions
    covergroup uart_cg;
        
        // Cover all possible data values (sample bins)
        cp_data: coverpoint tr.data_sent {
            bins data_sent = {[8'h00:8'hFF]};
        }
        
        // Cover parity bit values
        cp_parity: coverpoint tr.parity {
            bins even = {0};
            bins odd = {1};
        }
        
        // Cover error injection scenarios
        cp_parity_error: coverpoint tr.parity_error_inject {
            bins no_error = {0};
            bins error_injected = {1};
        }
        
        cp_stop_error: coverpoint tr.stop_error_inject {
            bins no_error = {0};
            bins error_injected = {1};
        }
        
        // Cover received data patterns
        cp_data_received: coverpoint tr.data_got {
            bins data_received = {[8'h00:8'hFF]};
        }
        
        // Cover error flags
        cp_error_flag: coverpoint tr.error_flag {
            bins no_error = {0};
            bins error_detected = {1};
        }
        
        cp_rx_done: coverpoint tr.rx_done {
            bins complete = {1};
        }
        
        // Cross coverage: Data patterns with parity
        cross_data_parity: cross cp_data, cp_parity;
        
        // Cross coverage: Error injection scenarios
        cross_errors: cross cp_parity_error, cp_stop_error {
            bins no_errors = binsof(cp_parity_error.no_error) && 
                            binsof(cp_stop_error.no_error);
            bins parity_only = binsof(cp_parity_error.error_injected) && 
                              binsof(cp_stop_error.no_error);
            bins stop_only = binsof(cp_parity_error.no_error) && 
                            binsof(cp_stop_error.error_injected);
            bins both_errors = binsof(cp_parity_error.error_injected) && 
                              binsof(cp_stop_error.error_injected);
        }
        
        // Cross coverage: Data match and error detection
        cross_data_errors: cross cp_data, cp_error_flag {
            ignore_bins no_match = binsof(cp_error_flag.error_detected);
        }
        
    endgroup
    
    // Coverage group for corner cases
    covergroup corner_cases_cg;
        
        // Consecutive identical bytes
        cp_consecutive_data: coverpoint tr.data_sent {
            bins same_byte[] = ([0:255] => [0:255]);
        }
        
        // Back-to-back transactions (timing coverage)
        cp_transaction_spacing: coverpoint tr.data_sent {
            bins fast_transactions = {[0:255]};
        }
        
    endgroup
    
    // Coverage group for protocol compliance
    covergroup protocol_cg;
        
        // Start bit detection scenarios
        cp_start_detection: coverpoint tr.data_sent {
            bins valid_start = {[0:255]};
        }
        
        // Stop bit scenarios
        cp_stop_bit: coverpoint tr.stop_error_inject {
            bins valid_stop = {0};
            bins invalid_stop = {1};
        }
        
        // Parity checking
        cp_parity_check: coverpoint tr.parity_error_inject {
            bins correct_parity = {0};
            bins incorrect_parity = {1};
        }
        
    endgroup
    
    function new(uart_config cfg);
        this.cfg = cfg;
        uart_cg = new();
        corner_cases_cg = new();
        protocol_cg = new();
    endfunction
    
    // Sample coverage when transaction is sent
    function void sample_tx(trans t);
        this.tr = t;
        uart_cg.sample();
        corner_cases_cg.sample();
        protocol_cg.sample();
    endfunction
    
    // Sample coverage when transaction is received
    function void sample_rx(trans t);
        this.tr = t;
        uart_cg.sample();
    endfunction
    
    // Display coverage report
    function void report();
        real uart_cov, corner_cov, protocol_cov, total_cov;
        
        uart_cov = uart_cg.get_coverage();
        corner_cov = corner_cases_cg.get_coverage();
        protocol_cov = protocol_cg.get_coverage();
        total_cov = (uart_cov + corner_cov + protocol_cov) / 3.0;
        
        $display("\n");
        $display("========================================================");
        $display("              FUNCTIONAL COVERAGE REPORT");
        $display("========================================================");
        $display("UART Coverage         : %.2f%%", uart_cov);
        $display("Corner Cases Coverage : %.2f%%", corner_cov);
        $display("Protocol Coverage     : %.2f%%", protocol_cov);
        $display("--------------------------------------------------------");
        $display("Overall Coverage      : %.2f%%", total_cov);
        $display("========================================================");

    endfunction
    
endclass


class gener;
    mailbox #(trans) gen2drv;
    int num_trans;
    uart_config cfg;
    coverage cov;
    
    function new(mailbox #(trans) mb, uart_config cfg, coverage cov, int n);
        this.gen2drv = mb;
        this.cfg = cfg;
        this.cov = cov;
        this.num_trans = n;
    endfunction

    task run();
        trans tr;
        $display("[%0t] GENERATOR STARTED", $time);
        $display("           Generating %0d transactions", num_trans);

        repeat(num_trans) begin
            tr = new();
            tr.cfg = cfg;
            assert(tr.randomize()) else $error("Randomization failed!");
            tr.display("GEN");
	    cov.sample_tx(tr);
            gen2drv.put(tr);
        end
        $display("[%0t] GENERATOR ENDED", $time);
    endtask
endclass

class driv;
    uart_config cfg;
    virtual uart_if vif;
    mailbox #(trans) gen2drv;
    mailbox #(trans) drv2scb;
    int num_trans;  // Track number of transactions

    function new(virtual uart_if vif, uart_config cfg, mailbox #(trans) mb_gen, mailbox #(trans) mb_scb, int n = 10);
        this.cfg = cfg;
        this.vif = vif;
        this.gen2drv = mb_gen;
        this.drv2scb = mb_scb;
        this.num_trans = n;
    endfunction

    task reset();
        $display("[%0t] RESET STARTED", $time);
        vif.reset <= 1;
        vif.tx_en <= 0;
        vif.tx_data_in <= 0;
        vif.rx_data <= 1;
        repeat(10) @(posedge vif.clk);
        vif.reset <= 0;
        repeat(5) @(posedge vif.clk);
        $display("[%0t] RESET ENDED", $time);
    endtask

    task driv_tx(trans tr);
        $display("[%0t] [DRV_TX] Transmitting data: 0x%02h", $time, tr.data_sent);
        
        @(posedge vif.clk);
        vif.tx_en <= 1'b1;
        vif.tx_data_in <= tr.data_sent;
        @(posedge vif.clk);
        vif.tx_en <= 1'b0;

        wait(vif.tx_done == 1'b1);
        @(posedge vif.clk);
        
        $display("[%0t] [DRV_TX] Transmission complete", $time);
    endtask

    task driv_rx(trans tr);
        int bit_period;
        bit parity_bit;
        
        bit_period = cfg.get_bit_period();
        
        $display("[%0t] [DRV_RX] Sending UART frame to RX", $time);
        
        if(cfg.PARITY_EN) begin
            parity_bit = (cfg.PARITY_TYPE) ? ~(^tr.data_sent) : ^(tr.data_sent);
            if (tr.parity_error_inject) begin
                parity_bit = ~parity_bit;
                $display("[%0t] [DRV_RX] Injecting PARITY ERROR", $time);
            end
        end

        repeat(10) @(posedge vif.clk);
        
        vif.rx_data <= 1'b0;
        repeat(bit_period) @(posedge vif.clk);

        for (int i = 0; i < cfg.DATABITS; i++) begin
            vif.rx_data <= tr.data_sent[i];
            repeat(bit_period) @(posedge vif.clk);
        end
        
        if(cfg.PARITY_EN) begin
            vif.rx_data <= parity_bit;
            repeat(bit_period) @(posedge vif.clk);
        end
        
        if(tr.stop_error_inject) begin
            vif.rx_data <= 1'b0;
            $display("[%0t] [DRV_RX] Injecting STOP BIT ERROR", $time);
        end else begin
            vif.rx_data <= 1'b1;
        end
        repeat(bit_period) @(posedge vif.clk);
        
        vif.rx_data <= 1'b1;
        
        $display("[%0t] [DRV_RX] UART frame sent to RX", $time);
    endtask

    task run();
        trans tr;
        $display("[%0t] DRIVER STARTED", $time);

        repeat(num_trans) begin  
            gen2drv.get(tr);
            tr.display("DRV");
            
            fork
                driv_tx(tr);
                driv_rx(tr);
            join
            
            drv2scb.put(tr);
	    @(posedge vif.clk);
        end
        
        $display("[%0t] DRIVER ENDED", $time);
    endtask
endclass

class montr;
    virtual uart_if vif;
    mailbox #(trans) mon2scb;
    uart_config cfg;
    int num_trans;  // Track number of transactions
    int trans_received = 0;
    coverage cov;

    function new(virtual uart_if vif, uart_config cfg,coverage cov, mailbox #(trans) mb, int n);
        this.vif = vif;
        this.cfg = cfg;
	    this.cov = cov;
        this.mon2scb = mb;
        this.num_trans = n;
    endfunction
    
    task run();
        trans tr;
        $display("[%0t] MONITOR STARTED", $time);

        while(trans_received < num_trans) begin 
            @(posedge vif.clk);

            if(vif.rx_done) begin
                tr = new();
                tr.cfg = cfg;
                tr.data_got = vif.rx_data_out;
                tr.rx_done = vif.rx_done;
                tr.error_flag = vif.error_flag;
                tr.display_result("MON");
    		cov.sample_rx(tr);
                mon2scb.put(tr);
                trans_received++;
            end    
        end
        
        $display("[%0t] MONITOR ENDED", $time);
    endtask
endclass

class scrboard;
    mailbox #(trans) drv2scb;
    mailbox #(trans) mon2scb;
    int pass_count = 0;
    int fail_count = 0;
    int trans_count = 0;
    int num_trans;  // Expected number of transactions

    function new(mailbox #(trans) mb_mon, mailbox #(trans) mb_drv, int n);
        this.mon2scb = mb_mon;
        this.drv2scb = mb_drv;
        this.num_trans = n;
    endfunction

    task run();
        trans tr_exp, tr_act;
        $display("[%0t] SCOREBOARD STARTED", $time);
        
        repeat(num_trans) begin  // Changed from forever to repeat
            drv2scb.get(tr_exp);
            mon2scb.get(tr_act);
            
            trans_count++;

            if (tr_exp.data_sent == tr_act.data_got) begin
                if (tr_exp.parity_error_inject || tr_exp.stop_error_inject) begin
                    if (tr_act.error_flag) begin
                        $display("[%0t][SCB] PASS (Error Expected): Exp=0x%02h, Got=0x%02h, Error=%0b", 
                            $time, tr_exp.data_sent, tr_act.data_got, tr_act.error_flag);
                        pass_count++;
                    end else begin
                        $display("[%0t][SCB] FAIL (Error Not Detected): Exp=0x%02h, Got=0x%02h, Error=%0b", 
                            $time, tr_exp.data_sent, tr_act.data_got, tr_act.error_flag);
                        fail_count++;
                    end
                end else begin
                    if (!tr_act.error_flag) begin
                        $display("[%0t][SCB] PASS: Exp=0x%02h, Got=0x%02h", 
                            $time, tr_exp.data_sent, tr_act.data_got);
                        pass_count++;
                    end else begin
                        $display("[%0t][SCB] FAIL (Unexpected Error): Exp=0x%02h, Got=0x%02h, Error=%0b",
                            $time, tr_exp.data_sent, tr_act.data_got, tr_act.error_flag);
                        fail_count++;
                    end
                end
            end else begin
                $display("[%0t][SCB] FAIL (Data Mismatch): Exp=0x%02h, Got=0x%02h, Error=%0b",
                    $time, tr_exp.data_sent, tr_act.data_got, tr_act.error_flag);
                fail_count++;
            end
        end
        
        $display("[%0t] SCOREBOARD ENDED", $time);
    endtask

    function void report();
        $display("\n");
        $display("========================================================");
        $display("              SCOREBOARD FINAL REPORT");
        $display("========================================================");
        $display("Total Transactions : %0d", trans_count);
        $display("Total Passed       : %0d", pass_count);
        $display("Total Failed       : %0d", fail_count);
        $display("Pass Rate          : %.2f%%", (pass_count * 100.0) / trans_count);
        $display("========================================================");

    endfunction
endclass

class environment;
    uart_config cfg;    
    virtual uart_if vif;

    gener gen;
    driv drv;
    montr mon;
    scrboard scb;
    coverage cov;  

    mailbox #(trans) gen2drv;
    mailbox #(trans) mon2scb;
    mailbox #(trans) drv2scb;
    
    int num_trans;

    function new(virtual uart_if vif, uart_config cfg, int n = 10);
        this.vif = vif;
        this.cfg = cfg;
        this.num_trans = n;
        
        gen2drv = new();
        mon2scb = new();
        drv2scb = new();

        cov = new(cfg);

        gen = new(gen2drv, cfg, cov, num_trans);
        drv = new(vif, cfg, gen2drv, drv2scb, num_trans);
        mon = new(vif, cfg, cov, mon2scb, num_trans);
        scb = new(mon2scb, drv2scb, num_trans);
    endfunction
    
    task run();
        drv.reset();
        
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join
        
        scb.report();
	cov.report();
    endtask
endclass

endpackage
