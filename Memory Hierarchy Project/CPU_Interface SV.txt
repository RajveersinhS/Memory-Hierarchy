module cpu_interface (
    input logic clk,
    input logic rst,
    input logic [31:0] cpu_addr,
    input logic [31:0] cpu_data_in,
    input logic cpu_read,
    input logic cpu_write,
    output logic [31:0] cpu_data_out,
    output logic cpu_ready,
    output logic hit,
    output logic miss,
    output logic dirty_bit_status
);

    // Parameters for cache configuration
    parameter CACHE_SIZE = 1024; // 1 KB
    parameter BLOCK_SIZE = 16;  // 16 bytes
    parameter CACHE_LINES = CACHE_SIZE / BLOCK_SIZE; //1024/16 = 64 Cache Lines
    parameter ADDR_WIDTH = 32;
    parameter BLOCK_ADDR_WIDTH = $clog2(BLOCK_SIZE);
    parameter CACHE_ADDR_WIDTH = ADDR_WIDTH - BLOCK_ADDR_WIDTH; // 32 - 16 = 16 Cache addr Width

    // Internal signals
    logic [ADDR_WIDTH-1:0] cache_addr;
    logic [31:0] cache_data_in;
    logic cache_read;
    logic cache_write;
    logic [31:0] cache_data_out;
    logic cache_ready;
    logic cache_hit;
    logic cache_miss;
    logic cache_dirty_bit_status;

    // Cache module
    cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cache_inst (
        .clk(clk),
        .rst(rst),
        .addr(cache_addr),
        .data_in(cache_data_in),
        .read(cache_read),
        .write(cache_write),
        .data_out(cache_data_out),
        .ready(cache_ready),
        .hit(cache_hit),
        .miss(cache_miss),
        .dirty_bit_status(cache_dirty_bit_status),
        .dram_data_out(),     // Assuming DRAM not yet connected in cpu_interface
        .dram_ready(),
        .dram_addr(),
        .dram_data_in(),
        .dram_read(),
        .dram_write()
    );
    
    assign hit = cache_hit;
    assign miss = cache_miss;
    assign dirty_bit_status = cache_dirty_bit_status;

    
    
//Acts as a bridge between the CPU and the cache. 
//It receives read/write requests and passes them to the cache. 
//It also collects data from the cache and informs the CPU when the data is ready.

    // CPU interface logic
    always @(posedge clk) begin
        if (rst) begin
            cpu_ready <= 0;
            cpu_data_out <= 0;
        end else begin
            cache_addr <= cpu_addr;
            cache_data_in <= cpu_data_in;
            cache_read <= cpu_read;
            cache_write <= cpu_write;
            cpu_data_out <= cache_data_out;
            cpu_ready <= cache_ready;
        end
    end

endmodule