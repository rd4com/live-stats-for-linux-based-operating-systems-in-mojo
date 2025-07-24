from `ui-terminal-mojo` import *
from pathlib import Path
from sys.info import os_is_linux
from sys.param_env import env_get_bool
from Dummy_GPU_metric_fetcher import gpu_metric_fetch


alias page_size = 4096

def TimePassed(mut previous: UInt)->Bool:
    var current = perf_counter_ns()
    if current-previous > 1000000000:
        previous = current
        return True
    return False

def main():
    @parameter
    if not os_is_linux():
        print("The app can run on linux based operating systems")
        return
    constrained[
        os_is_linux(),
        "The app can run on linux based operating systems"
    ]()

    var show_ui_networking = False
    var show_app_pannel = False
    
    var system_infos = SystemInfos()
    system_infos.update_values(show_ui_networking)
    # return
    
    var time = perf_counter_ns()
    
    var selected_overview = 0
    var values_overview = List("LastCreatedPID", "None")
    #TODO add "MostRamUsingPID", "MostCPUUsingPID"


    var ui = UI()
    ui.feature_tab_menu =True
    ui.show_tab_menu = True # Starts showed (tab to toggle)

    var show_cpu_cores = False
    var show_cpu_mhz = False
    var show_all_cooling = False
    var show_all_temp_sensors = False

    
    var show_net_drop = False
    var show_net_interfaces = False
    var net_interfaces_area_hovered = False
    
    var show_ui_networking_plus_button = False
    var show_ui_networking_element_selector = False
    var ui_networking_hidden_elements = List("remote", "inode", "status", "protocol", "local", "rx_tx_queue")
    
    var apps_area_hovered = False
    var show_apps_area_element_selector = False
    var ui_apps_hidden_columns = List("swap_kb","io_read", "io_write", "uptime", "rss_k", "pid", "oom_score", "oom_score_adj")
    var ui_apps_io_unit_type = 0
    var ui_app_selected_pid = Optional[Int](None)
    
    var ui_app_show_selected_pid_hidden_elements = False
    var ui_app_selected_pid_hidden_elements = List[String]()

    var show_next_refresh_progres_bar = False

    var sort_apps_by = 0
    var sort_apps_by_choices = List[String]("uptime", "rss", "swap")

    var show_gpu_pannel = False

    for _ in ui:
        
        @parameter
        fn tab_menu():
            with MoveCursor.BelowThis[StyleBorderSimple, Fg.blue](ui):
                with MoveCursor.BelowThis(ui):
                    Text("Show:") | Fg.blue | Bg.white in ui

                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "Next refresh", show_next_refresh_progres_bar)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "All cooling", show_all_cooling)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "Net drop", show_net_drop)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "Net interfaces", show_net_interfaces)
        ui.set_tab_menu[tab_menu]()

        if show_next_refresh_progres_bar:
            with MoveCursor.BelowThis(ui):
                with MoveCursor.AfterThis(ui):
                    " Next refresh: " in ui
                var _total = (100.0/1000000000.0)*(perf_counter_ns()-time)
                # widget_percent_bar(ui,Int(_total))
                if ui.term_size[0] >= 80:
                    widget_progress_bar_thin[width=64](ui, Int(_total))
                elif ui.term_size[0] >= 120:
                    widget_progress_bar_thin[width=100](ui, Int(_total))
                else:
                    widget_progress_bar_thin(ui, Int(_total))
                _ = ui.zones.pop()

        if TimePassed(time): 
            system_infos.update_values(show_ui_networking)
            if show_app_pannel:
                system_infos.pid_collection.update_values(ui_apps_hidden_columns)
        with MoveCursor.BelowThis(ui):
            with MoveCursor.BelowThis(ui):
                with MoveCursor.BelowThis(ui):
                    for e in system_infos.battery:
                        var percent = (100.0/Float64(e.charge_full))*Float64(e.charge_now)
                        Text("🔋 ",round(percent), "%") | Bg.white | Fg.black in ui
                        # Text("🔋 Battery ",round(percent), "%") | Bg.white | Fg.black in ui
                        if percent <= 33: ui[-1] |= Bg.red
                        elif percent <= 66: ui[-1] |= Bg.yellow
                        else: ui[-1] |= Bg.green
                        if ui[-1].hover():
                            Text(e.charge_now, "/", e.charge_full) in ui



            with MoveCursor.BelowThis(ui):
                
                with MoveCursor.AfterThis(ui):
                # with MoveCursor.AfterThis[StyleBorderCurved](ui):
                    # Text("Temperatures") | Bg.white | Fg.black in ui
                    var avg_temp_sensors = Float64(0.0)
                    var highest_temp_sensors = Float64(0.0)
                    for e in system_infos.thermal_sensors: 
                        avg_temp_sensors+=Float64(e.temp)/1000.0
                        if Float64(e.temp) > highest_temp_sensors: 
                            highest_temp_sensors = e.temp
                    avg_temp_sensors/=Float64(len(system_infos.thermal_sensors))
                    # " " in ui
                    highest_temp_sensors /=1000.0
                    with MoveCursor.BelowThis(ui):
                        var value_txt = String(round(highest_temp_sensors),"°C")
                        with MoveCursor.AfterThis(ui):
                            Text(" "*(17-len(value_txt))) in ui
                        with MoveCursor.AfterThis(ui):
                            Text(value_txt) in ui
                            if highest_temp_sensors < 50.0: ui[-1] |= Fg.green 
                            elif avg_temp_sensors < 60: ui[-1] |= Bg.yellow
                            else: ui[-1] |= Bg.red
                        if ui[-1].hover():
                            show_all_temp_sensors = True
                        else:
                            show_all_temp_sensors = False
                        # with MoveCursor.AfterThis(ui):
                        #     Text("highest   ") in ui
                    #TODO add for example to average: +1 or -4 for differences

                    # widget_checkbox(ui, "Show all", show_all_temp_sensors)
                    if show_all_temp_sensors:
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.thermal_sensors:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.type) | Fg.cyan in ui
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.thermal_sensors:
                                with MoveCursor.BelowThis(ui):
                                    Text(Float64(e.temp/1000.0)) in ui
                                    if Float64(e.temp/1000.0) >= 60:
                                        ui[-1] |= Bg.red

                with MoveCursor.AfterThis(ui):
                    with MoveCursor.BelowThis(ui):
                        # with MoveCursor.BelowThis(ui):
                        # with MoveCursor.AfterThis(ui):
                        #     Text("Coolers:") | Bg.blue in ui
                        for e in system_infos.cooling:
                            var e_to_percent = (100.0/Float64(e.max_state))*Float64(e.cur_state)
                            var to_speed = round((8.0/100.0)*e_to_percent)
                            if e_to_percent != 0:
                                if to_speed == 0: 
                                    to_speed = 1
                            with MoveCursor.AfterThis(ui):
                                if to_speed == 0: Text("|") in ui
                                elif to_speed == 1: spinner[1](ui)
                                elif to_speed == 2: spinner[2](ui)
                                elif to_speed == 3: spinner[3](ui)
                                elif to_speed == 4: spinner[4](ui)
                                elif to_speed == 5: spinner[5](ui)
                                elif to_speed == 6: spinner[6](ui)
                                elif to_speed == 7: spinner[7](ui)
                                else: spinner[8](ui)
                                if to_speed != 0: ui[-1] |= Fg.blue
                                if ui[-1].hover():
                                    with MoveCursor.AfterThis(ui):
                                        with MoveCursor.AfterThis(ui):
                                            Text(e.type) | Fg.blue in ui
                                        with MoveCursor.AfterThis(ui):
                                            Text(e.cur_state) in ui
                                        with MoveCursor.AfterThis(ui):
                                            Text("/") | Fg.blue in ui
                                        with MoveCursor.BelowThis(ui):
                                            Text(e.max_state) in ui
                    if show_all_cooling:
                        with MoveCursor.BelowThis(ui):
                            with MoveCursor.AfterThis(ui):
                                for e in system_infos.cooling:
                                    with MoveCursor.BelowThis(ui):
                                        Text(e.type) | Fg.blue in ui
                            with MoveCursor.AfterThis(ui):
                                for e in system_infos.cooling:
                                    with MoveCursor.BelowThis(ui):
                                        Text(e.cur_state) in ui
                            with MoveCursor.AfterThis(ui):
                                for _ in system_infos.cooling:
                                    with MoveCursor.BelowThis(ui):
                                        Text("/") | Fg.blue in ui
                            with MoveCursor.AfterThis(ui):
                                for e in system_infos.cooling:
                                    with MoveCursor.BelowThis(ui):
                                        Text(e.max_state) in ui

                with MoveCursor.AfterThis(ui):
                    " " in ui
                with MoveCursor.AfterThis(ui):
                # with MoveCursor.BelowThis[StyleBorderSimple](ui):
                    with MoveCursor.BelowThis(ui):
                        with MoveCursor.AfterThis(ui):
                            var percent_tmp_ram = Float64(100.0)/Float64(system_infos.ram_stats.total)
                            percent_tmp_ram*=Float64(system_infos.ram_stats.available)
                            var percent_tmp_ram2 = 100-Int(round(percent_tmp_ram))
                            Text(percent_tmp_ram2, "% 🧮 RAM") in ui
                            if percent_tmp_ram2 >= 66: 
                                ui[-1] |= Bg.red
                                # widget_percent_bar_with_speed[Fg.red](ui, percent_tmp_ram2, 0)
                            elif percent_tmp_ram2 >= 33: 
                                ui[-1] |= Bg.yellow
                                # widget_percent_bar_with_speed[Fg.yellow](ui, percent_tmp_ram2, 0)
                            else: 
                                ui[-1] |= Bg.green
                                # widget_percent_bar_with_speed[Fg.green](ui, percent_tmp_ram2, 0)
                            
                            if ui[-1].hover():
                                with MoveCursor.BelowThis(ui):
                                    Text(system_infos.ram_stats.available//1024, "Mb") | Fg.cyan in ui

                                Text("Available") in ui
                            # Text("RamFree") | Bg.white | Fg.black in ui
                            # Text(system_infos.ram_stats.free) | Fg.cyan in ui
                with MoveCursor.AfterThis(ui):
                    " " in ui
            with MoveCursor.AfterThis(ui):              
                with MoveCursor.AfterThis(ui):
                # with MoveCursor.AfterThis[StyleBorderSimple](ui):
                    with MoveCursor.BelowThis(ui):
                        var tmp_max_freq = system_infos.cpu_max_freq//1000
                        var avg = 0.0
                        for e in system_infos.cpu_infos: avg+=e.mhz
                        avg /= Float64(len(system_infos.cpu_infos))
                        var percent = (100.0/Float64(tmp_max_freq))*avg

                        with MoveCursor.BelowThis(ui):
                            with MoveCursor.BelowThis(ui):
                                widget_plot(ui, system_infos.freq_over_time)
                            with MoveCursor.AfterThis(ui):
                                Text("MHz") | Bg.white | Fg.black in ui
                                ui[-1].data.value = ui[-1].data.value.center(width=16)
                                if ui[-1].hover():
                                    show_cpu_mhz = True
                                else:
                                    show_cpu_mhz = False
                        with MoveCursor.BelowThis(ui):
                            # with MoveCursor.AfterThis(ui):
                            #     "avg " in ui
                            widget_progress_bar_thin[width=12](ui, UInt8(percent))
                        if show_cpu_mhz:

                            with MoveCursor.BelowThis(ui):
                                with MoveCursor.AfterThis(ui):
                                    for e in system_infos.cpu_infos:
                                        with MoveCursor.BelowThis(ui):
                                            Text(Int(e.mhz)) | Fg.cyan in ui
                                with MoveCursor.AfterThis(ui):
                                    for _ in system_infos.cpu_infos:
                                        with MoveCursor.BelowThis(ui):
                                            "Mhz" in ui
                            with MoveCursor.BelowThis(ui):
                                with MoveCursor.BelowThis(ui):
                                    Text("Avg: ", String(Int(avg)).ljust(5)) in ui
                                with MoveCursor.AfterThis(ui):
                                    Text("Max: ", tmp_max_freq) in ui
                        # with MoveCursor.BelowThis(ui):


                    


                        # with MoveCursor.BelowThis(ui):
                        #     with MoveCursor.AfterThis(ui): Text(" ") in ui
                        #     with MoveCursor.AfterThis(ui):
                        #         widget_value_selector[""](ui, selected_overview, values_overview)
                        #     with MoveCursor.AfterThis(ui): Text(" ") in ui
                        #     with MoveCursor.AfterThis(ui):
                        #         if selected_overview == 0:
                        #
                        #             with MoveCursor.AfterThis(ui):
                        #                 Text(system_infos.last_created_pid.pid) | Fg.yellow in ui
                        #             with MoveCursor.AfterThis(ui): Text(" ") in ui
                        #             Text(system_infos.last_created_pid.cmd) | Fg.magenta in ui
                        #         elif selected_overview == 1: ...
                    
                        # with MoveCursor.AfterThis[StyleBorderDouble, Fg.magenta](ui):
                with MoveCursor.AfterThis(ui):
                    " " in ui
                with MoveCursor.AfterThis(ui):
                    with MoveCursor.AfterThis(ui):
                    # with MoveCursor.AfterThis[StyleBorderSimple](ui):
                        with MoveCursor.BelowThis(ui):
                            with MoveCursor.BelowThis(ui):
                                widget_plot(ui, system_infos.cpu0_over_time)
                            with MoveCursor.AfterThis(ui):
                                Text("CPU") | Bg.white | Fg.black in ui
                                ui[-1].data.value = ui[-1].data.value.center(width=16)
                                if ui[-1].hover():
                                    show_cpu_cores = True
                                else:
                                    show_cpu_cores = False
                        with MoveCursor.BelowThis(ui):
                            with MoveCursor.AfterThis(ui):
                                for e in system_infos.proc_stats_deltas:
                                    with MoveCursor.BelowThis(ui):
                                        var tmp_delta_sum = e.user + e.nice + e.system + e.idle + e.iowait + e.irq + e.soft_irq + e.steal
                                        var tmp_idle_sum = e.idle + e.iowait
                                        var percent = 100.0 * Float64(tmp_delta_sum - tmp_idle_sum) / Float64(tmp_delta_sum);
                                        if e.name == "cpu":
                                            with MoveCursor.BelowThis(ui):
                                                widget_progress_bar_thin[width=12](ui, UInt8(percent))
                                        # Text(" ", round(percent),"%") in ui
                                        else:
                                            if show_cpu_cores:
                                                widget_progress_bar_thin[theme = Fg.magenta, width=12](ui, UInt8(percent))
            with MoveCursor.AfterThis(ui):
                " " in ui
            with MoveCursor.AfterThis(ui):
            # with MoveCursor.AfterThis[StyleBorderSimple](ui):
                with MoveCursor.AfterThis(ui):
                    if show_net_interfaces:
                        with MoveCursor.AfterThis(ui):
                            Text("🛜") in ui
                            for e in system_infos.network_deltas:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.name) | Bg.magenta in ui
                    with MoveCursor.AfterThis(ui):
                        Text("rx bytes") | Fg.cyan in ui
                        for e in system_infos.network_deltas:
                            with MoveCursor.BelowThis(ui):
                                if e.rx_bytes != 0:
                                    Text(e.rx_bytes) | Bg.cyan in ui
                                    #TODO better:
                                else:
                                    #TODO better:
                                    Text(e.rx_bytes) in ui
                                    # Text(" ") in ui
                    with MoveCursor.AfterThis(ui): " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("tx bytes") | Fg.green in ui
                        for e in system_infos.network_deltas:
                            with MoveCursor.BelowThis(ui):
                                if e.tx_bytes != 0:
                                    #TODO better:
                                    Text(e.tx_bytes) | Bg.green in ui
                                else:
                                    #TODO better:
                                    # Text(" ") in ui
                                    Text(e.tx_bytes) in ui
                    if show_net_drop:
                        with MoveCursor.AfterThis(ui):
                            Text("drop") in ui
                            for e in system_infos.network_deltas:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.drop) in ui
                        with MoveCursor.AfterThis(ui): " " in ui
                        with MoveCursor.AfterThis(ui):
                            Text("link quality") in ui
                            for e in system_infos.network_deltas:
                                with MoveCursor.BelowThis(ui):
                                    if e.link_quality:
                                        with MoveCursor.AfterThis(ui):
                                            Text(e.link_quality.value()) in ui
                                            if e.link_quality.value()>=35:
                                                ui[-1] |= Fg.green
                                            else:
                                                ui[-1] |= Bg.yellow
                                        with MoveCursor.AfterThis(ui):
                                            Text("/") | Fg.blue in ui
                                        with MoveCursor.AfterThis(ui):
                                            Text("70") in ui
                                    else:
                                        Text(" ") in ui

        with MoveCursor.BelowThis(ui):
            " " in ui

        with MoveCursor.BelowThis[StyleBorderCurved](ui):
            @parameter
            fn gpu_pannel_toggle():
                Text("GPU") | Bg.white | Fg.black in ui
                if ui[-1].click():
                    show_gpu_pannel = ~show_gpu_pannel
                if ui[-1].hover():
                    ui[-1].data.value += " (Click to toggle gpu pannel)" 
                    ui[-1] |= Bg.magenta
            if show_gpu_pannel:
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        gpu_pannel_toggle()
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                gpu.name in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Utilization") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                widget_percent_bar_with_speed(ui,gpu.utilization_pct , 0)
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Consumption") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                with MoveCursor.AfterThis(ui):
                                    Text(Int(round(gpu.power_usage))) in ui
                                with MoveCursor.AfterThis(ui):
                                    Text("/") | Fg.cyan in ui
                                with MoveCursor.AfterThis(ui):
                                    Text(Int(round(gpu.power_capacity))) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Memory used") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                var tmp_pct_gpu = 100.0/Float64(gpu.mem_total)
                                tmp_pct_gpu *= Float64(gpu.mem_used)
                                widget_progress_bar_thin[width=10](ui, Int(round(tmp_pct_gpu)))
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Memory total") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                Text(Int(round(gpu.mem_total))) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Temperature") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                Text(Int(round(gpu.temperature))) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("%Fan") in ui
                        for gpu in system_infos.gpu_collection.gpus:
                            with MoveCursor.BelowThis(ui):
                                Text(Int(round(gpu.fan_pct))) in ui
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        widget_plot(ui, system_infos.gpu_collection.avg_fan_over_time)
                        Text("Fan avg") | Bg.white | Fg.black in ui
                        ui[-1].data.value = ui[-1].data.value.center(width=16)
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        widget_plot(ui, system_infos.gpu_collection.avg_util_over_time)
                        Text("Util avg") | Bg.white | Fg.black in ui
                        ui[-1].data.value = ui[-1].data.value.center(width=16)
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                        with MoveCursor.AfterThis(ui):
                            "Time to fetch:" in ui
                            ui[-1] |= Bg.blue
                        Text(" ", system_infos.gpu_collection.time_to_fetch, " ns") in ui
            else:
                gpu_pannel_toggle()

        with MoveCursor.AfterThis[StyleBorderCurved](ui) as networking_area:
            # Text(len(system_infos.networking_app)) in ui
            with MoveCursor.BelowThis(ui):
                # with MoveCursor.AfterThis(ui):
                #     animate_emojis[List[String]("🌍","🌎", "🌏")](ui)
                #     ui[-1] |= Bg.white
                with MoveCursor.AfterThis(ui):
                    Text("📻 Networking") | Bg.white | Fg.black in ui
                    if ui[-1].click():
                        show_ui_networking = ~show_ui_networking
                    if ui[-1].hover():
                        Text("Click (Enter) to toggle") | Bg.blue in ui
            
            if show_ui_networking:
                " " in ui
                if len(ui_networking_hidden_elements):
                    if show_ui_networking_plus_button:
                        "➕" in ui
                        if ui[-1].click():
                            show_ui_networking_element_selector = ~show_ui_networking_element_selector
                        if ui[-1].hover():
                            Text("Click to toggle columns customizer") | Bg.blue in ui
                
                if show_ui_networking_element_selector:
                    for i in range(len(ui_networking_hidden_elements)):
                        Text("[+]", ui_networking_hidden_elements[i]) in ui
                        ui[-1] |= Fg.red
                        if ui[-1].click(): 
                            _ = ui_networking_hidden_elements.pop(i)
                with MoveCursor.BelowThis(ui):
                    if "status" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("Status") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("status")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.st, " ") in ui
                    if "local" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("Local") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("local")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    @parameter
                                    if env_get_bool["is_demo", False]():
                                        Text("blurred for demo ") in ui
                                    else:
                                        Text(e.local, " ") in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Ports") in ui 
                        for e in system_infos.networking_app:
                            with MoveCursor.BelowThis(ui):
                                Text(e.port_local, " ") in ui
                    with MoveCursor.AfterThis(ui):
                        Text(" ") in ui# | Bg.white | Fg.black in ui 
                        for e in system_infos.networking_app:
                            with MoveCursor.BelowThis(ui):
                                Text(e.port_remote, " ") in ui
                    if "remote" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("Remote") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("remote")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    @parameter
                                    if env_get_bool["is_demo", False]():
                                        Text("blurred for demo ") in ui
                                    else:
                                        Text(e.remote, " ") in ui
                    with MoveCursor.AfterThis(ui):
                        Text("App") in ui 
                        for e in system_infos.networking_app:
                            with MoveCursor.BelowThis(ui):
                                Text(e.comm, " ") | Fg.blue in ui
                    if "protocol" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("Protocol ") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("protocol")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    Text(["tcp","udp"][e.tcp_udp]) in ui
                    if "rx_tx_queue" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("rx_queue") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("rx_tx_queue")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.rx_queue) in ui
                        with MoveCursor.AfterThis(ui):
                            Text("tx_queue") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("rx_tx_queue")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.tx_queue) in ui
                    if "inode" not in ui_networking_hidden_elements:
                        with MoveCursor.AfterThis(ui):
                            Text("Inode") in ui 
                            if ui[-1].click(): ui_networking_hidden_elements.append("inode")
                            if ui[-1].hover(): ui[-1] |= Bg.red
                            for e in system_infos.networking_app:
                                with MoveCursor.BelowThis(ui):
                                    Text(e.inode) in ui
                Text("TCP6/UDP6 unfetched.") in ui
            if networking_area.hover():
                show_ui_networking_plus_button = True
            else:
                show_ui_networking_element_selector = False
                show_ui_networking_plus_button = False
        
        with MoveCursor.AfterThis[StyleBorderCurved](ui) as apps_area:
            # app_panel.render()
            Text("📱 Apps") | Bg.magenta in ui
            if ui[-1].click():
                show_app_pannel = ~show_app_pannel
            if ui[-1].hover():
                Text("Click (Enter) to toggle") | Bg.blue in ui
            

            if show_app_pannel:
                " " in ui
                if apps_area_hovered:

                    input_buffer["Filter:"](ui, system_infos.pid_collection.filter_edit_buffer, system_infos.pid_collection.filter_is_edit)
                    if len(ui_apps_hidden_columns):
                        Text("➕") in ui
                        if ui[-1].click():
                            show_apps_area_element_selector = ~show_apps_area_element_selector
                        if ui[-1].hover():
                            Text("Click to toggle columns customizer") | Bg.blue in ui
                    Text("ℹ️") in ui
                    if ui[-1].hover():
                        with MoveCursor.BelowThis[StyleBorderCurved, Fg.green](ui):
                            Text("- Apps in the list can be clicked!") in ui
                            Text("- Columns can be clicked!") in ui
                    # ui_apps_io_unit_type
                    if show_apps_area_element_selector:
                        widget_checkbox(ui, "Ignore zero rss pids", system_infos.pid_collection.ignore_zero_rss_entries)
                        for i in range(len(ui_apps_hidden_columns)):
                            Text("[+]", ui_apps_hidden_columns[i]) in ui
                            ui[-1] |= Fg.red
                            if ui[-1].click(): 
                                _ = ui_apps_hidden_columns.pop(i)
                    if ("io_read" in ui_apps_hidden_columns) and ("io_write" in ui_apps_hidden_columns):
                        ...
                    else:
                        widget_value_selector["IO unit"](ui, ui_apps_io_unit_type, List("Mb","Kb","B"))

                    with MoveCursor.BelowThis[StyleBorderCurved](ui):
                        with MoveCursor.AfterThis(ui):
                            Text(" ") in ui
                            ui[-1].data.replace_each_when_render = "↑"
                            if system_infos.pid_collection.sort_apps_smallest_first == False:
                                ui[-1] |= Bg.green
                            if ui[-1].click():
                                system_infos.pid_collection.sort_apps_smallest_first = False
                        with MoveCursor.AfterThis(ui):
                            Text(" ") in ui
                            ui[-1].data.replace_each_when_render = "↓"
                            if system_infos.pid_collection.sort_apps_smallest_first == True:
                                ui[-1] |= Bg.green
                            if ui[-1].click():
                                system_infos.pid_collection.sort_apps_smallest_first = True

                        with MoveCursor.AfterThis(ui):
                            " " in ui
                        widget_value_selector["Sort by:"](ui, system_infos.pid_collection.sort_apps_by,  sort_apps_by_choices)

                if "pid" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        "PID" in ui
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("pid")
                        for e in system_infos.pid_collection.values:
                            Text(e.PID) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui

                if "uptime_h_m" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("h ") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("uptime_h_m")
                        for e in system_infos.pid_collection.values:
                            var tmp_uptime = ((system_infos.uptime*100)-e.start_time)/100.0
                            var tmp_uptime2 = Int((tmp_uptime/60/60).__floor__())
                            if tmp_uptime2 > 0: Text(tmp_uptime2) in ui
                            else: " " in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                    with MoveCursor.AfterThis(ui):
                        Text("m ") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("uptime_h_m")
                        for e in system_infos.pid_collection.values:
                            var tmp_uptime = ((system_infos.uptime*100)-e.start_time)/100.0
                            var tmp_uptime2 = Int((tmp_uptime/60).__floor__())%60
                            if tmp_uptime2 > 0: Text(tmp_uptime2) in ui
                            else: " " in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "uptime" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("uptime") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("uptime")
                        for e in system_infos.pid_collection.values:
                            var tmp_uptime = ((system_infos.uptime*100)-e.start_time)/100.0
                            Text(Int(tmp_uptime.__floor__())) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "rss_m" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("rss[Mb]") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("rss_m")
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.pid_collection.values:
                                var tmp_rss_gbyte = (e.rss>>20)
                                if tmp_rss_gbyte:
                                    Text(tmp_rss_gbyte) in ui
                                else:
                                    Text(" ") in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "rss_k" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("rss[Kb]") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("rss_k")
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.pid_collection.values:
                                var tmp_rss_gbyte = (e.rss>>10)&1023
                                if tmp_rss_gbyte:
                                    Text(tmp_rss_gbyte) in ui
                                else:
                                    Text(" ") in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "swap_kb" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("swap[Kb]") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("swap_kb")
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.pid_collection.values:
                                if e.swap_kb:
                                    Text(e.swap_kb) in ui
                                else:
                                    Text(" ") in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                with MoveCursor.AfterThis(ui):
                    "App" in ui
                    for e in system_infos.pid_collection.values:
                        Text(e.COMM) in ui
                        if ui[-1].click():
                            ui_app_selected_pid = e.PID
                        if ui[-1].hover():
                            ui[-1] |= Bg.blue
                            ui[-1].data.value = String(ui[-1].data.value, " 📌 (Pin)")
                with MoveCursor.AfterThis(ui):
                    " " in ui
                if "io_read" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("io_r") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("io_read")
                        for e in system_infos.pid_collection.values:
                            if e.io[0]!=0:
                                var tmp_io_read_val = e.io[0]
                                if ui_apps_io_unit_type == 0:
                                    tmp_io_read_val >>= 20
                                elif ui_apps_io_unit_type == 1:
                                    tmp_io_read_val >>= 10
                                if tmp_io_read_val:
                                    Text(tmp_io_read_val) in ui
                                else:
                                    if e.io[0]:
                                        "<1" in ui
                                    else:
                                        " " in ui
                            else:
                                " " in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "io_write" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("io_w") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("io_write")
                        for e in system_infos.pid_collection.values:
                            if e.io[1]:
                                var tmp_io_write_val = e.io[1]
                                if ui_apps_io_unit_type == 0:
                                    tmp_io_write_val >>= 20
                                elif ui_apps_io_unit_type == 1:
                                    tmp_io_write_val >>= 10
                                if tmp_io_write_val:
                                    Text(tmp_io_write_val) in ui
                                else:
                                    if e.io[1]:
                                        "<1" in ui
                                    else:
                                        " " in ui
                            else:
                                " " in ui 
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "oom_score" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("oom_score") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("oom_score")
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.pid_collection.values:
                                Text(e.oom_score) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                if "oom_score_adj" not in ui_apps_hidden_columns:
                    with MoveCursor.AfterThis(ui):
                        Text("oom_score_adj") in ui 
                        if ui[-1].hover(): ui[-1] |= Bg.red
                        if ui[-1].click(): ui_apps_hidden_columns.append("oom_score_adj")
                        with MoveCursor.AfterThis(ui):
                            for e in system_infos.pid_collection.values:
                                Text(e.oom_score_adj) in ui
                    with MoveCursor.AfterThis(ui):
                        " " in ui
                # Running/Sleep
                # with MoveCursor.AfterThis(ui):
                #     for e in system_infos.pid_collection.values:
                #         e.current_state in ui
                #         if e.current_state == "R": ui[-1] |= Bg.green
            apps_area_hovered = apps_area.hover()
        if ui_app_selected_pid:
            with MoveCursor.AfterThis[StyleBorderDouble](ui) as pinned_apps_area:
                Text("📌 Pinned: ", ui_app_selected_pid.value()) | Bg.green in ui
                Text("Unpin") | Bg.red in ui
                if ui[-1].click():
                    ui_app_selected_pid = None
                if ui[-1].hover():
                    "⬆️ Click to unpin" in ui
                " " in ui
                if len(ui_app_selected_pid_hidden_elements) == 0:
                    "ℹ️  Columns can be clicked to be toggled" in ui
                "➕" in ui
                if ui[-1].click():
                    ui_app_show_selected_pid_hidden_elements = ~ui_app_show_selected_pid_hidden_elements
                if ui[-1].hover():
                    "^Click to toggle columns menu" in ui
                    ui[-1] |= Bg.blue
                if ui_app_show_selected_pid_hidden_elements:
                    var tmp_idx = 0
                    for v in ui_app_selected_pid_hidden_elements:
                        v in ui
                        ui[-1] |= Fg.red
                        if ui[-1].hover():
                            ui[-1].data.value += "➕"
                            ui[-1] |= Fg.green
                        if ui[-1].click():
                            _ = ui_app_selected_pid_hidden_elements.pop(tmp_idx)
                            break
                        tmp_idx+=1
                try:
                    if ui_app_selected_pid.__bool__() == False:
                        raise "Error"
                    var p = (Path("/proc")/Path(String(ui_app_selected_pid.value()))/"status").read_text().split("\n")
                    for ref tmp_entry in p:
                        var splitted = tmp_entry.strip().split(":")
                        if len(splitted) == 2:
                            var tmp_splitted_0 = String(splitted[0].strip())
                            if tmp_splitted_0 not in ui_app_selected_pid_hidden_elements:
                                with MoveCursor.BelowThis(ui):
                                    Text(tmp_splitted_0) in ui
                                    ui[-1] |= Bg.white
                                    ui[-1] |= Fg.black
                                    if ui[-1].click():
                                        if tmp_splitted_0 not in ui_app_selected_pid_hidden_elements:
                                            ui_app_selected_pid_hidden_elements.append(tmp_splitted_0)
                                    if ui[-1].hover():
                                        ui[-1] |= Bg.red
                                        "Click to remove column" in ui
                                        ui[-1] |= Bg.magenta
                                    Text(splitted[1].strip()) in ui
                except e:
                    # if error, set to none !
                    ui_app_selected_pid = None


@fieldwise_init
struct CoolingDevice(Movable, Copyable):
    var path: Path
    var type: String
    var cur_state: Int
    var max_state: Int
    fn update_values(mut self):
        try:
            self.type = (self.path/"type").read_text().split("\n")[0]
            self.cur_state = Int((self.path/"cur_state").read_text())
            self.max_state = Int((self.path/"max_state").read_text())
        except e: ...
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        path = Path("/sys/class/thermal")
        try:
            var tmp = path.listdir()
            for d in tmp:
                d_list = (path/d).listdir()
                if "type" in d_list and "cur_state" in d_list and "max_state" in d_list:
                    ret.append(
                        CoolingDevice(
                            path/d, "",0, 0
                        )
                    )

        except e:
            ...
        for ref d in ret: d.update_values()

@fieldwise_init
struct ThermalSensor(Movable, Copyable):
    var path: Path
    var type: String
    var temp: Int
    fn update_values(mut self):
        try:
            self.type = (self.path/"type").read_text().split("\n")[0]
            self.temp = Int((self.path/"temp").read_text())
        except e: ...
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        path = Path("/sys/class/thermal")
        try:
            var tmp = path.listdir()
            for d in tmp:
                d_list = (path/d).listdir()
                if "temp" in d_list and "type" in d_list:
                    ret.append(
                        ThermalSensor(
                            path/d, "",0
                        )
                    )

        except e:
            ...
        for ref d in ret: d.update_values()
@fieldwise_init
struct CpuInfo(Movable, Copyable):
    var mhz: Float64
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        try:
            path = Path("/proc/cpuinfo").read_text().split("\n")
            for l in path:
                if l.startswith("cpu MHz"):
                    ret.append(CpuInfo(Float64(l.split(":")[1])))
        except e: ...

@fieldwise_init
struct Battery(Movable, Copyable):
    var path: Path
    var charge_now: Int
    var charge_full: Int
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        try:
            path = Path("/sys/class/power_supply/")
            devices = path.listdir()
            for l in devices:
                if String(l).startswith("BAT"):
                    var charge_now = Int((path/l/"charge_now").read_text())
                    var charge_full = Int((path/l/"charge_full").read_text())
                    ret.append(Self(path/l, charge_now, charge_full))
        except e: ...
    fn update_values(mut self):
        try:
            self.charge_now = Int((self.path/"charge_now").read_text())
            self.charge_full = Int((self.path/"charge_full").read_text())
        except e: ...

@fieldwise_init
struct ProcStat(Movable, Copyable):
    var name: String
    var user: Int64
    var nice: Int64
    var system: Int64
    var idle: Int64
    var iowait: Int64
    var irq: Int64
    var soft_irq: Int64
    var steal: Int64
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        var path = Path("/proc/stat")
        try:
            var res = path.read_text().splitlines()
            for entry in res:
                if entry.startswith("cpu"):
                    var cols = entry.split(" ")
                    for i in reversed(range(0, len(cols))):
                        if len(cols[i]) == 0: _ = cols.pop(i)
                    var tmp_stat = Self(
                        cols[0],
                        Int(cols[1]),
                        Int(cols[2]),
                        Int(cols[3]),
                        Int(cols[4]),
                        Int(cols[5]),
                        Int(cols[6]),
                        Int(cols[7]),
                        Int(cols[8])
                    )
                    ret.append(tmp_stat)
        except e: ...
    @staticmethod
    fn to_deltas(mut stats: List[List[ProcStat]], out ret: List[ProcStat]):
        ret = []
        # assert len(stats[0]) == len(stats[1])
        total_entries = len(stats[0])
        for i in range(total_entries):
            ret.append(
                ProcStat(
                    stats[0][i].name,
                    stats[1][i].user - stats[0][i].user,
                    stats[1][i].nice - stats[0][i].nice,
                    stats[1][i].system - stats[0][i].system,
                    stats[1][i].idle - stats[0][i].idle,
                    stats[1][i].iowait - stats[0][i].iowait,
                    stats[1][i].irq - stats[0][i].irq,
                    stats[1][i].soft_irq - stats[0][i].soft_irq,
                    stats[1][i].steal - stats[0][i].steal
                )
            )

@fieldwise_init
struct Network(Movable, Copyable):
    var name: String
    var rx_bytes: Int64
    var tx_bytes: Int64
    var drop: Int64
    var link_quality: Optional[UInt8]
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []
        var path = Path("/proc/net/dev")
        try:
            var res = path.read_text().splitlines()[2:]
            for d in res: 
                var tmp_d = d.split(" ")
                for i in reversed(range(0, len(tmp_d))):
                    if len(tmp_d[i]) == 0: _ = tmp_d.pop(i)
                ret.append(
                    Self(
                        tmp_d[0], Int(tmp_d[1]), Int(tmp_d[9]), Int(tmp_d[4]) + Int(tmp_d[12]), None
                    )
                )
        except e: ...
    @staticmethod
    fn to_deltas(mut stats: List[List[Self]], out ret: List[Self]):
        ret = []
        # assert len(stats[0]) == len(stats[1])
        total_entries = len(stats[0])
        for i in range(total_entries):
            ret.append(
                Self(
                    stats[0][i].name,
                    stats[1][i].rx_bytes - stats[0][i].rx_bytes,
                    stats[1][i].tx_bytes - stats[0][i].tx_bytes,
                    stats[1][i].drop, #no delta
                    None
                )
            )
        #link_quality
        try:
            var tmp_path = Path("/proc/net/wireless").read_text().split("\n")
            for _ in range(2): _ = tmp_path.pop(0)
            for dev in tmp_path:
                var tmp_cols = dev.split(" ")
                for i in reversed(range(0, len(tmp_cols))):
                    if len(tmp_cols[i]) == 0: _ = tmp_cols.pop(i)
                for ref r in ret:
                    if r.name == tmp_cols[0]:
                        r.link_quality = UInt8(Float64(tmp_cols[2]))
        except e: ...


struct NetworkingApp(Movable, Copyable):
    var inode: Int
    var comm: String
    var local: SIMD[DType.uint8, 4]
    var port_local: UInt64
    var port_remote: UInt64
    var remote: SIMD[DType.uint8, 4]
    var st: UInt8
    var tcp_udp: UInt8
    var tx_queue: Int
    var rx_queue: Int
    alias st_values = [
        "ESTABLISHED", "SYN_SENT", "SYN_RECV",
        "FIN_WAIT1", "FIN_WAIT2", "TIME_WAIT",
        "CLOSE", "CLOSE_WAIT", "LAST_ACK",
        "LISTEN", "CLOSING"
    ] #0-> 11
    fn __init__(out self):
        self.inode = 0
        self.local = 0
        self.remote = 0
        self.port_remote = 0
        self.port_local = 0
        self.st = 0
        self.tcp_udp = 0
        self.comm = String("")
        self.tx_queue = 0
        self.rx_queue = 0
    @staticmethod
    fn get_all(out ret: List[Self]):
        ret = []

        @parameter
        fn _get_all(p:Path, tcp_udp:UInt8):
            try:
                var data = p.read_text().split("\n")
                for n in data[1:]:
                    if len(n)==0: continue
                    var splitted = n.split(" ")
                    for i in reversed(range(len(splitted))):
                        if len(splitted[i]) == 0: _ = splitted.pop(i)
                    var tmp_entry = NetworkingApp()
                    tmp_entry.inode = Int(splitted[9])
                    try:
                        tmp_entry.local[0] = Int(splitted[1][0:2], base=16)
                        tmp_entry.local[1] = Int(splitted[1][2:4], base=16)
                        tmp_entry.local[2] = Int(splitted[1][4:6], base=16)
                        tmp_entry.local[3] = Int(splitted[1][6:8], base=16)
                        tmp_entry.remote[0] = Int(splitted[2][0:2], base=16)
                        tmp_entry.remote[1] = Int(splitted[2][2:4], base=16)
                        tmp_entry.remote[2] = Int(splitted[2][4:6], base=16)
                        tmp_entry.remote[3] = Int(splitted[2][6:8], base=16)
                        tmp_entry.remote = tmp_entry.remote.reversed()
                        tmp_entry.local = tmp_entry.local.reversed()
                        tmp_entry.port_local = Int(splitted[1][9:], base=16)
                        tmp_entry.port_remote = Int(splitted[2][9:], base=16)
                        tmp_entry.st = Int(splitted[3], base=16)
                        tmp_entry.tcp_udp = tcp_udp
                        var tmp_split_tx_rx = splitted[4].split(":")
                        tmp_entry.tx_queue = Int(tmp_split_tx_rx[0], base=16)
                        tmp_entry.rx_queue = Int(tmp_split_tx_rx[1], base=16)
                    except e: ...
                    ret.append(tmp_entry)

            except e: ... #print(e)
        _get_all("/proc/net/tcp", 0)
        _get_all("/proc/net/udp", 1)
        try:
            var pids = Path("/proc").listdir()
            for p in pids:
                if String(p).isdigit() and (Path("/proc")/p).is_dir():
                    try:
                        var tmp_fds = Path("/proc")/p/"fd"
                        var tmp_list = tmp_fds.listdir()
                        for tmp_f in tmp_list:
                            try:
                                var tmp_f_st_ino = (tmp_fds/tmp_f).stat().st_ino
                                for ref r in ret:
                                    if tmp_f_st_ino== r.inode:
                                        r.comm = "ok"
                                        r.comm = String((Path("/proc")/p/"comm").read_text().strip())
                            except e: ...
                    except e: ...
        except e: ...



@fieldwise_init
struct LastCreatedPID(Movable, Copyable):
    var pid: Int
    var cmd: String
    fn __init__(out self):
        self.pid = 1
        self.cmd = ""
        self.update_values()
    fn update_values(mut self):
        try:
            var data = Path("/proc/loadavg").read_text().split(" ")[4]
            self.pid = Int(data)
            var cmd = Path("/proc")/String(self.pid)/"comm"
            self.cmd = cmd.read_text()
        except e:...

    # @staticmethod
    # fn get_all(out ret: List[Self]):

@fieldwise_init
struct RamStat(Movable, Copyable):
    var total: Int64
    var free: Int64
    var available: Int64
    fn __init__(out self):
        self.total = 0
        self.free = 0
        self.available = 0
        var path = Path("/proc/meminfo")
        try:
            var res = path.read_text().splitlines()
            idx = 0
            for d in res: 
                var tmp_d = d.split(" ")
                for i in reversed(range(0, len(tmp_d))):
                    if len(tmp_d[i]) == 0: _ = tmp_d.pop(i)
                if idx == 0: self.total = Int(tmp_d[1])
                elif idx == 1: self.free = Int(tmp_d[1])
                elif idx == 2: self.available = Int(tmp_d[1])
                idx+=1
                if idx == 3: break
        except e: ...

struct SystemInfos:
    var cooling: List[CoolingDevice]
    var thermal_sensors: List[ThermalSensor]
    var cpu_infos: List[CpuInfo]
    var proc_stats: List[List[ProcStat]]
    var proc_stats_deltas: List[ProcStat]
    var battery: List[Battery]
    var network_stats: List[List[Network]]
    var network_deltas: List[Network]
    var last_created_pid: LastCreatedPID
    var ram_stats: RamStat
    var cpu_max_freq: Int
    var networking_app: List[NetworkingApp]
    var freq_over_time: WidgetPlotSIMDQueue
    var cpu0_over_time: WidgetPlotSIMDQueue
    var pid_collection: PIDCollection
    var uptime: Float64
    var gpu_collection: GPU_collection
    fn __init__(out self):
        self.freq_over_time = __type_of(self.freq_over_time)()
        self.cpu0_over_time = __type_of(self.cpu0_over_time)()
        self.cooling = CoolingDevice.get_all()
        self.thermal_sensors = ThermalSensor.get_all()
        self.cpu_infos = CpuInfo.get_all()
        self.battery = Battery.get_all()
        var tmp_proc = ProcStat.get_all()
        self.proc_stats = __type_of(self.proc_stats)()
        self.proc_stats.append(tmp_proc)
        self.proc_stats.append(tmp_proc)
        self.proc_stats_deltas = ProcStat.to_deltas(self.proc_stats)
        self.network_stats = __type_of(self.network_stats)()
        var tmp_network = Network.get_all()
        self.network_stats.append(tmp_network)
        self.network_stats.append(tmp_network)
        self.network_deltas = Network.to_deltas(self.network_stats)
        self.last_created_pid = LastCreatedPID()
        self.ram_stats = RamStat()
        self.cpu_max_freq = 0
        try:
            self.cpu_max_freq = Int(Path("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq").read_text())
        except e: ...
        self.networking_app = NetworkingApp.get_all()
        self.pid_collection = __type_of(self.pid_collection)()
        self.uptime=0
        try:
            self.uptime = Path("/proc/uptime").read_text().split(" ")[0].__float__()
        except e: ...
        self.gpu_collection = GPU_collection()
    fn update_values(mut self, show_ui_networking_app: Bool):
        for ref c in self.cooling: c.update_values()
        for ref t in self.thermal_sensors: t.update_values()
        for ref b in self.battery: b.update_values()
        self.cpu_infos = CpuInfo.get_all()
        self.proc_stats.append(ProcStat.get_all())
        _ = self.proc_stats.pop(0)
        self.proc_stats_deltas = ProcStat.to_deltas(self.proc_stats)
        self.network_stats.append(Network.get_all())
        _ = self.network_stats.pop(0)
        self.network_deltas = Network.to_deltas(self.network_stats)
        # self.network_deltas.append(Network("test", 1, 1, 1, None))
        self.last_created_pid = LastCreatedPID()
        self.ram_stats = RamStat()
        if show_ui_networking_app:
            self.networking_app = NetworkingApp.get_all()
        #update freq_over_time
        var tmp_max_freq = self.cpu_max_freq//1000
        var avg = 0.0
        for e in self.cpu_infos: avg+=e.mhz
        avg /= Float64(len(self.cpu_infos))
        var percent = (100.0/Float64(tmp_max_freq))*avg
        self.freq_over_time.append_3bit_value(Int(((8.0/100.0)*percent).__floor__()))
        #update cpu0_over_time
        var e = self.proc_stats_deltas[0]
        var tmp_delta_sum = e.user + e.nice + e.system + e.idle + e.iowait + e.irq + e.soft_irq + e.steal
        var tmp_idle_sum = e.idle + e.iowait
        percent = 100.0 * Float64(tmp_delta_sum - tmp_idle_sum) / Float64(tmp_delta_sum);
        self.cpu0_over_time.append_3bit_value(Int(((8.0/100.0)*percent).__floor__()))
        try:
            self.uptime = Path("/proc/uptime").read_text().split(" ")[0].__float__()
        except e: ...
        self.gpu_collection.update_values()

@fieldwise_init
struct GPUElement(Movable&Copyable):
    var idx: Int
    var name: String
    var utilization_pct: Int
    var mem_total: Int
    var mem_used: Int
    var fan_pct: Int
    var temperature: Int
    var power_usage: Int
    var power_capacity: Int

struct GPU_collection(Movable&Copyable):
    var gpus: List[GPUElement]
    var time_to_fetch: UInt
    var avg_fan_over_time: WidgetPlotSIMDQueue
    var avg_util_over_time: WidgetPlotSIMDQueue
    fn __init__(out self):
        self.gpus = __type_of(self.gpus)()
        self.time_to_fetch = 0
        self.avg_fan_over_time = __type_of(self.avg_fan_over_time)()
        self.avg_util_over_time = __type_of(self.avg_util_over_time)()
    fn update_values(mut self):
        try:
            # Some dummy GPU metrics in the expected CSV format:
            var start = perf_counter_ns()
            var tmp_fetch = gpu_metric_fetch() # imported from Dummy_GPU_metric_fetcher.mojo
            var stop = perf_counter_ns()
            self.time_to_fetch = stop-start

            self.gpus.clear()

            var tmp_gpus = tmp_fetch.split("\n")
            var idx = 0
            for g in tmp_gpus:
                var splitted = g.split(",")
                tmp_gpu_name = splitted[0]
                tmp_gpu_utilization = splitted[1]
                tmp_ram_used = splitted[2]
                tmp_ram_total = splitted[3]
                tmp_temperature = splitted[4]
                tmp_fan_pct = splitted[5]
                tmp_power_usage = splitted[6]
                tmp_power_capacity = splitted[7]
                self.gpus.append(
                    GPUElement(
                        idx,
                        tmp_gpu_name,
                        Int(round(tmp_gpu_utilization.__float__())),
                        Int(round(tmp_ram_total.__float__())),
                        Int(round(tmp_ram_used.__float__())),
                        Int(round(tmp_fan_pct.__float__())),
                        Int(round(tmp_temperature.__float__())),
                        Int(round(tmp_power_usage.__float__())),
                        Int(round(tmp_power_capacity.__float__())),
                    )
                )
                idx+=1
            
            var tmp_avg_fan = Float64(0)
            var tmp_avg_util = Float64(0)
            for _gpu in self.gpus:
                tmp_avg_fan += Float64(_gpu.fan_pct)
                tmp_avg_util += Float64(_gpu.utilization_pct)
            tmp_avg_fan /= Float64(len(self.gpus))
            tmp_avg_util /= Float64(len(self.gpus))

            self.avg_fan_over_time.append_3bit_value(
                UInt8(Int(round((7.0/100.0)*tmp_avg_fan)))
            )
            self.avg_util_over_time.append_3bit_value(
                UInt8(Int(round((7.0/100.0)*tmp_avg_util)))
            )
        except e:
            ...


@fieldwise_init
struct PIDElement(Movable&Copyable):
    var PID: Int
    var COMM: String
    var start_time: Int
    var uptime_sec: Int
    var rss: Int
    var io: Self.io_storage_type 
    var current_state: String
    var swap_kb: Int
    var oom_score: Int
    var oom_score_adj: Int
    alias io_storage_type = SIMD[DType.int64, 2] #R/W == indexes[0, 1]
    fn get_io(mut self):
        try:
            var tmp_mstat = (Path("/proc")/String(self.PID)/"io").read_text().split("\n")
            self.io[0] = Int(tmp_mstat[4].split(" ")[1])
            self.io[1] = Int(tmp_mstat[5].split(" ")[1])
        except e: ...
    #ram: WidgetPlotSIMDQueue
struct PIDCollection:
    var values: List[PIDElement]
    var ignore_zero_rss_entries: Bool
    var filter_is_edit: Bool
    var filter_edit_buffer: String
    var sort_apps_smallest_first: Bool
    var sort_apps_by: Int
    fn __init__(out self):
        self.values = __type_of(self.values)()
        self.ignore_zero_rss_entries = True
        self.filter_is_edit = False
        self.filter_edit_buffer = String("")
        self.sort_apps_smallest_first = True
        self.sort_apps_by = 0
    fn update_values(mut self, read hidden_columns: List[String]):
        self.values.clear()
        var need_io = ("io_read" not in hidden_columns) | ("io_write" not in hidden_columns)
        var need_swap = "swap_kb" not in hidden_columns
        var need_oom_score = "oom_score" not in hidden_columns
        var need_oom_score_adj = "oom_score_adj" not in hidden_columns
        try:
            var pids = Path("/proc").listdir()
            # a > b, a newer, but need to check:
            # cat /proc/sys/kernel/pid_max
            for p in reversed(pids):
                if String(p).isdigit():
                    var p_name = (Path("/proc")/p/"comm").read_text()
                    if self.filter_edit_buffer != "":
                        if self.filter_edit_buffer not in p_name.strip():
                            continue
                    self.values.append(
                        PIDElement(Int(String(p)), String(p_name.strip()), 0, 0, 0, PIDElement.io_storage_type(), " ", 0, 0, 0)
                    )
                    try:
                        var tmp_stats = (Path("/proc")/p/"stat").read_text()#[1].split(" ")
                        var last_p = len(tmp_stats)-1
                        if last_p <= 0: raise "error"
                        while tmp_stats[last_p] != String(")"): last_p -= 1
                        var splitted_stats = (tmp_stats[last_p+2:]).split(" ")
                        self.values[-1].rss = Int(splitted_stats[24-3])*page_size
                        self.values[-1].start_time = Int(splitted_stats[22-3])
                        if need_io:
                            self.values[-1].get_io()
                        self.values[-1].current_state = splitted_stats[0]
                        # TODO: Need to make this way faster:
                        # (Currently uses a lot of CPU%)
                        if need_swap:
                            try:
                                var tmp_p = (Path("/proc")/p/"smaps_rollup").read_text().splitlines()
                                for i_ in range(2, len(tmp_p)-1): 
                                    if tmp_p[i_].startswith("Swap:"):
                                        self.values[-1].swap_kb = Int(tmp_p[i_][5:-3].strip())
                            except e: ...
                        try:
                            if need_oom_score:
                                var tmp_p = (Path("/proc")/p/"oom_score").read_text()
                                self.values[-1].oom_score = Int(tmp_p)
                            if need_oom_score_adj:
                                tmp_p = (Path("/proc")/p/"oom_score_adj").read_text()
                                self.values[-1].oom_score_adj = Int(tmp_p)
                        except e: ...

                    except e:
                        ...
                    if self.ignore_zero_rss_entries==True:
                        if self.values[-1].rss == 0:
                            _ = self.values.pop()
        except e: ...
        # TODO: make this very generic
        var sort_apps_smallest_first = UnsafePointer(to=self.sort_apps_smallest_first)
        @parameter
        fn app_sort_rss(a: PIDElement, b: PIDElement)->Bool:
            if sort_apps_smallest_first[] == True:
                return b.rss>a.rss
            else: 
                return a.rss>b.rss 
        @parameter
        fn app_sort_swap(a: PIDElement, b: PIDElement)->Bool:
            if sort_apps_smallest_first[] == True:
                return b.swap_kb>a.swap_kb
            else: 
                return a.swap_kb>b.swap_kb 
        if self.sort_apps_by == 0: 
            if self.sort_apps_smallest_first == False:
                self.values.reverse()
        elif self.sort_apps_by == 1: sort[app_sort_rss](self.values)
        elif self.sort_apps_by == 2: sort[app_sort_swap](self.values)

