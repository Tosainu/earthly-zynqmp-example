#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <string_view>
#include <utility>

extern "C" {
#include <sys/fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
}

class uio {
public:
  static constexpr std::size_t mapsize = 0x1000;

  static std::optional<uio> open(const char* device) {
    int fd = ::open(device, O_RDWR | O_CLOEXEC);
    if (fd < 0) return std::nullopt;

    auto ptr = ::mmap(nullptr, mapsize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (ptr == MAP_FAILED) return std::nullopt;

    return uio{fd, ptr};
  }

  uio(const uio&) = delete;
  uio& operator=(const uio&) = delete;

  uio(uio&& a) : fd_{std::exchange(a.fd_, -1)}, ptr_{std::exchange(a.ptr_, nullptr)} {}

  uio& operator=(uio&& a) {
    if (ptr_) {
      ::munmap(ptr_, mapsize);
    }
    if (fd_ >= 0) {
      ::close(fd_);
    }
    fd_ = std::exchange(a.fd_, -1);
    ptr_ = std::exchange(a.ptr_, nullptr);
    return *this;
  }

  ~uio() {
    if (ptr_) {
      ::munmap(ptr_, mapsize);
    }
    if (fd_ >= 0) {
      ::close(fd_);
    }
  }

  auto fd() const {
    return fd_;
  }

  auto& operator[](std::size_t i) {
    return ptr_[i];
  }

  const auto& operator[](std::size_t i) const {
    return ptr_[i];
  }

private:
  uio(int fd, void* ptr) : fd_{fd}, ptr_{static_cast<std::uint32_t*>(ptr)} {}

  int fd_;
  std::uint32_t* ptr_;
};

static std::optional<std::filesystem::path> find_uio_device_by_name(std::string_view name) {
  for (const auto& dir : std::filesystem::directory_iterator{"/sys/class/uio"}) {
    auto path = dir.path();
    if (std::string s{}; std::ifstream{path / "name"} >> s && s == name) {
      return "/dev" / path.filename();
    }
  }
  return std::nullopt;
}

static std::optional<uio> find_and_open_uio_device(std::string_view name) {
  auto p = find_uio_device_by_name(name);
  if (!p) return std::nullopt;
  return uio::open(p->c_str());
}

inline constexpr std::size_t IPI_TRIG = 0; // Interrupt Trigger
inline constexpr std::size_t IPI_OBS = 1;  // Interrupt Observation
inline constexpr std::size_t IPI_ISR = 4;  // Interrupt Status and Clear
inline constexpr std::size_t IPI_IMR = 5;  // Interrupt Mask
inline constexpr std::size_t IPI_IER = 6;  // Interrupt Enable
inline constexpr std::size_t IPI_IDR = 7;  // Interrupt Disable

inline constexpr std::uint32_t IPI_TRIG_RPU0_MASK = std::uint32_t{1} << 8;

inline constexpr std::size_t IPI_BUF_CH7_TO_R5_0 = 0x600 / 4;

auto main() -> int {
  auto ipi_ctrl = [] {
    auto d = find_and_open_uio_device("ipi-ctrl");
    if (!d) {
      std::cerr << "ipi-ctrl" << std::endl;
      std::exit(-1);
    }
    return *std::move(d);
  }();

  auto ipi_buf = [] {
    auto d = find_and_open_uio_device("ipi-buffer");
    if (!d) {
      std::cerr << "ipi-buffer" << std::endl;
      std::exit(-1);
    }
    return *std::move(d);
  }();

  ipi_ctrl[IPI_ISR] = IPI_TRIG_RPU0_MASK;
  ipi_ctrl[IPI_IER] = IPI_TRIG_RPU0_MASK;

  ipi_buf[IPI_BUF_CH7_TO_R5_0] = 1;
  ipi_ctrl[IPI_TRIG] = IPI_TRIG_RPU0_MASK;

  for (;;) {
    std::uint32_t irq = 1;

    if (::write(ipi_ctrl.fd(), &irq, sizeof irq) < 0) {
      std::perror("write");
      return -1;
    }

    if (::read(ipi_ctrl.fd(), &irq, sizeof irq) < 0) {
      std::perror("read");
      return -1;
    }

    if (ipi_ctrl[IPI_ISR] & IPI_TRIG_RPU0_MASK) {
      ipi_ctrl[IPI_ISR] = IPI_TRIG_RPU0_MASK;
    }
  }
}
