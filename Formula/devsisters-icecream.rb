class DevsistersIcecream < Formula
  desc "Icecc forked from icecc/icecream"
  homepage "https://en.opensuse.org/Icecream"
  url "https://github.com/devsisters/icecream/archive/1.4.1-devsisters.tar.gz"
  sha256 "8a1ff0f9eda738fab3be61335c6f6c1fa216f27466027309a5c953a6a82f91aa"
  license "GPL-2.0"

  bottle do
    sha256 "666f827a6a686e6d2e81dc1d0eb5aae8374f01d7d1524ef6c695e3bf207c4af5" => :catalina
    sha256 "fb94b2d8e763469a2b0112523f89496f4a81e22ed9b7290f4280178f726853da" => :mojave
    sha256 "6cc11bcddd969e9aeb7e83692e9714d5891f0530bacbc1c52b019b298bce3d24" => :high_sierra
  end

  depends_on "asciidoc" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "docbook-xsl" => :build
  depends_on "docbook2x" => :build
  depends_on "libarchive"
  depends_on "libtool" => :build
  depends_on "libxslt" => :build
  depends_on "lzo"
  depends_on "pkg-config"
  depends_on "zstd"

  def install
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-clang-wrappers
    ]

    system "./autogen.sh"
    system "./configure", *args
    system "make", "install"

    # Manually install scheduler property list
    (prefix/"#{plist_name}-scheduler.plist").write scheduler_plist
  end

  def caveats
    <<~EOS
      To override the toolset with icecc, add to your path:
        #{opt_libexec}/icecc/bin
    EOS
  end

  plist_options manual: "iceccd"
  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>EnvironmentVariables</key>
          <dict>
              <key>ICECC_LOGFILE</key>
              <string>#{var}/log/icecream.log</string>
              <key>ICECC_CARET_WORKAROUND</key>
              <string>0</string>
          </dict>
          <key>ProgramArguments</key>
          <array>
              <string>#{sbin}/iceccd</string>
              <string>-l</string>
              <string>#{var}/log/icecream-daemon.log</string>
              <string>-u</string>
              <string>#{ENV["USER"]}</string>
              <string>-b</string>
              <string>#{var}/icecream</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
      </dict>
      </plist>
    EOS
  end

  def scheduler_plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}-scheduler</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{sbin}/icecc-scheduler</string>
              <string>-l</string>
              <string>#{var}/log/icecream-scheduler.log</string>
              <string>-u</string>
              <string>#{ENV["USER"]}</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
      </dict>
      </plist>
    EOS
  end

  test do
    (testpath/"hello-c.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/gcc", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", shell_output("./hello-c")

    (testpath/"hello-cc.cc").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/g++", "-o", "hello-cc", "hello-cc.cc"
    assert_equal "Hello, world!\n", shell_output("./hello-cc")

    (testpath/"hello-clang.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/clang", "-o", "hello-clang", "hello-clang.c"
    assert_equal "Hello, world!\n", shell_output("./hello-clang")

    (testpath/"hello-cclang.cc").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system opt_libexec/"icecc/bin/clang++", "-o", "hello-cclang", "hello-cclang.cc"
    assert_equal "Hello, world!\n", shell_output("./hello-cclang")
  end
end
