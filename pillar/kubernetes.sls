#!yaml|gpg
kubernetes:
  lookup:
    source_url: https://storage.googleapis.com/kubernetes-release/release
    source_version: v1.21.5
    install_dir: /usr/local/bin
    k8s:
      statedir: /var/lib/k8s/kubernetes
      etcdir: /etc/kubernetes
      apiserver:
        cluster_ip: 172.16.0.1
        secure_port: 6443
        insecure: False
        log_debug_rbac: True
      cluster_dns:
        override_resolvconf: False
        nameservers:
          - 8.8.8.8
        domain: internal
        cluster_domain: cluster.local
        search:
          - service
          # Additional search entries
          #- 1st entry
          #- 2nd entry
          #- ...
      networks:
        pod_network_cidr: 172.18.0.0/15
        svc_network_cidr: 172.16.0.0/20
      authorization_mode:
        - Node
        - RBAC
      security:
        - allow_privileged
      runtime_config:
        # Enable/Disable specific resources:
        #- api/all=false
        #- api/v1=true
        #- ...
      admission_controllers:
        # Enable additional Admission Plugins:
        #- PodPreset
        #- ...
      use_ssl: True
      enable_cert_issuer: False
      log_debug: False
      ca_cert: |
          -----BEGIN CERTIFICATE-----
          MIIDUTCCAjmgAwIBAgIUHrLxO6rc1J7q1Qqr1/lyTjPqAncwDQYJKoZIhvcNAQEL
          BQAwODEeMBwGA1UECgwVS3ViZXJuZXRlcyBnZW5lcmFsIENBMRYwFAYDVQQDDA1r
          dWJlcm5ldGVzLWNhMB4XDTIxMDIyMDEwMDg1OVoXDTMxMDIxODEwMDg1OVowODEe
          MBwGA1UECgwVS3ViZXJuZXRlcyBnZW5lcmFsIENBMRYwFAYDVQQDDA1rdWJlcm5l
          dGVzLWNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzMdNoYqZ33iS
          muJ9Ymu8wThBrs/WOI1zkZT3v8eIwEKQBZGZZQ7NuvnAsuLVw7teNRqv9XbP3oyS
          6ZG70AZeVoUZqxP9xUCm33Hisfqm5N+CrjF58k3qczMmeyN3G+70AoPDT5f8+X0O
          E9jm1w3NLU+UlfNroDifz9jFFgynmKdURLg9/48QShkqLq7VGQcTwO55IT9sB6ps
          Mp6A/JkPgN7o5+zUp0Vadbq6DihhNsuLDOotVVq7dvmfnis6U2Gy4ChT71GC3ODe
          CzQU0OfUvHZRA8AVsC3bEdZMbr7RZ2GiVt74L6O4zc+zOMEkq48OiivJOdTFDFPR
          KzgY/e/cqwIDAQABo1MwUTAdBgNVHQ4EFgQUYTuh4k0U+V/+7+AkBZmOJl3rpIUw
          HwYDVR0jBBgwFoAUYTuh4k0U+V/+7+AkBZmOJl3rpIUwDwYDVR0TAQH/BAUwAwEB
          /zANBgkqhkiG9w0BAQsFAAOCAQEAdbBsOJimlMeisX7rCjM42tsZ67/wFW0OorHo
          Zm8mgJ5IPDjUnpy289CgmYdYNlhSa+4sa9MFFDYGWSEe17JvNf5BvnO3L5Tq9hV2
          /ElJ+T4eR5rI6q2Vttwz6Lo00+6xgeklvtm+329fgQfciX3reAp727OUCD1xQn/D
          ZpexT/Ag0wyP3X+dJJK0nOBB4YpEjy8GKp+Qx05YCULLdSUjMSXldsDTDC/zzTlQ
          vgOTUj3iz4oHqhPwAxrGk64QGS43EM3DOW/sX93kpmWK9QVL7FSEa2weWHpZLwFV
          FM3f8m0npUr3IYxl4jGrtgos9WVUk3rOCgxMwuxIlHo86KkRkw==
          -----END CERTIFICATE-----
      ca_key: |
          -----BEGIN PGP MESSAGE-----
          
          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
          FUABZPZfys6tVlySQl0SFw==
          =AOxX
          -----END PGP MESSAGE-----
      service_account_signing_key: |
          -----BEGIN PGP MESSAGE-----
          
          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
          AxHHt0CSByIYLtHNS4vG
          =0VU3
          -----END PGP MESSAGE-----
      service_account_key: |
          -----BEGIN PUBLIC KEY-----
          MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtqds5XQ4etzVCq3u8sFX
          E33vvRLbmHaVpymuLICTjvdnIpVuMkP0kKEV1VZ9BaUDCjPoON2ru+RQi4kakOs/
          7W2ezvqbkjyj4Zx7yd7FaWVtrgP5D1UdaMDAEukUPllwkdAkB/yPHG0kz8F0oVsY
          IFvfP83xxnZuu6JCChppKu557f9fuf2ZgjzcauKmKDDINmpKo9KACHrnrL0y7/aC
          +2zRS7l/4bqsS0/58AD5rMVOvW6XGGW3E9HiHCLbbeYz2g6myTiFBWJz++NOm3gF
          t3v3UcVFG5dGfEq3kxVo5Fs1eEqio1OZibTZx4X2rNUe9fvi4bEOyzg0TXBnYHNQ
          0wIDAQAB
          -----END PUBLIC KEY-----
      proxy_ca_cert: |
          -----BEGIN CERTIFICATE-----
          MIIDLTCCAhWgAwIBAgIUT8SyZR6l8cyZdM2fwzAWXGU7eLswDQYJKoZIhvcNAQEL
          BQAwJjERMA8GA1UECgwIUHJveHkgQ0ExETAPBgNVBAMMCHByb3h5LWNhMB4XDTIx
          MDIyMDEwMTA1NVoXDTMxMDIxODEwMTA1NVowJjERMA8GA1UECgwIUHJveHkgQ0Ex
          ETAPBgNVBAMMCHByb3h5LWNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
          AQEAymBLBptcpJfaAStvbF5IKjxCrHIQ2bri/zNYrXta79qtJC0TVwI+6NYURpbG
          ACa+5BzQIkxkhyubEFjViDLXFz7UcC3BKoQnkiB6RuPLYSSdOX9hOm0+t0cPznhm
          mfiikoVf1zuuaivWdxjWenhsWJNB7waVjHanMjJYu4wAzhzchpFSsawaS9W3Zfcw
          pORcX0TPI6oyEhfI9LnJV3uq7RXqPBUk44HLed8BWpziSPgB+QXCJMPStoIYffy0
          du9LBUatj5imF4GTd6Zf/YO013cqkM/WA5qfxCb/IUQHey3fjHD0OkP/JmR6qOdw
          5GLhi4N82VWyzD2SYEsIG1iOlQIDAQABo1MwUTAdBgNVHQ4EFgQUEuFQfeNk14g8
          Wk7s739ifNegyOkwHwYDVR0jBBgwFoAUEuFQfeNk14g8Wk7s739ifNegyOkwDwYD
          VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEATnUTdR7AHABdgKwh4H6m
          Zh/qApliGCG5cfPPvBPO/KvkSmYMOjNFm+F0DgjrJlWuzgAUUQ1xiKjtPeEjRTb8
          lDQ5ix6E3zcbq96DwtJlFp0w9e9cLb4xeCuww/F3AUSq0qLi1qDvpOxLOeMSXI4x
          PUUtXa2N2l4S65vztj0Y6a9vMlFN1ZcMx/2uMFgZlcF2JejSEmssSS18+C3yUTsZ
          FYN8VgYfm3CL8pL9QerLfJ4SxoAxVvTHtUf9aFkaP3+hTVyaZnkRwVokGEX0PLHp
          viNR2NREQBa86eAvWluYwlDbK7GzIrktQ+Q7vtyG/njjKF8dW333au0IJGAqs13b
          TQ==
          -----END CERTIFICATE-----
      proxy_ca_key: |
          -----BEGIN PGP MESSAGE-----
          
          hQIMA7gFvY0/3uAGARAAggJsWgzBhmAwYIEXhytokh9RkZt8oMagRKTICFGMSFom
          cikHWgidBzvhTaUqaDvj5ivKs5GyxvCdVsA9h5Wnhd0U6IICf1mxv3gIpQOSSgeD
          N7ie8QHzQbAawSzWLys00d+HNGR0qHoAKEQ0hkpUX9R3zd2KQtf1ioEfiq781dd4
          Ynrs9T9750RofvCLP7KkOg1CS/eqVSCp82RfvwRENgSFY2gcMxaeijdC1wZcRh3x
          oPQd8FGaN0sSf9ueYbfmWPcbmtc4iRfvKVPKtCBvNCny2YjG8NPFNYJbMlU4L6dl
          1Ps3J+ifFfKXBbFUH2kKPkLQzb0WFiA9r6FHJ0eZlTyr4FZ92LsilMu349C4FWdu
          QsctJn5DHIrI+qG5TVzCIzOCg0Y27HJ9L1xEzT3aM97/2u5Osp1Cyr2WPXKntbbj
          bZjVhYsRAAUtOrJ8iO/uPThlCSsDb37Ip6zF0B4c8mXHfm4Ce4h+osuoWAl4f6Sb
          s8DMHr4BTQxAk0AyGikPaRIQg5HkBQByaeuBm7KIy8b/kB07jKso0IW4xj/ftc8v
          dH1z4gxx3DeFtn0Q6JHGGKrACTE2BrFDcYzXCfGzE8viEkXG9GWXkNNj/obtAYvO
          XBfF54H8tD9spdq7ynO5imNvmSrCMZQKPcw29hpaO4MpihWG8mmzB9SiQHeOdrPS
          6gHCxSfZtM5q6bXLPf6A9RZp98WdeCxGFIam+7eHK+L7EDJqy7hFxG+zX/6yMhD6
          XbRVnSPLZ2sooVzYCYJs4zv/sFxpT/MqTR88Ym9XqrwzUCTvX2SxmpBsp5aMW2Cx
          Smn/xKVDJyTeCKCyYWWHfVhZ0LkF3+zd35/Vc3WNHYs6mRT5Zz3VTL7+qaaxOsU5
          xYpLr43dao7SaMuKtPffJMmm2gsOJ0Y1bMa5Faf+4VXd1Bn0JeLGEq6mL5sNHdSS
          najg5yvGnMuH6J5ZHqlYWdXm2ed5+IQMgmJQR9/gDLMPPrGCJGVz5hPgTLx1luqG
          w94OQWgc4xev0oqzaZngdixff5B25LsYckO5ixim6Vbk7M42S2vqeT3O+//LhkWN
          PgFDhJF81QCVMvLBXrYeAwqycxY9xAOQERoJkNlK8nIFOnUaH+pw2ZpwSIA2oi20
          SliRfKNhwm+1PpbLn4NYdnHf1y9yz2MWPMoCa8koLAPE2WExzivF1wWRZVFeB52o
          Qd7HN7l7870lFxp3D69jKTl05qxdESJD5TV57VjUGETK9kMzWuKqxz7Mw+Epw1op
          khtdlWECls1Sl3cHTypEXWGpSvJZPYxsOnBmqeQtNk6Z6Hm3qBW5CApFyG5/gPZ9
          fUFNnejnj5LzsEKWm0bAWWaR469Q7SX21hsCTssZ21/io7tEO+xAXitkVK6wDEkJ
          ln5CBx6UNLGxqGTKZv08kYYVYdAeBcX6puiUZVuQ2MXpn2IS8czm080LZ61MJmd4
          BQPPUVKt6sKwKkWdgTKRttuWi56X7RW2vdweDmVqI29Ovv47+NAVX0v0Z7AW+486
          xsObg9/Jjat6eQv5X3T/xz1lConz6+Y4c/AawxjC0WhZDfSB9kovrHIWQNogoJev
          B40ZB+Or9jwYHkgyXV7+HH8mrzroul5raUZfIS0oA2mRDZhpyPoyhiBtLVPI6M3+
          wVLllUnYjl+toK6t5WO/RXbEBfkG96iB+x5tf3DRL/ONshx79UcOr3vDdRq89yXx
          zGoZsQmVVY17KLXHBMhA3ABVdp6JLz+oVe18ZTvn4IadPR23RQxHKsEnRQkF1umZ
          v+M54hXfdZ7DLricEj2iKWrgRMHdcHQCKLmJTwec085RFv7972LU+JqTztjVXUn5
          Vs1MqSH9DKsz3vfEhbOdRYDtgw++kyDnyq/p5Dkk8Mgtw/V0HJ7S8NKBAuuj6XGf
          NUdZC/XNj/zOuIUTDMrlVheOHUUnYxurFLALnHb+pO9gcBLcAl5JC56mAEDRj2Nq
          Qidt7wRiyg0iPgzDxFOj+ItXP3xy8YZJP1yLVeAwyvax4VWcvWYG7AW3RTkoP/VX
          dKA3B2PeWpq8RdzC+SJ6ZffAjsH2lF6/G4W57fR4aQs1Ps3rI/XiTaTh5C2D3G3s
          ja6gmBX+dq0sewt+1PHLwKR5l8NGULy4bIwuzqt6KGWfOn1pTxrG2ztCnSsue5uH
          JY9a4quUDmLJMAI5XKo39QEy370OdPFfVyf7co9+vqCBY3cPD+m12iDdpHJJiKLn
          lAlJQCNx0uJ9ayYO2RlJ6x3k+WblN+GYkBj1MfXiYhiYw2PhWo50MmKvPgmdpHWF
          0ogx4L8zaNMy+sTGfdnu2JlYJvsD7YaSwsJx3O+JIlWKRQpTcxwVTDQD4pKIsKpw
          OUhIqFo/iEqpUyA+BrHw77MDJ1DLlbYbhE81+iRyjrFJLd3Aburto+VMu2Jv0nmI
          7ph27iygtPXwu2EqB8SpyGz+JL5HylYfiO3FPjlL3gF3/JKYBSElK/Nq66JwhlyC
          /XQ6dKHrKUWL9hrCfBPLZys=
          =U6+h
          -----END PGP MESSAGE-----
