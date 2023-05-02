using Base.Threads

function async_loop()
    stop_channel = Channel{Bool}(1)

    @async begin
        while true
            # Check if the stop signal is received
            stop = isready(stop_channel) ? take!(stop_channel) : false
            if stop
                break
            end

            # Your loop execution code goes here
            println("Executing the loop...")

            # Sleep for a while (optional, used to demonstrate async behavior)
            sleep(0.5)
        end
        println("Loop stopped.")
    end

    return stop_channel
end

function main()
    # Start the async loop and receive the stop_channel
    stop_channel = async_loop()

    # Main process code goes here
    # For demonstration, let's wait for 5 seconds
    sleep(5)

    # Stop the async loop
    put!(stop_channel, true)
    println("Stop signal sent.")
end

main()
