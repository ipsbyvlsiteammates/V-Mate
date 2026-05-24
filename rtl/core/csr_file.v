`timescale 1ns/1ps
module csr_file #(
    parameter EXTENSION_F = 1
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [11:0] csr_addr,
    input  wire [31:0] csr_wdata,
    input  wire [1:0]  csr_op,
    input  wire        csr_write,
    input  wire        exception,
    input  wire [3:0]  exception_cause,
    input  wire [31:0] exception_pc,
    input  wire [31:0] exception_addr,
    input  wire        mret_exec,
    input  wire [4:0]  fp_fflags_update,
    input  wire        fp_fflags_we,
    output wire [1:0]  mstatus_fs_out,
    output reg  [31:0] csr_rdata,
    output wire [31:0] mepc_out,
    output wire [31:0] mtvec_out,
    output wire [2:0]  fcsr_rm
);

    localparam logic [11:0] CSR_MSTATUS  = 12'h300;
    localparam logic [11:0] CSR_MISA     = 12'h301;
    localparam logic [11:0] CSR_MIE      = 12'h304;
    localparam logic [11:0] CSR_MTVEC    = 12'h305;
    localparam logic [11:0] CSR_MSCRATCH = 12'h340;
    localparam logic [11:0] CSR_MEPC     = 12'h341;
    localparam logic [11:0] CSR_MCAUSE   = 12'h342;
    localparam logic [11:0] CSR_MTVAL    = 12'h343;
    localparam logic [11:0] CSR_MIP      = 12'h344;
    localparam logic [11:0] CSR_MHARTID  = 12'hF14;

    localparam logic [11:0] CSR_FFLAGS   = 12'h001;
    localparam logic [11:0] CSR_FRM      = 12'h002;
    localparam logic [11:0] CSR_FCSR     = 12'h003;

    localparam logic [1:0] CSR_OP_NONE = 2'b00;
    localparam logic [1:0] CSR_OP_RW   = 2'b01;
    localparam logic [1:0] CSR_OP_RS   = 2'b10;
    localparam logic [1:0] CSR_OP_RC   = 2'b11;

    reg        mstatus_mie;
    reg        mstatus_mpie;
    reg [1:0]  mstatus_fs;
    reg [31:0] mie_reg;
    reg [31:0] mtvec_reg;
    reg [31:0] mscratch_reg;
    reg [31:0] mepc_reg;
    reg [31:0] mcause_reg;
    reg [31:0] mtval_reg;
    reg [31:0] mip_reg;

    reg [2:0]  frm_reg;
    reg [4:0]  fflags_reg;

    wire [31:0] mstatus_val = {17'b0, mstatus_fs, 2'b11, 3'b0, mstatus_mpie, 3'b0, mstatus_mie, 3'b0};
    assign mstatus_fs_out = mstatus_fs;
    wire [31:0] misa_val    = 32'h40000100;
    wire [31:0] mhartid_val = 32'h00000000;

    assign mepc_out  = mepc_reg;
    assign mtvec_out = mtvec_reg;
    wire [31:0] next_csr_wdata;
    assign next_csr_wdata = (csr_op == CSR_OP_RW) ? csr_wdata :
                            (csr_op == CSR_OP_RS) ? (csr_rdata | csr_wdata) :
                            (csr_op == CSR_OP_RC) ? (csr_rdata & ~csr_wdata) :
                            csr_rdata;
    assign fcsr_rm = (csr_write && (csr_addr == CSR_FRM)) ? next_csr_wdata[2:0] : (csr_write && (csr_addr == CSR_FCSR)) ? next_csr_wdata[7:5] : frm_reg;

    always @(*) begin
        case (csr_addr)
            CSR_MSTATUS:  csr_rdata = mstatus_val;
            CSR_MISA:     csr_rdata = misa_val;
            CSR_MIE:      csr_rdata = mie_reg;
            CSR_MTVEC:    csr_rdata = mtvec_reg;
            CSR_MSCRATCH: csr_rdata = mscratch_reg;
            CSR_MEPC:     csr_rdata = mepc_reg;
            CSR_MCAUSE:   csr_rdata = mcause_reg;
            CSR_MTVAL:    csr_rdata = mtval_reg;
            CSR_MIP:      csr_rdata = mip_reg;
            CSR_MHARTID:  csr_rdata = mhartid_val;
            CSR_FFLAGS:   csr_rdata = {27'b0, fflags_reg};
            CSR_FRM:      csr_rdata = {29'b0, frm_reg};
            CSR_FCSR:     csr_rdata = {24'b0, frm_reg, fflags_reg};
            default:      csr_rdata = 32'b0;
        endcase
    end


    wire cg_en = (!rst_n) | exception | mret_exec | csr_write | fp_fflags_we;
    wire gated_clk;
    icg u_local_icg (
        .clk(clk),
        .en(cg_en),
        .gated_clk(gated_clk)
    );

    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus_mie  <= 1'b0;
            mstatus_mpie <= 1'b0;
            mstatus_fs   <= 2'b00;
            mie_reg      <= 32'b0;
            mtvec_reg    <= 32'b0;
            mscratch_reg <= 32'b0;
            mepc_reg     <= 32'b0;
            mcause_reg   <= 32'b0;
            mtval_reg    <= 32'b0;
            mip_reg      <= 32'b0;
            frm_reg      <= 3'b0;
            fflags_reg   <= 5'b0;
        end else begin
            if (exception) begin
                mepc_reg     <= exception_pc;
                mcause_reg   <= {28'b0, exception_cause};
                mtval_reg    <= exception_addr;
                mstatus_mpie <= mstatus_mie;
                mstatus_mie  <= 1'b0;
            end else if (mret_exec) begin
                mstatus_mie  <= mstatus_mpie;
            end else if (csr_write) begin
                case (csr_addr)
                    CSR_MSTATUS: begin
                        mstatus_mie  <= next_csr_wdata[3];
                        mstatus_mpie <= next_csr_wdata[7];
                        mstatus_fs   <= next_csr_wdata[14:13];
                    end
                    CSR_MIE:      mie_reg      <= next_csr_wdata;
                    CSR_MTVEC:    mtvec_reg    <= next_csr_wdata;
                    CSR_MSCRATCH: mscratch_reg <= next_csr_wdata;
                    CSR_MEPC:     mepc_reg     <= next_csr_wdata;
                    CSR_MCAUSE:   mcause_reg   <= next_csr_wdata;
                    CSR_MTVAL:    mtval_reg    <= next_csr_wdata;
                    CSR_MIP:      mip_reg      <= next_csr_wdata;
                    CSR_FFLAGS:   fflags_reg   <= next_csr_wdata[4:0];
                    CSR_FRM:      frm_reg      <= next_csr_wdata[2:0];
                    CSR_FCSR: begin
                        frm_reg    <= next_csr_wdata[7:5];
                        fflags_reg <= next_csr_wdata[4:0];
                    end
                    default: ;
                endcase
            end else if (fp_fflags_we) begin
                fflags_reg <= fflags_reg | fp_fflags_update;
            end
        end
    end
endmodule
