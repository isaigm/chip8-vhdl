`timescale 1ns/1ps

module tb_priority_encoder_non_power_2;

  // N no es potencia de 2 (ejemplo con N = 10)
  localparam int N = 10;
  localparam int IDX_WIDTH = $clog2(N) + 1; // Para alinearse con [$clog2(N):0]

  logic [N-1:0]           data_in;
  logic                   found;
  logic [IDX_WIDTH-1:0]   idx;

  // Instancia del DUT
  priority_encoder #(
    .N(N)
  ) dut (
    .data_in (data_in),
    .found   (found),
    .idx     (idx)
  );

  // Golden Model LSB
  function automatic void expected_out(
    input  logic [N-1:0]           in_val,
    output logic                   exp_found,
    output logic [IDX_WIDTH-1:0]   exp_idx
  );
    exp_found = 1'b0;
    exp_idx   = '0;

    for (int i = 0; i < N; i++) begin
      if (in_val[i]) begin
        exp_found = 1'b1;
        exp_idx   = i[IDX_WIDTH-1:0];
        break; // Prioridad LSB
      end
    end
  endfunction

  // Tarea de verificación
  task automatic check_result(input string test_name);
    logic                   exp_found;
    logic [IDX_WIDTH-1:0]   exp_idx;

    #1; // Retardo combinacional
    expected_out(data_in, exp_found, exp_idx);

    if (found !== exp_found) begin
      $error("[%s] ERROR en 'found': data_in=%b (%0d bits) | Exp=%b, Got=%b", 
             test_name, data_in, N, exp_found, found);
    end else if (exp_found && (idx !== exp_idx)) begin
      $error("[%s] ERROR en 'idx': data_in=%b (%0d bits) | Exp=%0d, Got=%0d", 
             test_name, data_in, N, exp_idx, idx);
    end else begin
      $display("[%s] PASS: data_in=%b -> found=%b, idx=%0d", 
               test_name, data_in, found, idx);
    end
  endtask

  initial begin
    $display("--- INICIO SIMULACION (N = %0d, NO POTENCIA DE 2) ---", N);

    // 1. Caso base: Cero
    data_in = '0;
    check_result("ALL_ZEROS");

    // 2. Barrido One-Hot hasta el bit máximo válido (N - 1 = 9)
    for (int i = 0; i < N; i++) begin
      data_in = (1'b1 << i);
      check_result($sformatf("ONE_HOT_BIT_%0d", i));
    end

    // 3. Caso borde: solo el bit más alto activo (bit 9)
    data_in = (1'b1 << (N - 1));
    check_result("MAX_INDEX_ALONE");

    // 4. Todos los bits válidos en '1' (N bits en 1)
    data_in = '1; // Rellena exactamente los N bits
    check_result("ALL_ONES_N_BITS");

    // 5. Casos con patrones mixtos
    data_in = 10'b10_0000_0000; // Solo MSB -> idx = 9
    check_result("ONLY_MSB");

    data_in = 10'b10_1000_0000; // Bits 9 y 7 -> idx = 7
    check_result("MSB_AND_BIT7");

    data_in = 10'b01_0000_0100; // Bits 8 y 2 -> idx = 2
    check_result("BIT8_AND_BIT2");

    // 6. Pruebas Aleatorias con máscara exacta a N bits
    for (int i = 0; i < 20; i++) begin
      data_in = $urandom(); // SystemVerilog trunca automáticamente a N bits
      check_result($sformatf("RANDOM_%0d", i));
    end

    $display("--- SIMULACION COMPLETADA CON EXITO ---");
    $finish;
  end

endmodule