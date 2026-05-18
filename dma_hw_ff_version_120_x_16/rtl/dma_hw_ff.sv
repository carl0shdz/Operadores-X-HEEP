module dma_hw_ff (
    input logic clk_i,
    input logic rst_ni,
    // Interfaz hadware fifo
    output hw_fifo_req_done,
    input dma_fifo_pkg::fifo_req_t hw_fifo_req_i,
    output dma_fifo_pkg::fifo_resp_t hw_fifo_resp_o

);

  localparam RW_FIFO_DEPTH_W = 16;
  logic [4 : 0] conta;
  logic done;

  // --- 1. FIFO DE ENTRADA (DMA -> HW) --- 
  logic hw_r_fifo_full, hw_r_fifo_empty, hw_r_fifo_pop;  //Creo senales intermedias.
  logic [15:0] hw_r_fifo_data_out;
  fifo_v3 #(
      .DEPTH(RW_FIFO_DEPTH_W),
      .FALL_THROUGH(1'b1),
      .DATA_WIDTH(4)
  ) hw_r_fifo_i (
      .clk_i(clk_i),
      .rst_ni,
      .flush_i(1'b0),
      .testmode_i(1'b0),
      .full_o(hw_r_fifo_full),  	//indica si la FIFO esta llena
      .empty_o(hw_r_fifo_empty),  	//indica si la FIFO esta vacia
      .usage_o(),
      .data_i(hw_fifo_req_i.data),  	//Cargar dato en la FIFO
      .push_i(hw_fifo_req_i.push),  	//Bit para empuar dato hacia dentro de la FIFO
      .data_o(hw_r_fifo_data_out),  	//Sacar dato de la FIFO
      .pop_i(hw_r_fifo_pop)  		//Bit para empujar dato hacia fuera de la FIFO
  );
  assign hw_fifo_resp_o.full     = hw_r_fifo_full;
  assign hw_fifo_resp_o.alm_full = hw_r_fifo_full;



  // --- 2. FIFO DE SALIDA (HW -> DMA) --- 
  logic hw_w_fifo_full, hw_w_fifo_empty, hw_w_fifo_push;
  logic [15:0] hw_w_fifo_data_in;
  fifo_v3 #(
      .DEPTH(RW_FIFO_DEPTH_W),
      .FALL_THROUGH(1'b1),
      .DATA_WIDTH(4)
  ) hw_w_fifo_i (
      .clk_i(clk_i),
      .rst_ni,
      .flush_i(1'b0),
      .testmode_i(1'b0),
      .full_o(hw_w_fifo_full),
      .empty_o(hw_w_fifo_empty),
      .usage_o(),
      .data_i(hw_w_fifo_data_in),
      .push_i(hw_w_fifo_push),
      .data_o(hw_fifo_resp_o.data),
      .pop_i(hw_fifo_req_i.pop)
  );

  assign hw_fifo_resp_o.empty = hw_w_fifo_empty;
  assign hw_w_fifo_data_in = hw_r_fifo_data_out + 1;


  assign hw_r_fifo_pop = !hw_r_fifo_empty && !hw_w_fifo_full;
  assign hw_w_fifo_push = hw_r_fifo_pop;

  logic [7:0] count_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      count_q <= '0;
      done <= 1'b0;
    end else if (hw_fifo_req_i.pop) begin
      count_q <= count_q + 1;
      if (count_q == 15) begin
        done <= 1'b1;
        $display("[%t]Done", $time);
      end
    end  /*
    if (hw_fifo_req_i.push) begin  //aqui depuramos
      $display("[%t] DMA IN_____________: %d", $time, hw_fifo_req_i.data);
    end
    if (hw_fifo_req_i.pop) begin
      $display("[%t] DMA OUT___: %d", $time, hw_fifo_resp_o.data);
    end*/
  end
  assign hw_fifo_req_done = done;

endmodule
