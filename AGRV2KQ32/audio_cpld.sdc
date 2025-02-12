# Main PLL Clock 24.576 MHz
create_clock -name clk -period 40.69 -waveform {0 18.518} [get_ports {clk}]
# Sub Clock 22.5792 MHz
create_clock -name sub_clk -period 44.29 -waveform {0 22.145} [get_ports {sub_clk}]
create_generated_clock -name sub_clk_d2 -source [get_ports {sub_clk}] -divide_by 2 [get_registers {clkdiv4:clkdiv4|cnt[0]}]
create_generated_clock -name sub_clk_d4 -source [get_ports {sub_clk}] -divide_by 4 [get_registers {clkdiv4:clkdiv4|cnt[1]}]

derive_pll_clocks -create_base_clocks

# Clock Groups
set_clock_groups -asynchronous -group {clk} \
                               -group {main_pll|altpll_component|auto_generated|pll1|clk[0]} \
										 -group {main_pll|altpll_component|auto_generated|pll1|clk[1]} \
										 -group {main_pll|altpll_component|auto_generated|pll1|clk[2]} \
										 -group {main_pll|altpll_component|auto_generated|pll1|clk[3]} \
										 -group {main_pll|altpll_component|auto_generated|pll1|clk[4]} \
										 -group {sub_clk} \
										 -group {sub_clk_d2} \
										 -group {sub_clk_d4}

# False paths
set_false_path -from [get_ports in_ck]
set_false_path -from [get_ports in_ws]
set_false_path -from [get_ports in_sd]

set_false_path -to [get_ports out_ws]
set_false_path -to [get_ports out_ck]
set_false_path -to [get_ports out_sd]

set_false_path -to [get_ports buffer_empty]
set_false_path -to [get_ports buffer_full]

set_false_path -from [get_ports spi_ck]
set_false_path -from [get_ports spi_mosi]
set_false_path -to [get_ports spi_miso]
set_false_path -from [get_ports spi_nss]

derive_clock_uncertainty
