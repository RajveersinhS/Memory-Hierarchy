module tb_cpu_interface;

    // Parameters
    parameter CLK_PERIOD = 10;          // Clock period in time units
    parameter ADDR_WIDTH = 32;          // Address width
    parameter DATA_WIDTH = 32;          // Data width
    parameter NUM_TESTS = 10;           // Number of test cases
    parameter CACHE_SIZE = 1024;        // Cache size in bytes
    parameter BLOCK_SIZE = 16;          // Block size in bytes
    parameter CACHE_LINES = CACHE_SIZE / BLOCK_SIZE; // Number of cache lines
    parameter DRAM_SIZE = 64 * 1024;    // DRAM size in bytes (64 KB)
    parameter DRAM_LATENCY = 1;         // DRAM latency in clock cycles

    // Signals
    logic clk;                          // Clock signal
    logic rst;                          // Reset signal
    logic [ADDR_WIDTH-1:0] cpu_addr;    // CPU address
    logic [DATA_WIDTH-1:0] cpu_data_in; // Data input to CPU
    logic cpu_read;                     // CPU read signal
    logic cpu_write;                    // CPU write signal
    logic [DATA_WIDTH-1:0] cpu_data_out;// Data output from CPU
    logic cpu_ready;                    // CPU ready signal
    logic cache_hit;                    // Cache hit signal
    logic cache_miss;                   // Cache miss signal
    logic cache_dirty_bit_status;       // Cache dirty bit status
    logic [ADDR_WIDTH-1:0] dram_addr;   // DRAM address
    logic [DATA_WIDTH-1:0] dram_data_in;// DRAM data input
    logic dram_read;                    // DRAM read signal
    logic dram_write;                   // DRAM write signal
    logic [DATA_WIDTH-1:0] dram_data_out;// DRAM data output
    logic dram_ready;                   // DRAM ready signal

    // Counters for hit and miss
    int hit_count = 0;
    int miss_count = 0;

    // Total operations counter (must be declared at the top level)
    int total_ops;

    // CPU interface instance
    cpu_interface cpu_interface_inst (
        .clk(clk),
        .rst(rst),
        .cpu_addr(cpu_addr),
        .cpu_data_in(cpu_data_in),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .cpu_data_out(cpu_data_out),
        .cpu_ready(cpu_ready),
        .hit(cache_hit),
        .miss(cache_miss),
        .dirty_bit_status(cache_dirty_bit_status)
    );

    // Cache instance
    cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cache_inst (
        .clk(clk),
        .rst(rst),
        .addr(cpu_addr),
        .data_in(cpu_data_in),
        .read(cpu_read),
        .write(cpu_write),
        .data_out(cpu_data_out),
        .ready(cpu_ready),
        .hit(cache_hit),
        .miss(cache_miss),
        .dirty_bit_status(cache_dirty_bit_status),
        .dram_data_out(dram_data_out),
        .dram_ready(dram_ready),
        .dram_addr(dram_addr),
        .dram_data_in(dram_data_in),
        .dram_read(dram_read),
        .dram_write(dram_write)
    );

    // DRAM instance
    dram #(
        .DRAM_SIZE(DRAM_SIZE),
        .DRAM_LATENCY(DRAM_LATENCY)
    ) dram_inst (
        .clk(clk),
        .rst(rst),
        .addr(dram_addr),
        .data_in(dram_data_in),
        .read(dram_read),
        .write(dram_write),
        .data_out(dram_data_out),
        .ready(dram_ready)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;  // Toggle clock every half period

    // Test sequence
    initial begin
        clk = 0;                        // Initialize clock
        rst = 1;                        // Assert reset
        cpu_addr = 0;                   // Initialize address
        cpu_data_in = 0;                // Initialize data input
        cpu_read = 0;                   // Initialize read signal
        cpu_write = 0;                  // Initialize write signal
        dram_addr = 0;                  // Initialize DRAM address
        dram_data_in = 0;               // Initialize DRAM data input
        dram_read = 0;                  // Initialize DRAM read signal
        dram_write = 0;                 // Initialize DRAM write signal

        // Reset
        #(CLK_PERIOD*2);                // Wait for 2 clock periods
        rst = 0;                        // Deassert reset

        // Initialize total operations counter
        total_ops = 0;

        // Test cases for register read/write operations
        for (int i = 0; i < NUM_TESTS; i++) begin
            // Write to address 0x00000000 + i*4 (Register write)
            cpu_addr = 32'h00000000 + i*4; // Set address
            cpu_data_in = 32'hAAAAAAAA + i; // Set data to write
            cpu_write = 1;               // Assert write signal
            #(CLK_PERIOD*2);             // Wait for 2 clock periods
            cpu_write = 0;               // Deassert write signal

            // Read from address 0x00000000 + i*4 (Register read)
            cpu_addr = 32'h00000000 + i*4; // Set address
            cpu_read = 1;                // Assert read signal
            #(CLK_PERIOD*2);             // Wait for 2 clock periods
            cpu_read = 0;                // Deassert read signal
        end

        // Introduce cache misses by accessing addresses outside the initial cache content
        for (int i = 0; i < NUM_TESTS; i++) begin
            // Write to address 0x00001000 + i*4 (Address outside initial cache content)
            cpu_addr = 32'h00001000 + i*4; // Set address
            cpu_data_in = 32'h55555555 + i; // Set data to write
            cpu_write = 1;               // Assert write signal
            #(CLK_PERIOD*2);             // Wait for 2 clock periods
            cpu_write = 0;               // Deassert write signal

            // Read from address 0x00001000 + i*4 (Address outside initial cache content)
            cpu_addr = 32'h00001000 + i*4; // Set address
            cpu_read = 1;                // Assert read signal
            #(CLK_PERIOD*2);             // Wait for 2 clock periods
            cpu_read = 0;                // Deassert read signal
        end

        // Wait for all operations to complete
        #(CLK_PERIOD*2);

        // Calculate total operations
        total_ops = hit_count + miss_count; // Total operations are hits plus misses

        // Display hit and miss rates
        $display("Hit Count: %d", hit_count);
        $display("Miss Count: %d", miss_count);
        $display("Total Operations: %d", total_ops);
        $display("Hit Rate: %f%%", (hit_count / total_ops) * 100);
        $display("Miss Rate: %f%%", (miss_count / total_ops) * 100);

        // Finish simulation
        #(CLK_PERIOD*2);                 // Wait for 2 clock periods
        $finish;                         // End simulation
    end

    // Monitor changes
    always @(posedge clk) begin
        if (cpu_ready) begin
            // Display CPU interface activity
            $display("Time = %t, Addr = %h, Data = %h, Read = %b, Write = %b, Ready = %b, Hit = %b, Miss = %b, Dirty Bit = %b",
                     $time, cpu_addr, cpu_data_out, cpu_read, cpu_write, cpu_ready, cache_hit, cache_miss, cache_dirty_bit_status);

            // Update hit and miss counters
            if (cache_hit) hit_count++;
            if (cache_miss) miss_count++;
        end
    end

    // Waveform generation
    initial begin
        // Generate waveform file
        $dumpfile("tb_cpu_interface.vcd");
        $dumpvars(0, tb_cpu_interface);
    end

endmodule