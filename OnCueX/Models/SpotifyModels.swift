//
//  SpotifyModels.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/17/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit

extension SPTPartialAlbum {
    func getClosestCoverImage(forSize:CGSize) -> SPTImage {
        var smallestDiff:CGFloat = CGFloat.max
        var indexOfSmallest = 0
        for x in 0..<self.covers.count {
            if let cover = self.covers[x] as? SPTImage {
                let diff = forSize.width - cover.size.width
                if diff < smallestDiff {
                    smallestDiff = diff
                    indexOfSmallest = x
                }
            }
        }
        return self.covers[indexOfSmallest] as! SPTImage
    }
}

internal struct SpotifyTrack: TrackItem, Queueable {
    var assetURL:NSURL {
        return self.partialTrack.playableUri
    }
    var source:ItemSource { return .Spotify }
    
    private var partialTrack:SPTPartialTrack
    private var fullTrack:SPTTrack?
    
    init(partialTrack:SPTPartialTrack) {
        self.partialTrack = partialTrack
    }
    
    var title:String? { return self.partialTrack.name }
    
    var subtitle:String? {
        let artists:[String] = self.partialTrack.artists.map { (artist) -> String in
            let artist = artist as! SPTPartialArtist
            return artist.name
        }
        var albumString:String?
        if self.partialTrack.album != nil {
            albumString = self.partialTrack.album.name
        }
        return "\(String(self.duration.toString())) - " + subtitleString(artists, album: albumString)
    }
    
    var isTrackCollection = false
    var identifier:String { return self.partialTrack.identifier }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        if self.partialTrack.album != nil {
            let cover = self.partialTrack.album.getClosestCoverImage(forSize)
            _imageController.getImage(cover.imageURL) { (url, image) -> Void in
                complete(context:self, image:image)
            }
        } else {
            SPTTrack.trackWithURI(self.partialTrack.uri, session: _spotifyController.session, callback: { (error, track) -> Void in
                if let track = track as? SPTTrack {
                    if track.album != nil {
                        let cover = track.album.getClosestCoverImage(forSize)
                        _imageController.getImage(cover.imageURL) { (url, image) -> Void in
                            complete(context:self, image:image)
                        }
                    }
                    
                }
            })
        }
        
    }
    
    var cellReuseID:String { return "textCell" }
    
    var duration:NSTimeInterval {
        return self.partialTrack.duration
    }
    
    var itemType:ItemType { return .Track }

    var isContainer:Bool { return false }
    func getTracks(complete: (tracks: [TrackItem]) -> Void) {
        complete(tracks:[self])
    }
}

internal struct SpotifyAlbum : AlbumItem {
    var itemType:ItemType { return .Album }
    var source:ItemSource { return .Spotify }
    
    private var partialAlbum:SPTPartialAlbum
    private var fullAlbum:SPTAlbum?
    
    init(partialAlbum:SPTPartialAlbum) {
        self.partialAlbum = partialAlbum
    }
    
    var title:String? { return self.partialAlbum.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialAlbum.identifier }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTAlbum.albumWithURI(self.partialAlbum.uri, accessToken: _spotifyController.token!, market: nil) { (error, album) -> Void in
            if error == nil {
                let items = album.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                let itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        let cover = self.partialAlbum.getClosestCoverImage(forSize)
        _imageController.getImage(cover.imageURL) { (url, image) -> Void in
            complete(context:self, image:image)
        }
    }

    var numberOfItemsInStack:Int = 0
}

internal struct SpotifyArtist : ArtistItem {
    var itemType:ItemType { return .Artist }
    var source:ItemSource { return .Spotify }
    
    private var partialArtist:SPTPartialArtist
    private var fullArtist:SPTArtist?
    
    init(partialArtist:SPTPartialArtist) {
        self.partialArtist = partialArtist
    }
    
    var title:String? { return self.partialArtist.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialArtist.identifier }
    var cellReuseID:String { return "textCell" }
    
    typealias T = SpotifyTrack
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTArtist.artistWithURI(self.partialArtist.uri, accessToken: _spotifyController.token!) { (error, artist) -> Void in
            if error == nil {
                let items = artist.firstTrackPage!.items as! [SPTPartialTrack]
                var listItems:[TrackItem] = []
                for track in items {
                    listItems.append(SpotifyTrack(partialTrack: track))
                }
                let itemList = List(items: listItems, totalCount:artist.firstTrackPage!.totalListLength, pageNumber:page)
                complete(list: itemList)
            }
        }
    }
    
    func getFullArtist(complete:(artist:SPTArtist)->Void) {
        spotify { (token) -> Void in
            SPTArtist.artistWithURI(self.partialArtist.uri, accessToken: token, callback: { (error, artist) -> Void in
                if let artist = artist as? SPTArtist {
                    complete(artist:artist)
                }
            })
        }
    }
    
    func getAlbums(page: Int, complete: (albums: List<TrackCollection>?) -> Void) {
        self.getFullArtist { (artist) -> Void in
            SPTUser.requestCurrentUserWithAccessToken(_spotifyController.token!, callback: { (errro, user) -> Void in
                if let user = user as? SPTUser {
                    artist.requestAlbumsOfType(.Album, withAccessToken: _spotifyController.token!, availableInTerritory: user.territory, callback: { (error, page) -> Void in
                        if let page = page as? SPTListPage {
                            let array:[TrackCollection] = page.items.map({ (item) -> TrackCollection in
                                let item = item as! SPTPartialAlbum
                                return SpotifyAlbum(partialAlbum: item)
                            })
                            
                            let list = List(items: array, totalCount: UInt(array.count), pageNumber: 0)
                            complete(albums: list)
                        }
                    })
                }
            })
        }
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        self.getAlbums(0) { (albums) -> Void in
            
        }
    }
    
    
    var numberOfItemsInStack:Int = 0
}

internal struct SpotifyPlaylist : PlaylistItem {
    var itemType:ItemType { return .Playlist }
    var source:ItemSource { return .Spotify }
    
    private var partialPlaylist:SPTPartialPlaylist
    private var fullPlaylist:SPTPlaylistSnapshot?
    
    init(partialPlaylist:SPTPartialPlaylist) {
        self.partialPlaylist = partialPlaylist
    }
    
    var title:String? { return self.partialPlaylist.name }
    var subtitle:String? { return nil }
    
    var identifier:String { return self.partialPlaylist.uri.absoluteString }
    var cellReuseID:String { return "textCell" }
    
    func getTracks(page: Int, complete: (list: List<TrackItem>?) -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(self.partialPlaylist.uri, accessToken: _spotifyController.token!) { (error, album) -> Void in
            if error == nil {
                autoreleasepool({ () -> () in
                    if let items = album.firstTrackPage!.items as? [SPTPartialTrack] {
                        var listItems:[TrackItem] = []
                        for track in items {
                            listItems.append(SpotifyTrack(partialTrack: track))
                        }
                        let itemList = List(items: listItems, totalCount:album.firstTrackPage!.totalListLength, pageNumber:page)
                        complete(list: itemList)
                    }
                })
            }
        }
    }
    
    func getImage(forSize:CGSize, complete:(context:Identifiable, image:UIImage?)->Void) {
        
    }
    func getImagesForStack(size:CGSize, complete:(context:StackedImageViewDataSource, images:[UIImage])->Void) {
        
    }
    
    var numberOfItemsInStack:Int = 0
}


