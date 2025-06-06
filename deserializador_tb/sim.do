if {[file exists work]} {
    vdel -lib work -all
}

vlib work

vcom -2008 deserializador.vhdl
vcom -2008 tb_deserializador.vhdl

vsim -gui deserializador_tb

add wave -divider "Clock e Reset"
add wave /deserializador_tb/clk
add wave /deserializador_tb/reset

add wave -divider "Sinais de Entrada"
add wave /deserializador_tb/data_in
add wave /deserializador_tb/write_in
add wave /deserializador_tb/ack_in

add wave -divider "Sinais de Saída"
add wave /deserializador_tb/data_out
add wave /deserializador_tb/data_ready
add wave /deserializador_tb/status_out

configure wave -namecolwidth 200
configure wave -valuecolwidth 100

run 1 ms

add wave -divider "Sinais Internos"
catch {add wave /deserializador_tb/uut/shift_reg}
catch {add wave /deserializador_tb/uut/bit_counter}
catch {add wave /deserializador_tb/uut/state}

wave zoom full

write format wave fifo_simulation.wlf 
