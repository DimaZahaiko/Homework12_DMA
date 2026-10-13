# 2026-09-28T19:25:35.672380400
import vitis

client = vitis.create_client()
client.set_workspace(path="10_AXI_MB")

platform = client.create_platform_component(name = "platform_MB1",hw_design = "$COMPONENT_LOCATION/../LED_AXI_GPIO_vitis/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_MB1")
status = platform.build()

comp = client.create_app_component(name="app_component_MB",platform = "$COMPONENT_LOCATION/../platform_MB1/export/platform_MB1/platform_MB1.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_component_MB")
status = comp.import_files(from_loc="", files=["C:\Users\dimaz\10\10_AXI_PS\app_component_travelling_led\src\main_combined.c"], is_skip_copy_sources = False)

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = ["../main_combined.c", "C:/Users/dimaz/10/10_AXI_MB/app_component_MB/main_combined.c"])

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = ["../main_combined.c"])

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = [""])

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = ["C:/Users/dimaz/10/10_AXI_MB/app_component_MB/main_combined.c"])

status = comp.import_files(from_loc="$COMPONENT_LOCATION/../../10_AXI_PS/app_component_travelling_led/src", files=["main_combined.c"], dest_dir_in_cmp = "src", is_skip_copy_sources = False)

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = [""])

comp.set_app_config(key = "USER_COMPILE_SOURCES", values = ["C:/Users/dimaz/10/10_AXI_MB/app_component_MB/src/main_combined.c"])

status = platform.build()

comp = client.get_component(name="app_component_MB")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

