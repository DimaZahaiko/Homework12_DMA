# 2026-09-28T21:23:39.280474600
import vitis

client = vitis.create_client()
client.set_workspace(path="10_AXI_MB")

platform = client.get_component(name="platform_MB1")
status = platform.build()

comp = client.get_component(name="app_component_MB")
comp.build()

vitis.dispose()

vitis.dispose()

