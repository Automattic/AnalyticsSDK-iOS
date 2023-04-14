import XCTest
import Nimble

@testable import ParselyTracker

class ParselyTrackerTests: ParselyTestCase {
    let testUrl = "http://example.com/testurl"
    let testVideoId = "12345"
    
    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: ParselyTestCase.testApikey)
    }
    
    func testConfigure() {
        XCTAssertEqual(parselyTestTracker.apikey, ParselyTestCase.testApikey,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackPageView(url: testUrl, urlref: testUrl, metadata: nil, extraData: nil)
        expectParselyState(self.parselyTestTracker.eventQueue.length()).toEventually(equal(1))
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.trackPageView should add an event to eventQueue")
    }
    
    func testStartEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]).toEventuallyNot(beNil())

        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement, the internal accumulator for the engaged url should exist " +
                  "and its isEngaged flag should be set")
    }
    func testStopEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)

        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]).toEventuallyNot(beNil())

        parselyTestTracker.stopEngagement()
        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]?.isEngaged).toEventually(beFalse())

        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssertFalse(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement followed by a call to Parsely.stopEngagement, the internal " +
                  "accumulator for the engaged url should exist and its isEngaged flag should be unset")
    }
    func testTrackPlay() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.isEmpty).toEventually(beFalse())

        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.trackPlay should add an event to eventQueue")
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to parsely.trackPlay, there should be exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssert(testVideo.isPlaying,
                  "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag set")
    }
    func testTrackPause() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        parselyTestTracker.expect({ $0.track.videoManager.trackedVideos }).toEventuallyNot(beEmpty())
        // Previous version, for reference
        //
        // expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos).toEventuallyNot(beEmpty())

        parselyTestTracker.trackPause()
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.values.first?.isPlaying).toEventually(beFalse())

        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to parsely.trackPlay followed by a call to parsely.trackPause, there should be " +
                       "exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssertFalse(testVideo.isPlaying,
                       "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag unset")
    }
    func testResetVideo() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        parselyTestTracker.resetVideo(url: testUrl, videoID: testVideoId)
        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 0,
                       "A call to Parsely.resetVideo should remove an tracked video from the video manager")
    }

    // A helper method to safely inspect the tracker's internal state.
    private func expectParselyState<T>(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @escaping () -> T?) -> SyncExpectation<T> {
        expect(file: file, line: line) {
            var value: T? = nil
            // Calling `DispatchQueue.sync` here is not ideal, but this is a convenient way to take advantange
            // of Nimble's `expect(...).toEventually(..)` DSL.
            self.parselyTestTracker.eventProcessor.sync {
                value = expression()
            }
            return value
        }
    }
}

extension Parsely {

    /// A helper method to safely set test expectations on the tracker's internal state.
    func expect<T>(file: FileString = #file, line: UInt = #line, _ expression: @escaping (Parsely) -> T?) -> SyncExpectation<T> {
        Nimble.expect(file: file, line: line) {
            var value: T? = nil
            // Calling `DispatchQueue.sync` here is not ideal, but this is a convenient way to take advantange
            // of Nimble's `expect(...).toEventually(..)` DSL.
            self.eventProcessor.sync {
                value = expression(self)
            }
            return value
        }
    }
}

