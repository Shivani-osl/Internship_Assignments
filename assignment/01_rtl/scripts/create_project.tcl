# P0 Vivado project creation script
# Target: Zynq-7000 xc7z020clg484-1
# Vivado: 2019.1

set project_name "p0_baseline"
set project_dir [file normalize "assignment/01_rtl/vivado"]

create_project $project_name $project_dir -part xc7z020clg484-1

set_property target_language Verilog [current_project]

puts "P0 project created successfully."
puts "Target part: [get_property PART [current_project]]"

close_project