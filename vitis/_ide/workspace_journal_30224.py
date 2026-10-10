# 2026-10-10T15:26:59.594683300
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

platform = client.create_platform_component(name = "platform_img_rx",hw_design = "$COMPONENT_LOCATION/../../vivado/img_rx/img_rx_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform_img_rx")
status = platform.build()

comp = client.create_app_component(name="app_img_rx",platform = "$COMPONENT_LOCATION/../platform_img_rx/export/platform_img_rx/platform_img_rx.xpfm",domain = "standalone_microblaze_0")

comp = client.get_component(name="app_img_rx")
status = comp.import_files(from_loc="", files=[], is_skip_copy_sources = False)

status = platform.build()

comp = client.get_component(name="app_img_rx")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

