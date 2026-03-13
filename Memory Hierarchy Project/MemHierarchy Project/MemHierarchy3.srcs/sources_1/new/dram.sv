module dram #(
    parameter DRAM_SIZE = 64 * 1024,
    parameter DRAM_LATENCY = 1
) (
    input logic clk,
    input logic rst,
    input logic [31:0] addr,
    input logic [31:0] data_in,
    input logic read,
    input logic write,
    output logic [31:0] data_out,
    output logic ready
);

    // Internal signals
    logic [31:0] dram_memory[DRAM_SIZE/4-1:0];
    logic [31:0] dram_data_out;
    logic dram_ready;

    // DRAM logic
    always @(posedge clk) begin
        if (rst) begin
            dram_ready <= 0;
            dram_data_out <= 0;
        end else begin
            if (read) begin
                dram_data_out <= dram_memory[addr >> 4]; //addr >> 4 simulates block addressing
                dram_ready <= 1;
            end else if (write) begin
                dram_memory[addr >> 4] <= data_in;
                dram_ready <= 1;
            end
        end
    end

    assign data_out = dram_data_out;
    assign ready = dram_ready;

endmodule