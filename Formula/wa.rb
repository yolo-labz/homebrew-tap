# typed: false
# frozen_string_literal: true

# Homebrew formula for wa — WhatsApp automation CLI + daemon.
#
# This file is maintained manually until HOMEBREW_TAP_GITHUB_TOKEN
# is configured on yolo-labz/wa. After that, every v* tag push on
# upstream writes an updated Formula/wa.rb here automatically via
# goreleaser's brews publisher. The goreleaser template in
# .goreleaser.yaml and this file MUST stay in sync — drift causes
# `brew install yolo-labz/tap/wa` to silently upgrade to a broken
# formula.
#
# Latest bump by hand: v0.3.3.
class Wa < Formula
  desc "WhatsApp automation CLI + daemon (per-profile isolation)"
  homepage "https://github.com/yolo-labz/wa"
  version "0.3.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.3/wa_0.3.3_darwin_arm64.tar.gz"
      sha256 "0260c1def067408431b3e60762260bf7066795cda7eb9bca34eead3e7eb1959e"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.3/wa_0.3.3_linux_amd64.tar.gz"
      sha256 "64a026d59f5125af8e59d7a862235a7485164bbeaeda8dbf4709e34971681af6"
    end

    on_arm do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.3/wa_0.3.3_linux_arm64.tar.gz"
      sha256 "52b3fd2fe5140c5a066e9b169c88ca09576ee15d41b93bb82353285781886bca"
    end
  end

  def install
    bin.install "wa"
    bin.install "wad"
  end

  test do
    system "#{bin}/wa", "version"
  end
end
