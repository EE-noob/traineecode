transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {d:/altera/13.1/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {d:/altera/13.1/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {d:/altera/13.1/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {d:/altera/13.1/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {d:/altera/13.1/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {d:/altera/13.1/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl {C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl/spi_sector_erase_ctrl.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl {C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl/spi_sector_erase.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl {C:/Users/86187/Desktop/SPI/spi_sector_erase/rtl/spi_drive.v}

vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/tb_spi_sector_erase.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/acdc_check.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/testbench.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/internal_logic.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/M25p16.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/m25p16_driver.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/memory_access.v}
vlog -vlog01compat -work work +incdir+C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12 {C:/Users/86187/Desktop/SPI/spi_sector_erase/prj/../sim/M25P16_VG_V12/parameter.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_spi_sector_erase

add wave *
view structure
view signals
run -all
