# 2026-09-29T10:29:41.655427900
import vitis

client = vitis.create_client()
client.set_workspace(path="10_AXI_MB")

platform = client.get_component(name="platform_MB1")
status = platform.build()

comp = client.get_component(name="app_component_MB")
comp.build()

status = platform.build()

comp.build()

