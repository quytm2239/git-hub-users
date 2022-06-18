# GitHubUser
This is a sample iOS project about displaying git user list, profile, ... available for offline mode.

`git-hub-users` requires `iOS 15.0` or later. If you are developer, you can set its `deployment target` to lower iOS version if needed. 

## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [How to run](#how-to-run)
* [Contribution](#contribution)

## General info
This project is simple GitHub user note management. Fetch user from GitHub then save at local storage then allow end-user to add note for each GitHub user.
	
## Technologies
This project is created following `MVVM` pattern.
And my customerized `UI tree/UI holder` or like a `NavigationCenter`
* `CoreData` is used for manage local storage logic
* `URLSessionTask` is used for networking
* `ImageCaching` or `ImageDownloader` is constructed by using both `CoreData` and `URLSessionTask`
	
## How to run
It requires `XCode 13.0 or later` to run directly from source code. XCode 13 requires `macOS 11.3+`
If your `XCode 13.0` is not available, you can change `deployment target` to lower iOS version.
I let an error in code of file `ApiRequest.swift`, at **line 56**. Please create a `Personal Access Token`(PAT) of your GitHub account to use GitHub user's api.
**We can use this api as guest but it will be limited**. Check this [link](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) for how to make a PAT.

## Contribution
If you have anything to upgrade this project, feel free to contact me via email: `quytm2239@gmail.com` or skype: `tranquy239`.

Thank you!
