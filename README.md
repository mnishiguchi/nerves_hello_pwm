# NervesHelloPwm

This is a simple project that demonstrates Pulse Width Modulation (PWM) using GenServer.
## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Usage

Here is an example of blinking an LED in various timings.

### Handmade GenServer powered Pwm Scheduler

```ex
# A GPIO pin for an LED.
gpio_pin = 12

# Get a reference to the LED.
{:ok, led_ref} = Circuits.GPIO.open(gpio_pin, :output)

# Start a scheduler with on/off callback functions and initial settings for the
# period (frequency in Hz and duty cycle in percentage).
NervesHelloPwm.PwmScheduler.start_link(%{
  id: gpio_pin,
  frequency: 1,
  duty_cycle: 50,
  on_fn: fn -> Circuits.GPIO.write(led_ref, 1)  end,
  off_fn: fn -> Circuits.GPIO.write(led_ref, 0) end
})

# Change the on/off ratio to 4:1.
NervesHelloPwm.PwmScheduler.change_period(gpio_pin, 1, 80)

# Change the frequency to 2Hz (2x faster than 1Hz).
NervesHelloPwm.PwmScheduler.change_period(gpio_pin, 2, 80)

# Stop the scheduler.
NervesHelloPwm.PwmScheduler.stop(gpio_pin)
** (EXIT from #PID<0.1202.0>) shell process exited with reason: shutdown
```

PWM scheduler processes are registered with an ID so it is possible to start
multiple PWM scheduler processes as long as IDs are unique.

Since Elixir's `Process.send_after/3` function is millisecond precision,
there is a limitation on the pulse precision.
So `NervesHelloPwm.PwmScheduler` has the maximum frequency of 100Hz (10ms / period),
which is probably fast enough to dim the brightness of an LED.

If you need faster and more precise PWM, please consider alternative approaches, such as accessing
the target device's built-in hardware PWM, using an external PWM driver board, etc.

### Hardware PWM using the [tokafish/pigpiox](https://github.com/tokafish/pigpiox) library

```
gpio = 12
frequency = 800
Pigpiox.Pwm.hardware_pwm(gpio, frequency, 1_000_000) # 100%
Pigpiox.Pwm.hardware_pwm(gpio, frequency, 500_000)   # 50%
Pigpiox.Pwm.hardware_pwm(gpio, frequency, 100_000)   # 10%
Pigpiox.Pwm.hardware_pwm(gpio, frequency, 10_000)    # 1%
```

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
