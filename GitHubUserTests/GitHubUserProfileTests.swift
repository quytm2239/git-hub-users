//
//  GitHubUserProfileTests.swift
//  GitHubUserTests
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import XCTest
@testable import GitHubUser

class GitHubUserProfileTests: XCTestCase {

    var userRepo: UserRepositoryProtocol!

    override func setUpWithError() throws {
        userRepo = UserRepository()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadRemoteUser() throws {
        let expectation = XCTestExpectation.init(description: "Normal waitting time for remote fetching")
    
        self.userRepo.getUserProfile(userLogin: "quytm2239") { result in
            switch result {
            case .success(let data):
                XCTAssertTrue(data != nil)
            case .failure(let error):
                XCTAssertTrue(false)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5)
    }
    
    func testLoadLocalUserSuccess() throws {
        let expectation = XCTestExpectation.init(description: "Normal waitting time for local fetching")
    
        self.userRepo.getLocalUserProfile(userLogin: "mojombo") { result in
            switch result {
            case .success(let data):
                XCTAssertTrue(data != nil)
            case .failure(let error):
                XCTAssertTrue(false)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testLoadLocalUserFail() throws {
        let expectation = XCTestExpectation.init(description: "Normal waitting time for local fetching")
    
        self.userRepo.getLocalUserProfile(userLogin: "quytm2239") { result in
            switch result {
            case .success(let data):
                XCTAssertTrue(data == nil)
            case .failure(let error):
                XCTAssertTrue(false)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testUpdateNoteSuccess() throws {
        let expectation = XCTestExpectation.init(description: "Normal waitting time for local fetching")
    
        let ranDomNote = randomString(length: 300)
        XCTAssertTrue(LUserItem.isValidNoteLength(ranDomNote))
                
        self.userRepo.updateUser(note: ranDomNote, userLogin: "mojombo") { result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
            case .failure(let error):
                XCTAssertTrue(false)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testUpdateNoteFail() throws {
        let expectation = XCTestExpectation.init(description: "Normal waitting time for local fetching")
    
        let ranDomNote = randomString(length: 301)
        XCTAssertFalse(LUserItem.isValidNoteLength(ranDomNote))
                
        self.userRepo.updateUser(note: ranDomNote, userLogin: "mojombo") { result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
            case .failure(let error):
                XCTAssertTrue(error.errorDescription != nil)
                XCTAssertTrue(error.errorDescription!.contains("too long"))
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 1)
    }
}
