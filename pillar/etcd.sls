#!yaml|gpg
etcd:
  lookup:
    source_url: https://github.com/etcd-io/etcd/releases/download
    source_version: v3.4.18
    install_dir: /usr/local/bin
    etc_dir: /etc/etcd
    endpoints:
      - https://10.81.10.1:2379
    cluster:
      name: k8s-etcd-cluster
      peers:
        - name: thinkpad-e495
          ip: 10.81.10.1
      initial_cluster: True
      ca_cert: |
          -----BEGIN CERTIFICATE-----
          MIIDKTCCAhGgAwIBAgIUA1xmfVl2S2Gzgpvf3RA1PqIW7l0wDQYJKoZIhvcNAQEL
          BQAwJDEQMA4GA1UECgwHZXRjZCBDQTEQMA4GA1UEAwwHZXRjZC1jYTAeFw0yMTAy
          MjAxMDA4NTJaFw0zMTAyMTgxMDA4NTJaMCQxEDAOBgNVBAoMB2V0Y2QgQ0ExEDAO
          BgNVBAMMB2V0Y2QtY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDs
          nsHdUgjlyXSTtQRMkz1QKkzG0A4Wi74ux4I+soU7coniYZTOqp9esZO6YvXGXfdX
          TeSVbxUtgUZJkwhJnbbouUIB9E2XUlxphBgbFWQfKjv9Rihrm34vq6MqKEr9kxH2
          JCCWQ7I5T/zPUeeZJkxDJB7O3wRsH2W2OjTSV9R1l3P/kJlNs+uZyxD+Ewd/BM3d
          AUcXotZMFEf7LiTZc9NH+EpER6guSGuKiYKcmRjneVweKwkCtPO4RqWdiHrmKgAa
          IHpDk1vF0oKUX6rywfKmVKwterWKj/wR1ENiKfjPfSh5fkDIAYl5Q02hCRYbm0LE
          VHI4lO5J5uwLlgoBqdlPAgMBAAGjUzBRMB0GA1UdDgQWBBSjF9IWldLehPP271TO
          BQFGIlfnjzAfBgNVHSMEGDAWgBSjF9IWldLehPP271TOBQFGIlfnjzAPBgNVHRMB
          Af8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQDPCGElGzuTpP1CDvRmSehKuoGG
          DEa4xW3ay7dktu7yK+Deo1M/ZbnJB6C2R/M3yX6B/r6RAdW5FhlU7fkpdzH4gkb8
          rHU8CUYFbavSi5xVDJhI0o1I6JgeyoNRd5uidQWNjENNWI6GDLNsA8M5DR4S/m9Q
          5HuvlBiTySMNgPG8Wqm63md+uxY00t1JSdYvA/s2YBPxGrpkqC6xdc/YtRNIVLs1
          i/oqSCDA/wg+svR5BOv36EbswqxpOgjcJblxei5disou5137mGNmSVswAIMXXjDx
          ZPYDcN3GN18QsTMNvJvOkUG19qVSfduR0Rz0kc1CxO4pI5H01ARBt6gNOX3I
          -----END CERTIFICATE-----
      ca_key: |
          -----BEGIN PGP MESSAGE-----
          
          hQIMA7gFvY0/3uAGARAAxzO4H/TokAwc2P92CTijrXLjKjw1aVXZwuTaKhyUJPHf
          8LzFYZl41SxkW/jRIv3+xGPm1sEKu47tFfusTNqQw7LrwaPq6QS8ZFdu19iq56I9
          jTd0QmWu4FgyHoSAO7Mr2yMENG0tNBGp0UuV7WGnat/gd1nNJxMbGXbGnZ1AxFw9
          J94vH9AnwBk3keX+qEtVqf7TX8TyShWIJPmWiPY2Ev1Ag7Vq8C6xXolMJoOMD7zV
          EY4dcAkTKOsjOio6BMG3vTibnmUjENHDj2mUi4o5ytAbusTstqxM+lmQ3OmgdtCw
          +DDmGW1jZj1qKe4JkuwRVWoTxPfGnckaClVfzGFuAxZYeoP24/FSxTCS5N5pApyZ
          KPCCwTNWTnNm1qENB7Z0L1baXXcLsMto3sxDWzeGvqiVw53yOZ5U8xQkfN6938ws
          mZL1M9O/7WateEPfSaus6uqEuNfOQ+I/5wy7DmjS1RMeBBJ8yv4HPEsHqSXl4WY3
          xNxLWMJH4eOM6n+MW3UIFl9qx3C7iloGBVRstWZKH1V2A7eSmxFt5OBu1wviUu6k
          4+k12jFmucF9ADEIHR8WSThFYPl9eLsq0gtRcmQOZ04SS6nXypZSOomJ2vFU/p9O
          yKyQQuWNHr10iGeCeH6kw9O0Kd3vQiGk++D70rux/+RG1wkiHINySFOrxSam1knS
          6gGNwlssfzsv0gr+/2GJvln8WVRzPNcdMxm47E3XF0YkUFhCVHKT73JiBM5BBgb1
          RVz8+GZJddmspFHFiVa7B1iWm2xw69PVCYSFSMi4OXJcfXCRIOGZEd2f9QSinlCF
          S3V1l8SQl3l4UkwrCiC1KKbBO/y333aG9jg5wx+9K7XUKnCmGnJaRsNJlo7jVTUY
          sd2sjlFsUNGli7bd/iqfUX55zH/BlENQxfpRUaw0M6baRQKi8gv9itPmuURl1Kxd
          h4q3EikWCbDUdCGq8b/kdPUZYmzablh7EsEwrp9Sey41tHqvfFJeO8QMcRUCpO8s
          x45NhhEyXo3uzDAmRB7hlVXTIHMibJHNdEFtkHGFVzDxWeSpD2hnX54d1v7MUTvc
          3Y7Sx87uNLMKP0t+G4uh8SNyMwhW+07AwMOYkRY//csoNeAyxObkcnH5LqUpTzSw
          qFe9n89+eeSwAXsKFW2gMGes/KDQx3E5xtRxb5+sRt2flHInZXR2mntCPr43ghv8
          9m4LkLuVKkn/8PZYSjeU4B1QPI37qgVIiKkcHXQbe40QEYvxzjexRAwP3u/9x4ry
          31tPz2JkIHgASxpz5vSVjn1zCKHXtnvb+zNAZJ6SpRKpIuRwAlOSkRYsDAzuPKB4
          YuGVRpHesdjBDxR7a1K1k7SJfA7JamHRfGFZcGfU9cewhJnFWvHxr/ezKZTIdPow
          7ckboMeeI/dcwHaaEpZu3QQBdYr+l0WlwJhz5Nq9gLthZ63/TNshjMLx0MoCWEfY
          bovWL8KUxcy9+cWW51yKZPZmyau7ZKxPvoYWG2ohm7ZGoOj8yST5TmHjpHkEGAXk
          2A8zswYMrBvqZQv6BnAJRF9At0SGhRcYT+JSWObuCvsDPqttChetFee+dMqFg6R8
          GFFXBcFf6F2S60fjPpuYJTrk1j2IXiPFrFdn/qOsCDKyIpV50JWkmgRs24uwQzvx
          w+Xxcp5BeBOle7HT0PtaEq43Lhc11QwP6mzNgImdI3FnrrmQDXMIPa1M0abT0K/K
          VmdgBR1VzKkFqunOJpMCYWAlQ5OkcH/YuDsh0aTKbkf0e41CrtwtO4Z0NZgmBwMI
          wDwuQO5xnUp42QSbQwu+64Oie4vA7Xv3M5MHs7T4oytNplsAxUVfl0ruGRUQT7KN
          OlPHh5DuZAPdrm+uNHKglf24WNtfafJZwEqZC37rpwvApvuqcpcMxukgCATUDR5x
          kHJ0AUewBB+lqAk55+smZVs9RKKNxAqjvh1FJElvYW8i0ZkzPQN3eoSQwTs7wQSE
          6dU8VGKYMyl8XSh/x/GLeoV/I2buMC6uOOtUZuig5gj10vGlrtgOEeEfVohUsdjw
          FAT1bxyzAvaCb0ZExFMMKNXAjD/2ENtUXo1c4on8i3hzvS0OpY2ZklQJyC/3/jsv
          GB0z8ylTy9ffZb0HgPFSPc6O4DrctuKzUhUt/p58DBouK+4v1VkRVQ47/DVYOHZ3
          XDOTrVHT9wd4zx62nKMtusgK9+71/vwnuhtNuIfudNhiFnLKRwbmoa0N1zLsbyw9
          VtQ+Lf5irzoremAEU3hThnaigSSDkm/GJ96z6wXBuvIsPurNsb+RyPy2jc4kzwtN
          B1khE7aiQmFbUUNMqdAstPattoQ9AB5Ea6FvpUI/4W39LAAIK0k85dl0fXjfEX3s
          TE5G3D8hJZrlok6eHPbWU56N5vTId90lGom08GPr7SKTD2ImCvyLGhe414XFhFca
          ZsIbwnjk8wh5PUgRb/08lV58Q81TxsB+7T09iQ7N2rLxl+dvXuWkeAtLbtd/7zOL
          bWsmGSCTF+PhFgsQXYhs
          =KJOA
          -----END PGP MESSAGE-----
