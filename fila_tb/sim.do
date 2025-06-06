if {[file exists work]} {
    vdel -lib work -all
}
vlib work


vcom -2008 -work work fila.vhdl
vcom -2008 -work work tb_fila.vhdl


vsim -t ps -voptargs=+acc work.fila_tb


add wave -divider "=== CONTROLE ==="
add wave -label "Clock" /fila_tb/clock_10KHz
add wave -label "Reset" /fila_tb/reset

add wave -divider "=== ENTRADA ==="
add wave -label "Data In" -radix hex /fila_tb/data_in
add wave -label "Enqueue" /fila_tb/enqueue_in
add wave -label "Dequeue" /fila_tb/dequeue_in

add wave -divider "=== SAIDA ==="
add wave -label "Data Out" -radix hex /fila_tb/data_out
add wave -label "Length" -radix unsigned /fila_tb/len_out

add wave -divider "=== INTERNO ==="
add wave -label "Memory" -radix hex /fila_tb/DUT/memory
add wave -label "Head" -radix unsigned /fila_tb/DUT/head_ptr
add wave -label "Tail" -radix unsigned /fila_tb/DUT/tail_ptr
add wave -label "Count" -radix unsigned /fila_tb/DUT/count

# Configura visualização
configure wave -namecolwidth 150
configure wave -valuecolwidth 80
configure wave -timelineunits us

# Mostra estado
echo "Estado inicial:"
echo "Clock: " [examine /fila_tb/clock_10KHz]
echo "Reset: " [examine /fila_tb/reset]
echo "Length: " [examine /fila_tb/len_out]

run -all

wave zoom full


