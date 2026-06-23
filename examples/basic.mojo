from tracy import FunctionZone, Zone, frame_mark, is_connected, message, plot, plot_i64, set_thread_name, sleep_ms, wait_for_connection

def do_work(i: Int):
    with FunctionZone("do_work"):
        message("inside do_work")
        sleep_ms(32)

def main() raises:
    set_thread_name("mojo-tracy example")
    message("starting mojo-tracy example")

    print("Waiting up to 5 seconds for Tracy profiler...")
    var connected = wait_for_connection()
    print("Tracy connected:", connected)

    var i = 0
    while i < 120:
        do_work(i)
        plot("example.float", Float64(i) * 0.25)
        plot_i64("example.count", Int64(i))

        frame_mark()
        sleep_ms(16)
        i += 1

    with Zone("custom zone", 0, True, "main"):
        message("this zone has a custom display name and main as its source function")

    frame_mark("example")
    print("Tracy connected at exit:", is_connected())
