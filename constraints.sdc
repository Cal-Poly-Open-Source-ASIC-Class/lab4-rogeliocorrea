puts "\[INFO\]: Creating Clocks"
create_clock [get_ports rd_clk] -name rd_clk -period 13
set_propagated_clock rd_clk
create_clock [get_ports wr_clk] -name wr_clk -period 92
set_propagated_clock wr_clk

set_clock_groups -asynchronous -group [get_clocks {rd_clk wr_clk}]

puts "\[INFO\]: Setting Max Delay"

set read_period     [get_property -object_type clock [get_clocks {rd_clk}] period]
set write_period    [get_property -object_type clock [get_clocks {wr_clk}] period]
set min_period      [expr {min(${read_period}, ${write_period})}]

set_max_delay -from [get_pins wpointergray*df*/CLK] -to [get_pins wpointerg1*df*/D] $min_period
set_max_delay -from [get_pins rpointergray*df*/CLK] -to [get_pins rpointerg1*df*/D] $min_period