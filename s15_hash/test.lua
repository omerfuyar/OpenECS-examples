-- the hashes of "abc" are the ones that sha256sum, md5sum and xxhsum give, and a file hashed in parts gives what it gives whole
return {
  preset = "preset.lua",
  run = function(test)
    test.match(test.session().workspaces[1].windows[1].panels[1].state, {
      text = {
        crc32 = "352441c2",
        md5 = "900150983cd24fb0d6963f7d28e17f72",
        sha1 = "a9993e364706816aba3e25717850c26c9cd0d89d",
        sha256 = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        sha512 = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
        xxh64 = "44bc2cf5ad770999",
        xxh3 = "78af5f94892f3950",
        xxh128 = "06b05ab6733a618578af5f94892f3950",
      },
      same = true,
    }, "the hashes")
  end,
}
