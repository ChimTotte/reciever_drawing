import sys, subprocess
args = sys.argv[1:]
new_args = []
skip = False
for a in args:
    if skip:
        skip = False
        continue
    if a == "-G":
        skip = True
        continue
    new_args.append(a)
new_args = ["-G", "Visual Studio 18 2026"] + new_args
exe = r"C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake_real.exe"
result = subprocess.run([exe] + new_args)
sys.exit(result.returncode)
