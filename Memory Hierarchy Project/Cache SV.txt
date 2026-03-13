module cache #(
    parameter CACHE_SIZE = 1024,        // Cache size in bytes (1 KB)
    parameter BLOCK_SIZE = 16,          // Block size in bytes (16 bytes)
    parameter ADDR_WIDTH = 32           // Address width (32 bits)
) (
    input logic clk,                    // Clock signal
    input logic rst,                    // Reset signal
    input logic [ADDR_WIDTH-1:0] addr,  // Address input
    input logic [31:0] data_in,         // Data input
    input logic read,                   // Read signal
    input logic write,                  // Write signal
    output logic [31:0] data_out,       // Data output
    output logic ready,                 // Ready signal
    output logic hit,                   // Cache hit signal
    output logic miss,                  // Cache miss signal
    output logic dirty_bit_status,      // Dirty bit status
    // DRAM interface
    input logic [31:0] dram_data_out,   // Data output from DRAM
    input logic dram_ready,             // Ready signal from DRAM
    output logic [ADDR_WIDTH-1:0] dram_addr, // Address to DRAM
    output logic [31:0] dram_data_in,   // Data input to DRAM
    output logic dram_read,             // Read signal to DRAM
    output logic dram_write             // Write signal to DRAM
);

    // Internal signals
    logic [31:0] cache_memory[CACHE_SIZE/BLOCK_SIZE-1:0]; // Cache memory
    logic [CACHE_SIZE/BLOCK_SIZE-1:0] dirty_bits;        // Dirty bits for each cache line
    logic [CACHE_SIZE/BLOCK_SIZE-1:0] valid_bits;        // Valid bits for each cache line
    logic [ADDR_WIDTH-1:0] cache_addr;                   // Internal address for cache
    logic [31:0] cache_data_out;                         // Internal data output
    logic cache_ready;                                   // Internal ready signal
    logic cache_hit;                                      // Internal hit signal
    logic cache_miss;                                     // Internal miss signal
    logic cache_dirty_bit_status;                         // Internal dirty bit status

    // DRAM interface signals
    logic [ADDR_WIDTH-1:0] internal_dram_addr;           // Internal DRAM address
    logic [31:0] internal_dram_data_in;                  // Internal DRAM data input
    logic internal_dram_read;                            // Internal DRAM read signal
    logic internal_dram_write;                           // Internal DRAM write signal

    // Cache logic
    always @(posedge clk) begin
        if (rst) begin
            cache_ready <= 0;             // Reset the ready signal
            cache_data_out <= 0;          // Reset the data output
            dirty_bits <= 0;              // Reset the dirty bits
            valid_bits <= 0;              // Reset the valid bits
            cache_hit <= 0;               // Reset the hit signal
            cache_miss <= 0;              // Reset the miss signal
            cache_dirty_bit_status <= 0;  // Reset the dirty bit status
        end else begin
            cache_addr <= addr;           // Update internal address
            if (write) begin
                logic [6:0] index = cache_addr[$clog2(BLOCK_SIZE)+$clog2(CACHE_SIZE/BLOCK_SIZE)-1:$clog2(BLOCK_SIZE)]; //Extract Index
                logic [21:0] tag = cache_addr[ADDR_WIDTH-1:$clog2(BLOCK_SIZE)+$clog2(CACHE_SIZE/BLOCK_SIZE)]; //Extract Tag

                if (valid_bits[index] && cache_memory[index][31:8] == tag) begin //checking for the HIT
                    cache_memory[index][7:0] <= data_in; // Write data to cache
                    dirty_bits[index] <= 1;             // Mark as dirty
                    cache_ready <= 1;
                    cache_hit <= 1;
                    cache_miss <= 0;
                    cache_dirty_bit_status <= dirty_bits[index]; // Update dirty bit status
                end else begin
                    // Cache miss, write to DRAM and update cache
                    internal_dram_addr <= cache_addr;
                    internal_dram_data_in <= data_in;
                    internal_dram_write <= 1;
                    internal_dram_read <= 0;
                    //updating the cache
                    cache_memory[index][7:0] <= data_in; // Write data to cache //can remove [7:0]
                    cache_memory[index][31:8] <= tag;    // Update tag
                    valid_bits[index] <= 1;             // Mark as valid
                    dirty_bits[index] <= 1;             // Mark as dirty
                    cache_ready <= 1;
                    cache_hit <= 0;
                    cache_miss <= 1;
                    cache_dirty_bit_status <= dirty_bits[index]; // Update dirty bit status
                end
            end else if (read) begin
                logic [6:0] index = cache_addr[$clog2(BLOCK_SIZE)+$clog2(CACHE_SIZE/BLOCK_SIZE)-1:$clog2(BLOCK_SIZE)];
                logic [21:0] tag = cache_addr[ADDR_WIDTH-1:$clog2(BLOCK_SIZE)+$clog2(CACHE_SIZE/BLOCK_SIZE)];

                if (valid_bits[index] && cache_memory[index][31:8] == tag) begin
                    cache_data_out <= cache_memory[index][7:0]; // Read data from cache
                    cache_ready <= 1;
                    cache_hit <= 1;
                    cache_miss <= 0;
                end else begin
                    // Cache miss, read from DRAM
                    internal_dram_addr <= cache_addr;
                    internal_dram_read <= 1;
                    internal_dram_write <= 0;

                    cache_ready <= 0;
                    cache_hit <= 0;
                    cache_miss <= 1;
                end
            end
        end
    end

    // Assign DRAM interface signals
    assign dram_addr = internal_dram_addr;
    assign dram_data_in = internal_dram_data_in;
    assign dram_read = internal_dram_read;
    assign dram_write = internal_dram_write;

    // Assign internal signals to output ports
    assign data_out = cache_data_out;
    assign ready = cache_ready;
    assign hit = cache_hit;
    assign miss = cache_miss;
    assign dirty_bit_status = cache_dirty_bit_status;

endmodule