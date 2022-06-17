//
//  GitHubUserTests.swift
//  GitHubUserTests
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import XCTest
@testable import GitHubUser

class GitHubUserTests: XCTestCase {

    var userRepo: UserRepositoryProtocol!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        userRepo = UserRepository()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
        
//    func testSaveOneUser() throws {
//        var user1 = RUserItem()
//        user1.userId = 10000 // mock
//        user1.login = "10000"
//        user1.avatarUrl = "https://cdn.pixabay.com/photo/2020/03/31/14/28/paper-4987885_960_720.jpg"
//        user1.note = "This is note for user 10000, ten K"
//
//        let expectationBatchInsert1 = XCTestExpectation.init(description: "Fast response for Batch Insert")
//        self. userRepo.batchInsert(users: [user1], validate: true) { resultFail in
//            switch resultFail {
//            case .success(_):
//                XCTAssertTrue(false)
//            case .failure(let error):
//                XCTAssertEqual(error.errorDescription ?? "", "Length of [Note] is longer than \(LUserItem.maxNoteLength)")
//            }
//            expectationBatchInsert1.fulfill()
//        }
//        self.wait(for: [expectationBatchInsert1], timeout: 1)
//
//        // now we reduce the length of note
//        let index = user1.note.index(user1.note.startIndex, offsetBy: LUserItem.maxNoteLength)
//        let char = name[index] // i
//        user1.note = String(char)
//
//        let expectationBatchInsert2 = XCTestExpectation.init(description: "Fast response for Batch Insert")
//        self.userRepo.batchInsert(users: [user1], validate: true) { resultSuccess in
//            switch resultSuccess {
//            case .success(let success):
//                XCTAssertTrue(success)
//            case .failure(let error):
//                XCTAssertTrue(false)
//            }
//        }
//        self.wait(for: [expectationBatchInsert2], timeout: 1)
//    }
    
    func testPagingLoad() throws {
        self.userRepo.getLocalUsers(page: 1, size: 30) { result in
            switch result {
            case .success(let item):
                XCTAssertTrue(item.count == 30)
            case .failure(let error):
                print(String(describing: error.errorDescription))
                XCTAssertTrue(false)
            }
        }
    }
    
    func testSearch() throws {
//        var user1 = RUserItem()
//        user1.userId = 20000 // mock
//        user1.login = "20000"
//        user1.avatarUrl = "https://cdn.pixabay.com/photo/2020/03/31/14/28/paper-4987885_960_720.jpg"
//        user1.note = "This is note for user 20000_x"
//
//        let result = userRepo.batchInsert(users: [user1], validate: false)
//        switch result {
//        case .success(let success):
//            XCTAssertTrue(success) // expectaion here
//        case .failure(let error):
//            XCTAssertTrue(false)
//        }
//
//        let resultSearchFound = userRepo.searchUsers(keyword: "20000_x")
//        switch resultSearchFound {
//        case .success(let data):
//            XCTAssertTrue(data.count > 0)
//        case .failure(let error):
//            XCTAssertTrue(false)
//        }
//
//        let resultSearchNotFound = userRepo.searchUsers(keyword: "20000_y")
//        switch resultSearchNotFound {
//        case .success(let data):
//            XCTAssertTrue(data.isEmpty) // expectation here
//        case .failure(let error):
//            XCTAssertTrue(false)
//        }
        
    }

    func testResponseTime() throws {
        let expectation = XCTestExpectation.init(description: "Fast response of User API")
        userRepo.getUsers(since: 0) { result in
            switch result {
            case .success(let data): print("Loaded: \(data.count)")
            case .failure(let error): print("Fail: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 0.5)
    }
    
    func testPerformanceProcessOneImage() throws {
        // This is an example of a performance test case.
        self.measure {
            let expectation = XCTestExpectation.init(description: "Fast response of User API")
            var imgToProcess = UIImage()
            ImageDownloader.loadLocalImg(urlStr: "https://avatars.githubusercontent.com/u/1?v=4") { img in
                imgToProcess = img ?? UIImage()
                let newImg = imgToProcess.inverseImage()
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 5)
        }
    }

}
