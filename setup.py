from setuptools import setup, Extension
from builder import ZigBuilder

ztap = Extension("ztap", sources=["ztapmodule.zig"])

setup(
    name="ztap",
    version="0.0.1",
    description="CTAP authenticator api",
    ext_modules=[ztap],
    cmdclass={"build_ext": ZigBuilder},
)
