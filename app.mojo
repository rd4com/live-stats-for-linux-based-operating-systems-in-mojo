from `ui-terminal-mojo` import *
from pathlib import Path
from sys.info import os_is_linux
from sys.param_env import env_get_bool

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

    var system_infos = SystemInfos()
    system_infos.update_values()
    # return
    
    var time = perf_counter_ns()
    
    var selected_overview = 0
    var values_overview = List("LastCreatedPID", "None")
    #TODO add "MostRamUsingPID", "MostCPUUsingPID"


    var ui = UI()
    ui.feature_tab_menu =True
    ui.show_tab_menu = True # Starts showed (tab to toggle)
    var app_panel = AppPanel(ui)
    var show_cpu_cores = False
    var show_all_cooling = False
    var show_all_temp_sensors = False
    var show_inode = False

    for _ in ui:
        
        @parameter
        fn tab_menu():
            with MoveCursor.BelowThis[StyleBorderSimple, Fg.blue](ui):
                with MoveCursor.BelowThis(ui):
                    Text("Show:") | Fg.blue | Bg.white in ui
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "Cores", show_cpu_cores)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "All sensors", show_all_temp_sensors)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "All cooling", show_all_cooling)
                with MoveCursor.BelowThis(ui):
                    widget_checkbox(ui, "Net inodes", show_inode)
        ui.set_tab_menu[tab_menu]()
        # Text(Int("FF", base=16)) in ui
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
            system_infos.update_values()
            # once_sec_timer = True
        else:
            ...
            # once_sec_timer = False

        with MoveCursor.BelowThis(ui):
            with MoveCursor.AfterThis[StyleBorderCurved](ui):
                Text("🔋 Battery") | Bg.white | Fg.black in ui
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        for e in system_infos.battery:
                            with MoveCursor.BelowThis(ui):
                                Text(e.charge_now) in ui
                    with MoveCursor.AfterThis(ui):
                        for _ in system_infos.battery:
                            with MoveCursor.BelowThis(ui):
                                Text("/") | Fg.blue in ui
                    with MoveCursor.AfterThis(ui):
                        for e in system_infos.battery:
                            with MoveCursor.BelowThis(ui):
                                Text(e.charge_full) in ui
                for e in system_infos.battery:
                    var percent = (100.0/Float64(e.charge_full))*Float64(e.charge_now)
                    if percent <= 33:
                        widget_percent_bar_with_speed[Fg.red](ui, Int(percent), 0)
                    elif percent <= 66:
                        widget_percent_bar_with_speed[Fg.yellow](ui, Int(percent), 0)
                    else:
                        widget_percent_bar_with_speed[Fg.green](ui, Int(percent), 0)
            with MoveCursor.AfterThis[StyleBorderCurved](ui):
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        Text("📶 Network") | Bg.white | Fg.black in ui
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
                    with MoveCursor.AfterThis(ui): " " in ui
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
            with MoveCursor.AfterThis[StyleBorderSimple](ui):
                
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        Text("🧮 RAM") in ui
                        Text("Available ") in ui
                        Text("Total ") in ui
                        # Text("RamFree") | Bg.white | Fg.black in ui
                    with MoveCursor.AfterThis(ui):
                        var percent_tmp_ram = Float64(100.0)/Float64(system_infos.ram_stats.total)
                        percent_tmp_ram*=Float64(system_infos.ram_stats.available)
                        var percent_tmp_ram2 = 100-Int(round(percent_tmp_ram))
                        if percent_tmp_ram2 >= 66: widget_percent_bar[Fg.red](ui, percent_tmp_ram2)
                        elif percent_tmp_ram2 >= 33: widget_percent_bar[Fg.yellow](ui, percent_tmp_ram2)
                        else: widget_percent_bar[Fg.green](ui, percent_tmp_ram2)

                        Text(system_infos.ram_stats.available//1024, "Mb") | Fg.cyan in ui
                        Text(system_infos.ram_stats.total//1024, "Mb") | Fg.cyan in ui
                        # Text(system_infos.ram_stats.free) | Fg.cyan in ui

        with MoveCursor.BelowThis(ui):
            with MoveCursor.AfterThis(ui): Text(" ") in ui
            with MoveCursor.AfterThis(ui):
                widget_value_selector[""](ui, selected_overview, values_overview)
            with MoveCursor.AfterThis(ui): Text(" ") in ui
            with MoveCursor.AfterThis(ui):
                if selected_overview == 0:

                    with MoveCursor.AfterThis(ui):
                        Text(system_infos.last_created_pid.pid) | Fg.yellow in ui
                    with MoveCursor.AfterThis(ui): Text(" ") in ui
                    Text(system_infos.last_created_pid.cmd) | Fg.magenta in ui
                elif selected_overview == 1: ...
        with MoveCursor.BelowThis(ui):
            with MoveCursor.AfterThis[StyleBorderSimple](ui):
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.BelowThis(ui):
                        widget_plot(ui, system_infos.cpu0_over_time)
                    with MoveCursor.AfterThis(ui):
                        Text("CPU") | Bg.white | Fg.black in ui
                        ui[-1].data.value = ui[-1].data.value.center(width=16)
                with MoveCursor.BelowThis(ui):
                    # with MoveCursor.AfterThis(ui):
                    #     for e in system_infos.proc_stats_deltas:
                    #         with MoveCursor.BelowThis(ui):
                    #             if e.name == "cpu":
                    #                 Text("cpu ") | Fg.green in ui
                    #             else:
                    #                 if show_cpu_cores:
                    #                     Text(e.name) | Bg.blue in ui
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
                                        widget_progress_bar_thin[theme = Fg.magenta](ui, UInt8(percent))
                
            with MoveCursor.AfterThis[StyleBorderSimple](ui):
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
                            Text("Frequencies") | Bg.white | Fg.black in ui
                            ui[-1].data.value = ui[-1].data.value.center(width=16)
                    with MoveCursor.BelowThis(ui):
                        # with MoveCursor.AfterThis(ui):
                        #     "avg " in ui
                        widget_progress_bar_thin[width=12](ui, UInt8(percent))
                    if show_cpu_cores:

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
                            with MoveCursor.AfterThis(ui):
                                Text("Avg: ", String(Int(avg)).ljust(5)) in ui
                            with MoveCursor.AfterThis(ui):
                                Text("Max: ", tmp_max_freq) in ui
                # with MoveCursor.BelowThis(ui):


            with MoveCursor.AfterThis[StyleBorderCurved](ui):
                Text("Temperature sensors") | Bg.white | Fg.black in ui
                var avg_temp_sensors = Float64(0.0)
                var highest_temp_sensors = Float64(0.0)
                for e in system_infos.thermal_sensors: 
                    avg_temp_sensors+=Float64(e.temp)/1000.0
                    if Float64(e.temp) > highest_temp_sensors: 
                        highest_temp_sensors = e.temp
                avg_temp_sensors/=Float64(len(system_infos.thermal_sensors))
                Text("Average: ", round(avg_temp_sensors)) in ui
                if avg_temp_sensors < 50.0: ui[-1] |= Fg.green 
                elif avg_temp_sensors < 60: ui[-1] |= Bg.yellow
                else: ui[-1] |= Bg.red

                highest_temp_sensors /=1000.0
                Text("Highest: ", round(highest_temp_sensors)) in ui
                if highest_temp_sensors < 50.0: ui[-1] |= Fg.green 
                elif avg_temp_sensors < 60: ui[-1] |= Bg.yellow
                else: ui[-1] |= Bg.red
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
            
            with MoveCursor.AfterThis[StyleBorderCurved](ui):

                var average_cooling_percent_float = 0.0
                for e in system_infos.cooling:
                    var tmp_avg_cooling_percent = (100.0/Float64(e.max_state))*Float64(e.cur_state)
                    average_cooling_percent_float += tmp_avg_cooling_percent
                average_cooling_percent_float /= len(system_infos.cooling)
                var average_cooling_percent_int = Int(average_cooling_percent_float)
                var speed_animate = 0
                if average_cooling_percent_int >= 66: speed_animate=3
                elif average_cooling_percent_int >= 33: speed_animate = 2
                elif average_cooling_percent_int > 0: speed_animate = 1
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.BelowThis(ui):
                        Text("Coolers") | Bg.blue in ui
                        # var center_width = len(system_infos.cooling)
                        # TODO: center_width of ui[-1] with len

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
                with MoveCursor.BelowThis(ui):
                    with MoveCursor.AfterThis(ui):
                        Text("Average: ", average_cooling_percent_int, "%") in ui
                    # widget_percent_bar_with_speed[Fg.default](ui, average_cooling_percent_int,speed_animate)
                if show_all_cooling:
                    # with MoveCursor.BelowThis(ui):
                        # widget_checkbox(ui, "Show all", show_all_cooling)
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
            # with MoveCursor.AfterThis[StyleBorderDouble, Fg.magenta](ui):
        with MoveCursor.AfterThis[StyleBorderSimple](ui):
            # Text(len(system_infos.networking_app)) in ui
            with MoveCursor.BelowThis(ui):
                # with MoveCursor.AfterThis(ui):
                #     animate_emojis[List[String]("🌍","🌎", "🌏")](ui)
                #     ui[-1] |= Bg.white
                with MoveCursor.AfterThis(ui):
                    Text("📻 Networking") | Bg.white | Fg.black in ui
            with MoveCursor.BelowThis(ui):
                with MoveCursor.AfterThis(ui):
                    Text("Status") in ui 
                    for e in system_infos.networking_app:
                        with MoveCursor.BelowThis(ui):
                            Text(e.st, " ") in ui
                with MoveCursor.AfterThis(ui):
                    Text("Local") in ui 
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
                with MoveCursor.AfterThis(ui):
                    Text("Remote") in ui 
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
                if show_inode:
                    with MoveCursor.AfterThis(ui):
                        Text("Protocol ") in ui 
                        for e in system_infos.networking_app:
                            with MoveCursor.BelowThis(ui):
                                Text(["tcp","udp"][e.tcp_udp]) in ui
                    with MoveCursor.AfterThis(ui):
                        Text("Inode") in ui 
                        for e in system_infos.networking_app:
                            with MoveCursor.BelowThis(ui):
                                Text(e.inode) in ui
            Text("(TCP6 and UDP6 connections are not included yet)") in ui
        with MoveCursor.BelowThis(ui):
            app_panel.render()

struct AppPanel[O:MutableOrigin]:
    var ui: Pointer[UI, O]
    var is_edit: Bool
    var edit_buffer: String
    var pids: List[(Int, String)]
    fn __init__(out self, ref[O]ui: UI):
        self.ui = Pointer(to=ui)
        self.is_edit = False
        self.edit_buffer = ""
        self.pids = []
    fn render(mut self):
        with MoveCursor.AfterThis[StyleBorderDouble, Fg.magenta](self.ui[]):
            Text("📱 Apps") | Bg.magenta in self.ui[]
            var current_is_edit = self.is_edit
            #TODO: Fix input_buffer when ""
            input_buffer["Search:"](self.ui[], self.edit_buffer, self.is_edit)
            var need_update = self.is_edit == False
            need_update = need_update == current_is_edit == True
            if need_update:
                spinner2(self.ui[])
                self.update_apps()
            for ref p in self.pids:
                if len(self.edit_buffer) and self.edit_buffer in p[1]:
                    Text(p[1]) in self.ui[]
                    if self.ui[][-1].hover():
                        var tmp_stats = (Self.get_statm(p[0]) * 4096)/1024
                        with MoveCursor.BelowThis[StyleBorderCurved, Fg.magenta](self.ui[]):
                            Text("🧮 Ram (Kb)") in self.ui[]
                            with MoveCursor.BelowThis(self.ui[]):
                                with MoveCursor.AfterThis(self.ui[]):
                                    with MoveCursor.BelowThis(self.ui[]):
                                        Text("Total")|Bg.blue in self.ui[]
                                    with MoveCursor.BelowThis(self.ui[]):
                                        Text(tmp_stats[0], " ") in self.ui[]
                                with MoveCursor.AfterThis(self.ui[]):
                                    with MoveCursor.BelowThis(self.ui[]):
                                        Text("Rss")|Bg.cyan in self.ui[]
                                    with MoveCursor.BelowThis(self.ui[]):
                                        Text(tmp_stats[1], " ") in self.ui[]
                            Text("(Page size assumed to be 4096)") in self.ui[]
                        var io_stats = Self.get_io(p[0])
                        with MoveCursor.BelowThis[StyleBorderCurved, Fg.magenta](self.ui[]):
                            Text("🗄️  Disk I/O (bytes)") in self.ui[]
                            with MoveCursor.AfterThis(self.ui[]):
                                with MoveCursor.BelowThis(self.ui[]):
                                    Text("👓 Read")|Bg.blue in self.ui[]
                                with MoveCursor.BelowThis(self.ui[]):
                                    Text(io_stats[0], " ") in self.ui[]
                            with MoveCursor.AfterThis(self.ui[]):
                                " " in self.ui[]
                            with MoveCursor.AfterThis(self.ui[]):
                                with MoveCursor.BelowThis(self.ui[]):
                                    Text("✏️ Write")|Bg.cyan in self.ui[]
                                with MoveCursor.BelowThis(self.ui[]):
                                    Text(io_stats[1], " ") in self.ui[]
                                
    @staticmethod
    fn get_statm(pid: Int, out ret:SIMD[DType.uint32, 8]):
        ret = __type_of(ret)(0)
        try:
            tmp_mstat = (Path("/proc")/String(pid)/"statm").read_text().split(" ")
            ret[0] = Int(tmp_mstat[0])
            ret[1] = Int(tmp_mstat[1])
            ret[2] = Int(tmp_mstat[2])
            ret[3] = Int(tmp_mstat[3])
            ret[4] = Int(tmp_mstat[4])
            ret[5] = Int(tmp_mstat[5])
            ret[6] = Int(tmp_mstat[6])
        except e: ...

    @staticmethod
    fn get_io(pid: Int, out ret:SIMD[DType.int64, 2]):
        ret = __type_of(ret)(0)
        try:
            var tmp_mstat = (Path("/proc")/String(pid)/"io").read_text().split("\n")
            ret[0] = Int(tmp_mstat[4].split(" ")[1])
            ret[1] = Int(tmp_mstat[5].split(" ")[1])
        except e: ...

    fn update_apps(mut self):
        try:
            self.pids.clear()
            var pids = Path("/proc").listdir()
            for p in pids:
                if String(p).isdigit():
                    var p_name = (Path("/proc")/p/"comm").read_text()
                    self.pids.append((Int(String(p)), String(p_name.strip())))
        except e: ...


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
    fn update_values(mut self):
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
        
