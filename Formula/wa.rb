# typed: false
# frozen_string_literal: true

# Homebrew formula for wa — WhatsApp automation CLI + daemon.
#
# This file is maintained manually for the bootstrap release. Future
# releases are written by goreleaser's brews publisher once the
# HOMEBREW_TAP_GITHUB_TOKEN secret is configured on the main repo. The
# goreleaser template in .goreleaser.yaml and this file MUST stay in
# sync — drift causes `brew install yolo-labz/tap/wa` to silently
# upgrade to a broken formula.
class Wa < Formula
  desc "WhatsApp automation CLI + daemon (per-profile isolation)"
  homepage "https://github.com/yolo-labz/wa"
  version "0.3.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.2/wa_0.3.2_darwin_arm64.tar.gz"
      sha256 "74c22ecab42099a8611ba50472158a1c2e78c89a4ab22925ff1a90d9bb3e8be2"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.2/wa_0.3.2_linux_amd64.tar.gz"
      sha256 "02970eb66e77f56659e224d4874bb52c8f421816b6ca6d796ea3a1d09949e56f"
    end

    on_arm do
      url "https://github.com/yolo-labz/wa/releases/download/v0.3.2/wa_0.3.2_linux_arm64.tar.gz"
      sha256 "625b940e8389f9b57c6ecfc1d20309b308507bf4b821c93e5b6442d781bcd0f8"
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
