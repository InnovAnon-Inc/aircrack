FROM kalilinux/kali-rolling as build

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update

RUN apt full-upgrade -y            \
    --no-install-recommends

RUN apt install      -y            \
    --no-install-recommends        \
    autoconf                       \
    automake                       \
    autotools-dev                  \
    build-essential                \
    ca-certificates                \
    ethtool                        \
    hostapd                        \
    iw                             \
    libcmocka-dev                  \
    libhwloc-dev                   \
    libnl-3-dev                    \
    libnl-genl-3-dev               \
    libpcap-dev                    \
    libpcre2-dev                   \
    libsqlite3-dev                 \
    libssl-dev                     \
    libtool                        \
    pkg-config                     \
    rfkill                         \
    screen                         \
    shtool                         \
    tcpdump                        \
    usbutils                       \
    wpasupplicant                  \
    zlib1g-dev

RUN apt autoremove   -y            \
    --purge                        \
&&  apt clean        -y            \
&&  rm -rf /var/lib/apt/lists/*

COPY   ./aircrack-ng /aircrack-ng

WORKDIR /aircrack-ng

#RUN find . -type f -exec sed -i 's@-O3@-Ofast@g' '{}' +

  #-msse5                                -mavx
ARG  CFLAGS
ENV  CFLAGS=" $CFLAGS -fprofile-use=/var/teamhack/pgo/aircrack-ng.prof -fprofile-abs-path -fuse-linker-plugin -flto -march=native -mfpmath=sse+387 -momit-leaf-frame-pointer -mtune=native -Ofast -g0 -fmerge-all-constants -fomit-frame-pointer"

ARG LDFLAGS
ENV LDFLAGS="$LDFLAGS -fprofile-use=/var/teamhack/pgo/aircrack-ng.prof -fprofile-abs-path -fuse-linker-plugin -flto -lgcov"

ARG SIMD

RUN autoreconf -fi
RUN ./configure    \
  --without-opt    \
  --disable-shared \
  --enable-static  \
  "--with-static-simd=$SIMD"
RUN make
RUN make install-strip

RUN       command -v aircrack-ng
RUN ldd $(command -v aircrack-ng)

FROM scratch
COPY --from=build /usr/local/bin/aircrack-ng /usr/local/bin/
COPY --from=build                                  \
  /lib/x86_64-linux-gnu/libsqlite3.so.0            \
  /lib/x86_64-linux-gnu/libhwloc.so.15             \
  /lib/x86_64-linux-gnu/libcrypto.so.3             \
  /lib/x86_64-linux-gnu/libstdc++.so.6             \
  /lib/x86_64-linux-gnu/libgcc_s.so.1              \
  /lib/x86_64-linux-gnu/libc.so.6                  \
  /lib/x86_64-linux-gnu/libm.so.6                  \
  /lib/x86_64-linux-gnu/libudev.so.1               \
  /lib/x86_64-linux-gnu/libcap.so.2                \
  /lib/x86_64-linux-gnu/
COPY --from=build                                  \
  /lib64/ld-linux-x86-64.so.2                      \
  /lib64/

WORKDIR  /var/teamhack
VOLUME ["/var/teamhack/caps"]
VOLUME ["/var/teamhack/pgo"]
VOLUME ["/var/teamhack/psks"]
VOLUME ["/var/teamhack/wordlists"]
ENTRYPOINT [                                        \
  "/usr/local/bin/aircrack-ng"                      \
]

