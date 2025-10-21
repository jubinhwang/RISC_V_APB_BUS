`timescale 1ns / 1ps

module tb_APB_Manager;

    // Clock and Reset Signals
    logic        PCLK;
    logic        PRESET;

    // APB Interface Signals
    logic [31:0] PADDR;
    logic        PWRITE;
    logic        PENABLE;
    logic [31:0] PWDATA;
    logic        PSEL0, PSEL1, PSEL2, PSEL3;
    logic [31:0] PRDATA0, PRDATA1, PRDATA2, PRDATA3;
    logic        PREADY0, PREADY1, PREADY2, PREADY3;

    // Internal Interface Signals
    logic        transfer;
    logic        write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        ready;

    //-- DUT (Device Under Test) Instantiation
    APB_Manager dut (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PSEL0(PSEL0),
        .PSEL1(PSEL1),
        .PSEL2(PSEL2),
        .PSEL3(PSEL3),
        .PRDATA0(PRDATA0),
        .PRDATA1(PRDATA1),
        .PRDATA2(PRDATA2),
        .PRDATA3(PRDATA3),
        .PREADY0(PREADY0),
        .PREADY1(PREADY1),
        .PREADY2(PREADY2),
        .PREADY3(PREADY3),
        .transfer(transfer),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready)
    );

    test_Master Master (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .transfer(transfer),
        .write(write),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .ready(ready)
    );

    test_Slave Slave0 (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PSEL(PSEL0),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );

    test_Slave Slave1 (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PSEL(PSEL1),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1)
    );

    test_Slave Slave2 (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PSEL(PSEL2),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2)
    );

    test_Slave Slave3 (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PSEL(PSEL3),
        .PENABLE(PENABLE),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA3),
        .PREADY(PREADY3)
    );


    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK; 
    end

    initial begin
        PRESET = 1;
        repeat (2) @(posedge PCLK);
        PRESET = 0;

        wait (Master.finished);
        #100;
        $finish;
    end

endmodule

module test_Master (
    input  logic        PCLK,
    input  logic        PRESET,
    output logic        transfer,
    output logic        write,
    output logic [31:0] addr,
    output logic [31:0] wdata,
    input  logic [31:0] rdata,
    input  logic        ready
);
    logic finished = 1'b0;


    task apb_write(input [31:0] t_addr, input [31:0] t_wdata);
        @(posedge PCLK);
        transfer = 1;
        write    = 1;
        addr     = t_addr;
        wdata    = t_wdata;
        @(posedge PCLK);
        transfer = 0;
        write    = 0;
        wait(ready);
    endtask

    task apb_read(input [31:0] t_addr);
        @(posedge PCLK);
        transfer = 1;
        write    = 0;
        addr     = t_addr;
        @(posedge PCLK);
        transfer = 0;
        wait(ready);
    endtask

    initial begin
        transfer = 0;
        write    = 0;
        addr     = 32'b0;
        wdata    = 32'b0;

        @(negedge PRESET);
        
        repeat (100) begin
            logic [31:0] random_addr;
            logic [31:0] random_wdata;
            logic [1:0]  slave_sel;
            logic [9:0]  word_offset;

            slave_sel = $urandom_range(3, 0);
            word_offset = $urandom_range(1023, 0);
            random_addr = (32'h1000_0000 | (slave_sel << 12) | (word_offset << 2));
            random_wdata = $urandom();

            apb_write(random_addr, random_wdata);
            apb_read(random_addr);
        end

        finished = 1'b1;
    end
endmodule


module test_Slave (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    logic [31:0] mem[0:1023];
    
    assign PRDATA = mem[PADDR[11:2]];

    assign PREADY = PSEL & PENABLE;

    // Write Logic
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            for (int i = 0; i < 1024; i++) begin
                mem[i] <= 32'b0;
            end
        end else begin
            if (PSEL && PENABLE && PWRITE) begin
                mem[PADDR[11:2]] <= PWDATA;
            end
        end
    end

    // // Read Logic
    // always_ff @(posedge PCLK) begin
    //     if (PSEL && PENABLE && !PWRITE) begin
    //         prdata_reg <= mem[PADDR[11:2]];
    //     end
    // end
endmodule

