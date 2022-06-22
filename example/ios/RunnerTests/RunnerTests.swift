//
//  RunnerTests.swift
//  RunnerTests
//
//  Created by Maido Kaara on 20.06.2022.
//

import XCTest
@testable import Runner
@testable import yubikit_flutter

class RunnerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCalculateECFingerpint() throws {
        let timestamp = 1652084583
        // 16092b06010401da470f01
        let curveParameters = Data(base64Encoded: "FgkrBgEEAdpHDwE=")!
        let publicKey = Data(base64Encoded: "QBiUUthBZXiK4poM1JTSx8Ae7KUzO1Qm/vbVLNIGyRqu")!
        let fingerpint = setECKeyFingerpint(publicKey: publicKey, curveParameters: curveParameters, timestamp: Int32(timestamp))
        XCTAssertEqual("D25515C366D77B8E9B66CD4BAC6B363B0C5A4FBD", fingerpint.hexDescription.uppercased())
    }
    
    func testCalculateRSAFingerpint() throws {
        let timestamp = 1652084583
        let modulus = Data(base64Encoded: "ANGvy2jusiy/cicp84GMZnOcDRc1MdPHD1aBUVEIvxeEEpk6S6fwhObREEPOHBn5rhx2bm09S+xjAvdxsDkTF5POqPPPKkJfdwX1EWxzKUrgEUHoqyxZEfZDSM1KsIWq8h0X0sv19W/NG0/SeEd0GMR4jSunqq1QU31wU/9kpJg22KzPAtHRcPbc9GZjOi9uzXWji9CKfwH8kRZHr9zXCzG2Q/Y8eeDGzsgLnJ+jKeMp7LjdWWbIz2mmwq+bIQwgnVnC1An/F16YDH7IzAZdtAscgPnmdvn9o7LyKnpIfXNhyI36sax1fIsvwBRsGBrYjn/WdqPktFZuXLPZTvGjZeM=")!
        let exponent = Data([0x01, 0x00, 0x01])
        let fingerpint = setRSAKeyFingerpint(modulus: modulus, exponent: exponent, timestamp: Int32(timestamp))
        XCTAssertEqual("f9c529ad74884a662384b287cef59add4a28b99d", fingerpint.hexDescription)
    }
    
    func testParseSimpleTlv() throws {
        let data: [UInt8] = [0x60, 0x02, 0x01, 0x03]
        let tlv = Tlv.parse(data: data, offset: 0)
        XCTAssertEqual(tlv.tag, 0x60)
        XCTAssertEqual(tlv.offset, 0x02)
        XCTAssertEqual(tlv.end, 0x04)
        XCTAssertEqual(tlv.length, 0x02)
    }
    
    func testParseSimpleTlvAsMap() throws {
        let data: [UInt8] = [0x60, 0x02, 0x01, 0x03]
        let tlvData = TlvData(data: data)
        XCTAssertEqual(tlvData.getValue(tag: 0x60), [0x01, 0x03])
    }
    
    func testParseMultipleTlvValues() throws {
        let data: [UInt8] = [0x60, 0x02, 0x01, 0x03, 0x61, 0x01, 0x01, 0x62, 0x00];
        let tlvData = TlvData(data: data)
        XCTAssertEqual(tlvData.getValue(tag: 0x60), [0x01, 0x03])
        XCTAssertEqual(tlvData.getValue(tag: 0x61), [0x01])
        XCTAssertEqual(tlvData.getValue(tag: 0x62), [])
    }
    
    func testParseMultiBytesTlv() throws {
        let data: [UInt8] = [0x7f, 0x49, 0x03, 0x61, 0x01, 0x03];
        let tlvData = TlvData(data: data)
        let tlv = tlvData.get(tag: 0x7f49)
        XCTAssertEqual(tlv.data, [0x61, 0x01, 0x03])
        XCTAssertEqual(tlv.getValue(tag: 0x61), [0x03])
    }

}
