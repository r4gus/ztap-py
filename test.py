import subprocess

failed = subprocess.call(["pip", "install", "-e", "."])
assert not failed

import ztap

assert ztap.request() == 1
print(ztap.request())
