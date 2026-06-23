from tracy import Zone, frame_mark, is_connected, message, plot, plot_i64, set_thread_name

def main() raises:
    set_thread_name("mojo-tracy example")
    message("starting mojo-tracy example")

    with Zone("work"):
        message("inside work")
        plot("example.float", 1.5)
        plot_i64("example.count", 42)
        frame_mark()

    frame_mark("example")
    print("Tracy connected:", is_connected())
