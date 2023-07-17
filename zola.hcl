description = "A fast static site generator in a single binary with everything built-in."
binaries = ["zola"]
test = "zola --version"

linux {
  source = "https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-unknown-linux-gnu.tar.gz"
}

darwin {
  source = "https://github.com/getzola/zola/releases/download/v${version}/zola-v${version}-x86_64-apple-darwin.tar.gz"
}

version "0.17.2" "0.16.1" "0.15.2" {
  auto-version {
    github-release = "getzola/zola"
  }
}
