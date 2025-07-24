# from subprocess import run
from random import random_ui64

fn gpu_metric_fetch(out ret: String):
    # This is the customizable generic fetcher used to feed metrics to the live GPU pannel.
    # Just modify this to integrate your GPU.
    # That way, it is possible to integrate any GPU brand from the user-side.
    # By defaut, the pannel consume Dummy random metrics.
    
    # CSV format seem like the way to go ! (Fast to parse) Here is the expected format:
    # gpu_name, %utilization, ram_used, ram_total, temperature, %fan, power_usage, power_capacity
    # ...
    # ...
    
    # Some gpu's have smi-like tools can output CSV, 
    # others have tools that can only do JSON, 
    # somes gpus don't even have tools.
    # That is why it is possible to run an posix shell script that returns results in the expected CSV format!
    # For example, some gpu's only have metrics available as virtual files on an linux based OS.

    # Because this app only consume CSV in an specific format, 
    # users only need to provide CSV, no matter what tool or brand of GPU !
    
    # tip: Move the shell script in tmpfs to not do disk I/O every second.
    # var tmp_fetch = run("arbitrary_shell_script_or_tool")

    # Please don't PR any solutions that bring external tools,
    # as good as they are, there are many many GPU's.
    # What is needed is an unified metric format.

    # Some dummy GPU metrics returned in the expected CSV format:
    # ret = String(
    #     "Example Dummy GPU 1, 30, 1024, 2048, 50, 25, 100, 2000",
    #     "\n", #New line
    #     "Example Dummy GPU 2, 95, 2048, 4096, 75, 50, 400, 2500"
    # )
    ret = String(
        "Example Dummy GPU 1, ",random_ui64(70,99),", ",random_ui64(1024,1400),", 2048, 50,",random_ui64(50,100),", 100, 2000",
        "\n", #New line
        "Example Dummy GPU 2, ",random_ui64(0,99),", ",random_ui64(0,4096),", 4096, 50, 20, 400, 2500",
    )
    # Calling this function is done each second (vary, depending on non-gpu fetchers)
