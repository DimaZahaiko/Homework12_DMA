# 2026-10-10T16:13:28.728208400
import vitis

client = vitis.create_client()
client.set_workspace(path="vitis")

comp = client.create_app_component(name="img_rx",platform = "$COMPONENT_LOCATION/../platform_img_rx/export/platform_img_rx/platform_img_rx.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="platform_img_rx")
status = platform.build()

comp = client.get_component(name="img_rx")
comp.build()

