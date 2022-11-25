```bash
istioctl pc secret ds/ztunnel -n istio-system -o json
istioctl pc secret ds/ztunnel -n istio-system -o json | jq -r '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode | openssl x509 -noout -text -in /dev/stdin
```

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            46:b2:7f:58:26:e0:06:7c:60:b0:37:f1:e5:ae:86:69
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: O = cluster.local
        Validity
            Not Before: Oct 26 05:51:40 2022 GMT
            Not After : Oct 27 05:53:40 2022 GMT
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:be:a7:10:75:2e:04:90:7c:8a:39:33:c7:16:0e:
                    00:e4:70:5f:f1:6c:f0:c3:34:7b:57:48:8c:00:9c:
                    73:02:d1:27:7d:b3:41:29:55:b8:54:3d:f0:df:84:
                    27:a7:d6:48:89:bf:55:f9:98:97:ae:a0:d4:3e:92:
                    8e:b2:8b:ba:f1:60:c3:c0:1e:81:69:8b:47:a9:8e:
                    5e:d7:8f:0a:84:4b:ab:13:58:8a:aa:e9:88:6d:85:
                    38:c1:33:87:1a:ef:67:0a:63:27:be:f8:b2:58:e5:
                    11:eb:47:ab:e2:c0:fa:87:ba:5e:e5:de:24:f3:18:
                    4c:32:d2:55:7c:e0:77:70:e4:a9:58:a0:a7:8c:9d:
                    01:31:f9:e1:06:0f:6e:f2:4f:60:b4:0a:e0:00:cc:
                    23:a5:e3:eb:5d:ea:4f:9a:b6:8b:1a:e1:fa:34:b1:
                    3e:b0:8a:a8:06:07:ce:2b:71:04:c7:7c:e8:a3:c5:
                    c2:47:e6:45:ff:1a:0e:1a:88:ff:f9:f6:19:ee:e2:
                    24:15:50:5d:e8:13:1b:3b:ed:22:6e:5d:b8:5b:1e:
                    41:0a:35:99:f7:8d:bb:c3:e8:ef:2d:e9:77:41:8a:
                    e9:97:f5:bf:c0:11:9e:eb:a8:aa:af:9e:39:31:30:
                    b8:17:12:5b:68:d4:2f:1d:9b:41:66:4d:86:39:c6:
                    9c:5b
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                01:B5:FA:53:DE:A8:1F:23:2C:27:A5:FE:35:26:B8:9B:D5:44:12:DF
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/echo-istio/sa/echo-v2
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        74:7b:64:4c:b6:ae:cc:35:70:08:d4:f6:48:7d:92:55:00:92:
        d5:33:bf:c9:69:19:3b:73:71:ea:d1:b4:0e:1e:4a:54:fe:ae:
        4a:6a:9a:1e:24:38:16:e7:a7:78:b5:fd:d6:fd:53:60:6b:d0:
        07:ea:4a:3e:37:bf:e3:4e:93:21:81:cf:5f:85:94:c0:29:13:
        67:2b:fe:6c:6f:97:d8:d2:c1:e6:c4:54:97:5c:a2:18:8d:94:
        c4:14:8f:74:c8:de:ac:2d:b6:c9:5d:3f:0c:60:8e:3f:55:01:
        e1:e2:33:82:45:d3:7d:48:66:7b:84:3a:ab:59:7d:f9:f3:f2:
        53:9d:2b:78:a8:54:c9:b6:f1:92:c8:70:97:23:1e:9a:6c:24:
        d7:6b:95:14:2b:4d:74:6f:b8:a4:c7:1a:c6:e8:dd:eb:c0:d1:
        ee:1c:25:99:c9:aa:5d:09:0e:83:6e:a2:58:3f:cc:ed:a9:f6:
        36:dc:40:9e:85:ed:79:a2:90:cd:09:e2:ea:08:99:c7:eb:49:
        8b:45:47:23:63:56:61:a9:56:d5:35:10:16:24:e4:d7:db:99:
        e6:7b:9a:e1:80:88:a8:40:9f:be:3f:c8:50:9e:98:71:70:9b:
        b1:f0:e3:ed:6c:3b:ad:24:d5:60:82:6d:1b:22:28:1c:87:4f:
        6d:72:78:8b
```
