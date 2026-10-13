# 2026-09-29T08:10:01.902691900
import vitis

client = vitis.create_client()
client.set_workspace(path="10_AXI_MB")

vitis.dispose()

