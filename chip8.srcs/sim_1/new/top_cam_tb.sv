`timescale 1ns/1ps

module tb_top_cam();

    // Parámetros (puedes ajustar N para arreglos más grandes)
    parameter int N = 8; 
    parameter int W = 16;

    // Señales
    logic clk;
    logic rst;
    logic start;
    logic [W - 1: 0] target;
    logic [N - 1: 0][W - 1: 0] nums;
    
    logic done;
    logic valid;
    logic [W - 1: 0] first;
    logic [W - 1: 0] second;

    // Estadísticas del Testbench
    int tests_passed = 0;
    int tests_failed = 0;

    // Instancia del DUT
    top_cam #(
        .N(N),
        .W(W)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .target(target),
        .nums(nums),
        .done(done),
        .valid(valid),
        .first(first),
        .second(second)
    );

    // Reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Tarea principal con Self-Checking
    task run_test(
        input logic [N-1:0][W-1:0] test_nums,
        input logic [W-1:0] test_target,
        input int test_id
    );
        automatic int timeout_cnt = 0;
        automatic logic expected_valid = 0;
        
        begin
            // 1. MODELO DE REFERENCIA (Software)
            // Calculamos la respuesta correcta antes de probar el hardware
            for (int i = 0; i < N-1; i++) begin
                for (int j = i+1; j < N; j++) begin
                    if (test_nums[i] + test_nums[j] == test_target) begin
                        expected_valid = 1'b1;
                    end
                end
            end

            // 2. INYECCIÓN DE ESTÍMULOS AL HARDWARE
            @(posedge clk);
            nums = test_nums;
            target = test_target;
            start = 1;
            
            @(posedge clk);
            start = 0; 
            
            // Sincronización: Esperar a que baje 'done'
            timeout_cnt = 0;
            while (done === 1'b1 && timeout_cnt < 20) begin
                @(posedge clk);
                timeout_cnt++;
            end
            
            if (timeout_cnt >= 20) begin
                $display("[FAIL] Test %0d | Target=%0d | FSM bloqueada (done no bajó).", test_id, $signed(target));
                tests_failed++;
            end else begin
                // Sincronización: Esperar a que termine (done suba a 1)
                timeout_cnt = 0;
                while (done === 1'b0 && timeout_cnt < 1000) begin
                    @(posedge clk);
                    timeout_cnt++;
                end
                
                if (timeout_cnt >= 1000) begin
                    $display("[FAIL] Test %0d | Target=%0d | Timeout (done no subió).", test_id, $signed(target));
                    tests_failed++;
                end else begin
                    
                    // 3. COMPARACIÓN DE RESULTADOS
                    if (valid !== expected_valid) begin
                        $display("[FAIL] Test %0d | Error de Valid. Esperado: %0b, Obtenido: %0b (Target=%0d)", 
                                 test_id, expected_valid, valid, $signed(target));
                        tests_failed++;
                    end 
                    else if (valid == 1'b1) begin
                        // Si es válido, verificar que la suma sea correcta
                        if (first + second !== target) begin
                            $display("[FAIL] Test %0d | Suma incorrecta. %0d + %0d != %0d", 
                                     test_id, $signed(first), $signed(second), $signed(target));
                            tests_failed++;
                        end else begin
                            $display("[PASS] Test %0d | Match Correcto: %0d + %0d = %0d", 
                                     test_id, $signed(first), $signed(second), $signed(target));
                            tests_passed++;
                        end
                    end 
                    else begin
                        // Ambos concuerdan en que NO hay solución
                        $display("[PASS] Test %0d | Rechazo Correcto (No hay solucion para %0d)", 
                                 test_id, $signed(target));
                        tests_passed++;
                    end
                end
            end
            repeat(3) @(posedge clk);
        end
    endtask

    // Variables para generación aleatoria
    logic [N-1:0][W-1:0] rand_nums;
    logic [W-1:0] rand_target;
    int idx1, idx2;

    // Bloque principal
    initial begin
        rst = 1;
        start = 0;
        target = 0;
        nums = '{default:0};
        
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);
        
        $display("==================================================");
        $display("   Iniciando Batería de Pruebas Aleatorias (N=%0d)", N);
        $display("==================================================");

        // Generar 100 casos de prueba al azar
        for (int t = 1; t <= 100; t++) begin
            
            // 1. Llenar el arreglo con números aleatorios
            for (int i = 0; i < N; i++) begin
                // Usamos $urandom, casteado al ancho W
                rand_nums[i] = $urandom(); 
            end

            // 2. Determinar el Target
            if (t % 2 == 0) begin
                // Caso A: Forzar que SI exista una solución
                idx1 = $urandom_range(0, N-1);
                idx2 = $urandom_range(0, N-1);
                while (idx1 == idx2) begin
                    idx2 = $urandom_range(0, N-1); // Asegurar índices distintos
                end
                rand_target = rand_nums[idx1] + rand_nums[idx2];
            end else begin
                // Caso B: Target totalmente aleatorio (Probablemente no tenga solución)
                rand_target = $urandom();
            end

            // 3. Ejecutar la prueba
            run_test(rand_nums, rand_target, t);
        end

        $display("==================================================");
        $display("   Resumen de Pruebas");
        $display("   Pasadas: %0d / 100", tests_passed);
        $display("   Falladas: %0d / 100", tests_failed);
        $display("==================================================");
        
        if (tests_failed == 0)
            $display(">> ¡ÉXITO! Tu hardware es 100% robusto.");
        else
            $display(">> ADVERTENCIA: Hay fallos por revisar.");
            
        $finish;
    end

endmodule