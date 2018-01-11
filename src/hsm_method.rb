class HsmMethod
    @@luna = nil
    @@aes_kw = PKCS11::CKM_VENDOR_DEFINED + 0x170

    def initialize(luna)
        @@luna = luna
    end
end
