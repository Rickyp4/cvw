// Random cache with LSFR

module cacherand import cvw::*; #(parameter cvw_t P,
                              parameter PA_BITS, XLEN, LINELEN,  NUMLINES,  NUMWAYS, LOGBWPL, WORDLEN, MUXINTERVAL, READ_ONLY_CACHE) (
    input  logic                 clk, reset, FlushStage, LRUWriteEn,
                                 ValidWay
    output logic [NUMWAYS-1:0]   VictimWay
);

    localparam                      LOGNUMWAYS = $clog2(NUMWAYS);

    logic [LOGNUMWAYS+1:0]          next, val, curr;


    logic                           AllValid;
    logic [NUMWAYS-1:0]             FirstZero;
    logic [LOGNUMWAYS-1:0]          FirstZeroWay;
    logic [LOGNUMWAYS-1:0]          VictimWayEnc;

    // LSFR Module
    flopenr #(LOGNUMWAYS+2) LSFReg (clk, reset, 1'b1, next, val, curr)

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