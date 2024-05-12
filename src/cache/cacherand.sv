// Random cache with LSFR

module cacherand
    #(parameter NUMWAYS = 4, SETLEN = 9, OFFSETLEN = 5, NUMLINES = 128) (
  input  logic                clk, 
  input  logic                reset,
  input  logic                FlushStage,
  input  logic                CacheEn,         // Enable the cache memory arrays.  Disable hold read data constant
  input  logic [NUMWAYS-1:0]  HitWay,          // Which way is valid and matches PAdr's tag
  input  logic [NUMWAYS-1:0]  ValidWay,        // Which ways for a particular set are valid, ignores tag
  input  logic [SETLEN-1:0]   CacheSetData,    // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   CacheSetTag,     // Cache address, the output of the address select mux, NextAdr, PAdr, or FlushAdr
  input  logic [SETLEN-1:0]   PAdr,            // Physical address 
  input  logic                LRUWriteEn,      // Update the LRU state
  input  logic                SetValid,        // Set the dirty bit in the selected way and set
  input  logic                ClearValid,      // Clear the dirty bit in the selected way and set
  input  logic                InvalidateCache, // Clear all valid bits
  output logic [NUMWAYS-1:0]  VictimWay        // LRU selects a victim to evict
);

    localparam                      LOGNUMWAYS = log2(NUMWAYS);

    logic [LOGNUMWAYS+1:0]          next;
    logic [LOGNUMWAYS+1:0]          val;
    logic [LOGNUMWAYS+1:0]          curr;


    logic                           AllValid;
    logic [NUMWAYS-1:0]             FirstZero;
    logic [LOGNUMWAYS-1:0]          FirstZeroWay;
    logic [LOGNUMWAYS-1:0]          VictimWayEnc;

    // LSFR Module
    flopenL #(LOGNUMWAYS+2) LSFReg (clk, reset, 1'b1, next, val, curr)

    assign next[LOGNUMWAYS:0] = curr[LOGNUMWAYS+1:1];
    if ((LOGNUMWAYS+2) == 3) begin
        assign next[2] = curr[2] ^ curr[0];
    end else if ((LOGNUMWAYS+2) == 4) begin
        assign next[3] = curr[3] ^ curr[0];
    end else if ((LOGNUMWAYS+2) == 7) begin
        assign next[6] = curr[6] ^ curr[5] ^ curr[3] ^ curr[0];
    end

    assign val[1:0] = 2'b10;
    assign val[LOGNUMWAYS+1:2] = '0;

    // Victim Way Module
    priorityonehot #(NUMWAYS) FirstZeroEncoder(~ValidWay, FirstZero);
    binencoder #(NUMWAYS) FirstZeroWayEncoder(FirstZero, FirstZeroWay);
    mux2 #(LOGNUMWAYS) VictimMux(FirstZeroWay, Curr[LOGNUMWAYS-1:0], AllValid, VictimWayEnc);
    decoder #(LOGNUMWAYS) decoder (VictimWayEnc, VictimWay);
endmodule