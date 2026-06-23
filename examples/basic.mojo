from mojo_tracy import FunctionZone, frame_mark, is_connected, message, plot, set_thread_name, sleep_ms, wait_for_connection

def do_work(i: Int):
    with FunctionZone[do_work]():
        message("inside do_work")
        sleep_ms(3)
        do_work2()

def do_work2():
    with FunctionZone[do_work2]():
        message("inside do_work2")
        sleep_ms(2)

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
        plot("example.count", Int64(i))

        frame_mark()
        sleep_ms(5)
        i += 1

    frame_mark("example")
    print("Tracy connected at exit:", is_connected())
