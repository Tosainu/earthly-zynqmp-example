#include <array>
#include <atomic>
#include <cstdint>

#include <xgpiops.h>
#include <xil_exception.h>
#include <xipipsu.h>
#include <xparameters.h>
#include <xscugic.h>
#include <xttcps.h>

// APU_TRIG[24:24] = IPI Ch 7, which is not defined in xparameters.h
// https://www.xilinx.com/htmldocs/registers/ug1087/ug1087-zynq-ultrascale-registers.html
inline constexpr std::uint32_t IPI_TRIG_CH7_MASK = std::uint32_t{1} << 24;

static std::atomic<std::uint32_t> ipi_req{0};

static void ipi_irq_handler(void* data) noexcept {
  auto ipi = static_cast<XIpiPsu*>(data);
  const auto status = XIpiPsu_GetInterruptStatus(ipi);
  if (status & IPI_TRIG_CH7_MASK) {
    const std::uint32_t req = Xil_In32(XPAR_PSU_MESSAGE_BUFFERS_S_AXI_BASEADDR + 0x600);
    ipi_req.store(req | 0x8000'0000, std::memory_order_relaxed);

    XIpiPsu_ClearInterruptStatus(ipi, IPI_TRIG_CH7_MASK);
  }
}

static std::atomic_flag ttc_irq_kicked_n = ATOMIC_FLAG_INIT;

static void ttc_irq_handler(void* data) noexcept {
  auto ttc = static_cast<XTtcPs*>(data);
  const auto status = XTtcPs_GetInterruptStatus(ttc);
  if (status & XTTCPS_IXR_INTERVAL_MASK) {
    ttc_irq_kicked_n.clear();

    XTtcPs_ClearInterruptStatus(ttc, XTTCPS_IXR_INTERVAL_MASK);
  }
}

inline constexpr std::uint32_t GPIO_BANK0_LED_MASK = std::uint32_t{0b1111} << 17;

inline void set_ultra96_leds(XGpioPs& gpio, std::uint8_t value) noexcept {
  XGpioPs_WriteReg(gpio.GpioConfig.BaseAddr, XGPIOPS_DATA_MSW_OFFSET,
                   (~GPIO_BANK0_LED_MASK & 0xffff0000) | ((value & 0b1111) << 1));
}

auto main() -> int {
  Xil_ExceptionDisable();

  XScuGic gic{};
  {
    auto cfg = XScuGic_LookupConfig(XPAR_PSU_RCPU_GIC_DEVICE_ID);
    XScuGic_CfgInitialize(&gic, cfg, cfg->CpuBaseAddress);

    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_IRQ_INT,
        [](void* ptr) { XScuGic_InterruptHandler(static_cast<XScuGic*>(ptr)); }, &gic);
  }

  XGpioPs gpio{};
  {
    auto cfg = XGpioPs_LookupConfig(XPAR_PSU_GPIO_0_DEVICE_ID);
    XGpioPs_CfgInitialize(&gpio, cfg, cfg->BaseAddr);

    auto dir = XGpioPs_GetDirection(&gpio, 0);
    XGpioPs_SetDirection(&gpio, 0, dir | GPIO_BANK0_LED_MASK);

    auto oen = XGpioPs_GetOutputEnable(&gpio, 0);
    XGpioPs_SetOutputEnable(&gpio, 0, oen | GPIO_BANK0_LED_MASK);

    set_ultra96_leds(gpio, 0);
  }

  XIpiPsu ipi{};
  {
    auto cfg = XIpiPsu_LookupConfig(XPAR_PSU_IPI_1_DEVICE_ID);
    XIpiPsu_CfgInitialize(&ipi, cfg, cfg->BaseAddress);

    XIpiPsu_InterruptEnable(&ipi, IPI_TRIG_CH7_MASK);
    XIpiPsu_ClearInterruptStatus(&ipi, IPI_TRIG_CH7_MASK);

    XScuGic_Connect(&gic, XPAR_PSU_IPI_1_INT_ID, ipi_irq_handler, &ipi);
    XScuGic_Enable(&gic, XPAR_PSU_IPI_1_INT_ID);
  }

  XTtcPs ttc{};
  {
    auto cfg = XTtcPs_LookupConfig(XPAR_PSU_TTC_0_DEVICE_ID);
    XTtcPs_CfgInitialize(&ttc, cfg, cfg->BaseAddress);

    XTtcPs_SetOptions(&ttc, XTTCPS_OPTION_INTERVAL_MODE | XTTCPS_OPTION_WAVE_DISABLE);

    XInterval interval;
    std::uint8_t prescaler;
    XTtcPs_CalcIntervalFromFreq(&ttc, 10, &interval, &prescaler);
    XTtcPs_SetInterval(&ttc, interval);
    XTtcPs_SetPrescaler(&ttc, prescaler);

    XTtcPs_EnableInterrupts(&ttc, XTTCPS_IXR_INTERVAL_MASK);
    XTtcPs_ClearInterruptStatus(&ttc, XTTCPS_IXR_ALL_MASK);

    XScuGic_Connect(&gic, XPAR_PSU_TTC_0_INTR, ttc_irq_handler, &ttc);
    XScuGic_Enable(&gic, XPAR_PSU_TTC_0_INTR);

    ttc_irq_kicked_n.test_and_set(std::memory_order_relaxed);
  }

  Xil_ExceptionEnable();

  constexpr std::uint8_t led_patterns[] = {
      0b0000, 0b0001, 0b0011, 0b0110, 0b1100, 0b1000,
      0b0000, 0b1000, 0b1100, 0b0110, 0b0011, 0b0001,
  };
  std::uint8_t led_pattern_next = 0;

  bool ipi_triggered = false;

  for (;;) {
    asm volatile("wfi");

    if (const auto req = ipi_req.exchange(0, std::memory_order_relaxed); req & 0x8000'0000) {
      if ((req & 1) && (XTtcPs_IsStarted(&ttc) == 0)) {
        led_pattern_next = 0;
        ipi_triggered = false;
        XTtcPs_Start(&ttc);
      } else {
        XTtcPs_Stop(&ttc);
        set_ultra96_leds(gpio, 0);
        ttc_irq_kicked_n.test_and_set(std::memory_order_relaxed);
        continue;
      }
    }

    if (!ttc_irq_kicked_n.test_and_set(std::memory_order_relaxed)) {
      if (ipi_triggered) {
        ipi_triggered = false;

        if (XIpiPsu_GetObsStatus(&ipi) & IPI_TRIG_CH7_MASK) {
          XTtcPs_Stop(&ttc);
          set_ultra96_leds(gpio, 0);
          continue;
        }
      } else {
        XIpiPsu_TriggerIpi(&ipi, IPI_TRIG_CH7_MASK);
        ipi_triggered = true;
      }

      set_ultra96_leds(gpio, led_patterns[led_pattern_next]);
      led_pattern_next = (led_pattern_next + 1) % std::size(led_patterns);
    }
  }
}
