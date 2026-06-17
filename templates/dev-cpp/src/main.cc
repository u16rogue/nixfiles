#include "utils.hh"
#include <span>

int main(const int argc, const char* const* argv) noexcept {
    logutil::init();

    if (argc <= 1) {
        logerr("missing arguments");
        return 1;
    }

    const std::span<const char* const> args = std::span(argv + 1, static_cast<std::size_t>(argc) - 1);
    for (const auto& arg : args) {
        logdbg("{}", arg);
    }

    return 0;
}
