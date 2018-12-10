//
//  StorageTests.swift
//  StorageTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class StorageTests: XCTestCase {
    var storage = Storage()


    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSetGetWithoutExpires() {
        let data: Dictionary<String, Any> = ["foo": "bar"]
        storage.set(key: "baz", value: data, expires: nil)
        _ = storage.get(key: "baz") ?? [:]
        _ = "stuff"
    }

    func testSetGetWithExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz") ?? [:]
        XCTAssertEqual(data as NSObject, retrievedData as NSObject)
    }

    func testGetSetWithNegativeExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60) * -1.0
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz") ?? [:]
        XCTAssert(retrievedData.isEmpty)
    }

    func testDataTypes() {
        let data: Dictionary<String, Any> = [
            "foo": "bar",
            "baz": 10,
            "bzz": 10.5,
            "lol": ["huh": "yah", "right": 10, "yup": 10.5],
            "millis": Date().millisecondsSince1970
        ]
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        storage.set(key: "bzz", value: data, expires: expires)
        let retrievedData = storage.get(key: "bzz") ?? [:]
        XCTAssertEqual(data as NSObject, retrievedData as NSObject)
    }

}
